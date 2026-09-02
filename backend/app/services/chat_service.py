"""The manager assistant: hybrid retrieval over transcripts and scores.

WHY A ROUTER, NOT PURE RAG
--------------------------
Managers ask two incompatible kinds of question:

  "Show me calls where the customer mentioned billing issues"
      -> semantic. The answer lives inside transcripts.

  "Which agents scored lowest on empathy this week?"
      -> analytical. The answer lives in NO single transcript. It is an
         aggregate over thousands of score rows, and no amount of vector
         similarity will produce it.

A pure-RAG assistant fails the second category outright — it retrieves five
transcripts that mention empathy and confidently invents a ranking. So the first
step is to classify the question and pick a retrieval path.

THREE PATHS
  semantic   -> hybrid vector + full-text retrieval (RRF), cite the calls
  analytical -> generate SQL, validate it, execute read-only, cite the numbers
  hybrid     -> both, when a question needs an aggregate AND examples

GROUNDING
Every answer carries citations, and analytical answers carry the SQL that
produced them. The assistant is only useful to a manager if its numbers can be
checked, and an uncheckable number in a quality-assurance tool is worse than no
number at all.
"""

import json
import logging
import time
from uuid import UUID

from app import db
from app.config import get_settings
from app.errors import NotFound
from app.llm import get_provider
from app.services.sql_guard import UnsafeSQL, validate

log = logging.getLogger(__name__)

# ── Router ──────────────────────────────────────────────────────────────────

ROUTER_SYSTEM = """You classify questions asked by a customer-support manager \
about their call-quality data. Choose the retrieval strategy that can actually \
answer the question.

- "analytical": the answer is a number, ranking, count, average or trend across \
many calls. It cannot be found by reading any single transcript.
- "semantic": the answer requires reading what was actually said inside calls — \
finding examples, quotes, or calls matching a description.
- "hybrid": the question needs an aggregate AND supporting examples."""

ROUTER_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "mode": {"type": "STRING", "enum": ["semantic", "analytical", "hybrid"]},
        "reasoning": {"type": "STRING"},
        "search_query": {
            "type": "STRING",
            "description": "Text to search transcripts for, when semantic or hybrid",
        },
    },
    "required": ["mode"],
}

# ── SQL generation ──────────────────────────────────────────────────────────

SCHEMA_DOC = """You write a single read-only Postgres SELECT against these views.

v_call_overview — one row per call, with its CURRENT evaluation flattened:
  call_id, call_code, started_at, duration_seconds, status, channel, direction,
  support_agent_id, agent_code, agent_name, team_id, team_name,
  evaluation_id, score_percentage (0-100), grade (A-F), auto_fail_triggered,
  headline, resolution_status, topics (text[]), sentiment_label,
  sentiment_score (-1..1), sentiment_delta, sentiment_trajectory,
  flag_count, critical_flag_count

v_agent_scorecard — per agent aggregates:
  support_agent_id, agent_code, agent_name, team_id, team_name,
  evaluated_calls, avg_score, min_score, max_score, score_stddev, auto_fails,
  avg_sentiment_delta, avg_talk_ratio, high_risk_flags, last_call_at

criterion_scores — per criterion, per evaluation (join to v_call_overview on
  evaluation_id to filter by team, agent or date):
  evaluation_id, criterion_code, criterion_name, subsection_code, section_code,
  raw_score, max_score, normalized (0..1), confidence, reasoning,
  is_applicable, is_critical_snapshot, weight_snapshot

section_scores — per section, per evaluation:
  evaluation_id, section_code, section_name, normalized (0..1), weight_snapshot

risk_flags — evaluation_id, call_id, flag_type, severity, title, description,
  is_acknowledged, is_false_positive

call_summaries — evaluation_id, call_id, headline, summary, customer_intent,
  resolution_status, topics (text[]), key_issues

RULES
- Exactly one SELECT. No semicolons, no CTEs writing data, no DDL or DML.
- Only the relations listed above.
- Always include a LIMIT (at most 200).
- normalized is 0..1; multiply by 100 to present a percentage.
- Criterion names are human-readable ("Acknowledges customer emotion"); codes
  are upper snake case (ACKNOWLEDGE_EMOTION). Match loosely with ILIKE when the
  user names a concept rather than a code.
- A not-applicable criterion has is_applicable = false and must be excluded from
  averages — including it would misrepresent the agent.
- Use only the CURRENT evaluation: join through v_call_overview, which already
  filters to is_current."""

SQL_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "sql": {"type": "STRING"},
        "explanation": {"type": "STRING", "description": "One sentence, for the user"},
    },
    "required": ["sql"],
}

# ── Answer generation ───────────────────────────────────────────────────────

ANSWER_SYSTEM = """You are a call-quality analyst assisting a support manager.

Rules:
- Answer ONLY from the evidence provided. If it does not support an answer, say
  so plainly and suggest what would.
- Never invent a call code, agent name, score or quotation.
- Lead with the answer, then the supporting detail. A manager is scanning.
- Reference calls by their call code so the manager can open them.
- Be concise. Two or three short paragraphs, or a short list. No preamble."""

ANSWER_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "answer": {"type": "STRING", "description": "Markdown. Concise."},
        "cited_call_codes": {"type": "ARRAY", "items": {"type": "STRING"}},
        "confidence": {"type": "STRING", "enum": ["high", "medium", "low"]},
    },
    "required": ["answer"],
}


def _scope_sql(user) -> str:
    """Row-level restriction appended to generated SQL for non-admins.

    The assistant must not become a way around the access model: a manager
    asking "which agents scored lowest" must get their own team, not everyone's.
    """
    if user.role == "admin":
        return ""
    if user.role == "manager" and user.team_id:
        return f" and team_id = '{user.team_id}'::uuid"
    return " and false"


async def _run_sql(sql: str) -> list[dict]:
    """Execute validated SQL inside a READ ONLY transaction with a timeout.

    This is the layer that actually guarantees safety. Even if the validator
    were bypassed, Postgres refuses writes in a read-only transaction.
    """
    pool = db.get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction(readonly=True):
            await conn.execute("set local statement_timeout = '8s'")
            rows = await conn.fetch(sql)
            return [dict(r) for r in rows]


class IndexMismatch(Exception):
    """The index was built with a different embedding model than the one now
    configured, so similarity between query and chunks is meaningless."""


async def _semantic_search(query: str, user, limit: int = 8) -> list[dict]:
    settings = get_settings()
    provider = get_provider()

    # Vectors from two different embedding models share a coordinate space only
    # by coincidence. Searching across them returns confidently-ranked nonsense,
    # which is worse than an error: the user cannot tell it is wrong. Refuse
    # instead, and say what to do about it.
    current = "mock" if settings.mock_llm else settings.gemini_embedding_model
    mismatched = await db.fetchval(
        "select count(*) from transcript_chunks where embedding_model is distinct from $1",
        current,
    )
    if mismatched:
        total = await db.fetchval("select count(*) from transcript_chunks")
        raise IndexMismatch(
            f"The search index was built with a different embedding model "
            f"({mismatched} of {total} passages). Rebuild it with "
            f"POST /api/chat/index/build?force=true before searching transcripts."
        )
    # ── Scoping ─────────────────────────────────────────────────────────────
    # This mirrors _scope_sql and, like it, FAILS CLOSED. An earlier version
    # only applied a filter for managers, so an agent whose profile was not
    # linked to a support_agents row fell through to no filter at all and could
    # retrieve every team's transcripts. Retrieval is an access path like any
    # other; "no restriction" must never be the default branch.
    team_id: str | None = None
    agent_id: str | None = None

    if user.role == "admin":
        pass
    elif user.role == "manager" and user.team_id:
        team_id = user.team_id
    elif user.role == "agent" and user.id:
        agent_id = await db.fetchval(
            "select id::text from support_agents where profile_id = $1::uuid", user.id
        )
        if not agent_id:
            return []
    else:
        return []

    vector = (await provider.embed([query], dimensions=settings.embedding_dimensions))[0]
    literal = "[" + ",".join(f"{v:.6f}" for v in vector) + "]"

    rows = await db.fetch(
        """
        select r.chunk_id, r.call_id, r.call_code, r.content, r.turn_start, r.turn_end,
               r.similarity, r.rrf_score,
               v.agent_name, v.team_name, v.score_percentage, v.grade, v.started_at,
               v.headline
          from search_transcript_chunks($1::vector, $2, $3, $4::uuid, $5::uuid, null, null) r
          join v_call_overview v on v.call_id = r.call_id
         order by r.rrf_score desc
        """,
        literal, query, limit, team_id, agent_id,
    )
    return [dict(r) for r in rows]


def _serialise(value):
    """JSON-safe conversion for values headed into a prompt."""
    if hasattr(value, "isoformat"):
        return value.isoformat()
    if hasattr(value, "quantize"):
        return float(value)
    if isinstance(value, UUID):
        return str(value)
    return value


async def ask(user, question: str, session_id: UUID | None = None) -> dict:
    """Answer one question. Returns the answer plus its full grounding trail."""
    started = time.perf_counter()
    provider = get_provider()
    settings = get_settings()
    model = "mock" if settings.mock_llm else settings.gemini_chat_model
    router_model = "mock" if settings.mock_llm else settings.gemini_router_model

    tokens_in = tokens_out = 0

    def account(result) -> None:
        nonlocal tokens_in, tokens_out
        tokens_in += result.input_tokens
        tokens_out += result.output_tokens

    # ── 1. Route ────────────────────────────────────────────────────────────
    route_kwargs = {"system": ROUTER_SYSTEM, "model": router_model, "temperature": 0.0}
    if provider.name == "mock":
        route_kwargs |= {"task": "chat_route", "context": {"question": question}}
    route_result = await provider.generate_json(
        f"Classify this question:\n\n{question}", ROUTER_SCHEMA, **route_kwargs
    )
    account(route_result)
    route = route_result.parsed or {}
    mode = route.get("mode", "semantic")
    search_query = route.get("search_query") or question

    citations: list[dict] = []
    chunks: list[dict] = []
    rows: list[dict] = []
    generated_sql: str | None = None
    sql_error: str | None = None

    # ── 2. Retrieve ─────────────────────────────────────────────────────────
    if mode in ("analytical", "hybrid"):
        sql_kwargs = {"system": SCHEMA_DOC, "model": model, "temperature": 0.0}
        if provider.name == "mock":
            sql_kwargs |= {"task": "chat_sql", "context": {"question": question}}
        sql_result = await provider.generate_json(
            f"Write one SELECT that answers:\n\n{question}", SQL_SCHEMA, **sql_kwargs
        )
        account(sql_result)
        raw_sql = (sql_result.parsed or {}).get("sql", "")

        try:
            safe = validate(raw_sql)
            # Scoping is appended AFTER validation so the model cannot write a
            # query that removes it.
            scope = _scope_sql(user)
            if scope and " where " in safe.lower():
                safe = safe.replace(" limit ", f"{scope} limit ", 1) if " limit " in safe else safe + scope
            generated_sql = safe
            rows = await _run_sql(safe)
        except UnsafeSQL as exc:
            sql_error = str(exc)
            generated_sql = raw_sql
            log.warning("rejected generated SQL: %s | %s", exc, raw_sql[:200])
        except Exception as exc:  # noqa: BLE001 - a bad query must not 500 the chat
            sql_error = f"Query failed: {exc}"
            log.warning("generated SQL failed: %s", exc)

    index_error: str | None = None
    if mode in ("semantic", "hybrid"):
        try:
            chunks = await _semantic_search(search_query, user)
        except IndexMismatch as exc:
            # A hybrid question can still answer from its query results, so the
            # whole request is not failed — the gap is reported instead.
            index_error = str(exc)
            log.warning("semantic search unavailable: %s", exc)
            chunks = []
        for c in chunks:
            citations.append({
                "call_id": str(c["call_id"]),
                "call_code": c["call_code"],
                "agent_name": c["agent_name"],
                "team_name": c["team_name"],
                "score_percentage": _serialise(c["score_percentage"]),
                "excerpt": c["content"][:400],
                "turn_start": c["turn_start"],
                "turn_end": c["turn_end"],
                "similarity": round(float(c["similarity"] or 0), 3),
            })

    # ── 3. Answer ───────────────────────────────────────────────────────────
    evidence: list[str] = []
    if rows:
        evidence.append(
            "## Query results\n"
            + json.dumps([{k: _serialise(v) for k, v in r.items()} for r in rows[:60]], indent=1)
        )
    if sql_error:
        evidence.append(f"## Query could not be run\n{sql_error}")
    if chunks:
        evidence.append(
            "## Transcript excerpts\n"
            + "\n\n".join(
                f"[{c['call_code']} · {c['agent_name']} · {c['team_name']} · "
                f"score {_serialise(c['score_percentage'])}%]\n{c['content'][:700]}"
                for c in chunks
            )
        )
    if index_error:
        evidence.append(f"## Transcript search unavailable\n{index_error}")
    if not evidence:
        evidence.append("## No evidence retrieved")

    answer_kwargs = {"system": ANSWER_SYSTEM, "model": model, "temperature": 0.3}
    if provider.name == "mock":
        answer_kwargs |= {
            "task": "chat_answer",
            "context": {"question": question, "rows": rows, "chunks": chunks,
                        "mode": mode, "sql_error": sql_error,
                        "index_error": index_error},
        }
    answer_result = await provider.generate_json(
        f"Question: {question}\n\n" + "\n\n".join(evidence) + "\n\nAnswer the question.",
        ANSWER_SCHEMA, **answer_kwargs,
    )
    account(answer_result)
    answer = answer_result.parsed or {}

    # Keep only the citations the answer actually referenced, when it named any.
    cited_codes = set(answer.get("cited_call_codes") or [])
    if cited_codes:
        ordered = [c for c in citations if c["call_code"] in cited_codes]
        citations = ordered or citations

    latency = int((time.perf_counter() - started) * 1000)

    payload = {
        "answer": answer.get("answer", "I could not answer that."),
        "retrieval_mode": mode,
        "router_reasoning": route.get("reasoning"),
        "citations": citations,
        "rows": [{k: _serialise(v) for k, v in r.items()} for r in rows[:60]],
        "generated_sql": generated_sql,
        "sql_error": sql_error,
        "index_error": index_error,
        "confidence": answer.get("confidence"),
        "model": model,
        "input_tokens": tokens_in,
        "output_tokens": tokens_out,
        "latency_ms": latency,
    }

    if session_id:
        await _persist(session_id, question, payload)

    return payload


async def _persist(session_id: UUID, question: str, payload: dict) -> None:
    pool = db.get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            await conn.execute(
                "insert into chat_messages (session_id, role, content) values ($1, 'user', $2)",
                session_id, question,
            )
            await conn.execute(
                """
                insert into chat_messages (session_id, role, content, citations,
                    generated_sql, retrieval_mode, model, input_tokens, output_tokens,
                    latency_ms, error_message)
                values ($1, 'assistant', $2, $3::jsonb, $4, $5, $6, $7, $8, $9, $10)
                """,
                session_id, payload["answer"], payload["citations"], payload["generated_sql"],
                payload["retrieval_mode"], payload["model"], payload["input_tokens"],
                payload["output_tokens"], payload["latency_ms"], payload["sql_error"],
            )
            await conn.execute(
                "update chat_sessions set updated_at = now() where id = $1", session_id
            )


# ── Sessions ────────────────────────────────────────────────────────────────

async def create_session(user, title: str = "New conversation") -> dict:
    if not user.id:
        # The dev-bypass identity has no profiles row, so sessions cannot be
        # persisted for it. Asking still works; only history is unavailable.
        raise NotFound("Chat history requires a signed-in account.")
    row = await db.fetchrow(
        "insert into chat_sessions (user_id, title) values ($1, $2) returning *",
        user.id, title[:120],
    )
    return dict(row)


async def list_sessions(user) -> list[dict]:
    if not user.id:
        return []
    return await db.fetch(
        """
        select s.*, (select count(*) from chat_messages m where m.session_id = s.id) as message_count
          from chat_sessions s
         where s.user_id = $1 and not s.is_archived
         order by s.updated_at desc limit 50
        """,
        user.id,
    )


async def get_messages(user, session_id: UUID) -> list[dict]:
    owner = await db.fetchval("select user_id from chat_sessions where id = $1", session_id)
    if not owner or (user.id and str(owner) != str(user.id)):
        raise NotFound(f"Conversation {session_id} does not exist.")
    return await db.fetch(
        """
        select id, role::text as role, content, citations, generated_sql, retrieval_mode,
               model, latency_ms, error_message, created_at
          from chat_messages where session_id = $1 order by created_at
        """,
        session_id,
    )
