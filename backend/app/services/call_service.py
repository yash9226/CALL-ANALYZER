"""Reading calls: the list view and the drill-down.

TEAM SCOPING IS ENFORCED HERE, NOT BY RLS
-----------------------------------------
The backend connects as the database owner and bypasses row-level security,
because the pipeline must write scores for every team. That makes the
`_scope_clause` below the real access control for API traffic: a manager's
queries are silently constrained to their own team, and an agent's to their own
calls. The RLS policies in migration 0010 guard the separate path where the
browser talks to Supabase directly.
"""

import logging
from datetime import datetime
from uuid import UUID

from app import db
from app.errors import NotFound

log = logging.getLogger(__name__)

_SORTABLE = {
    "started_at": "started_at",
    "score": "score_percentage",
    "duration": "duration_seconds",
    "agent": "agent_name",
    "sentiment": "sentiment_score",
}


def _scope_clause(user, params: list) -> str:
    """Return a SQL predicate restricting results to what `user` may see."""
    if user.role == "admin":
        return "true"
    if user.role == "manager" and user.team_id:
        params.append(user.team_id)
        return f"team_id = ${len(params)}::uuid"
    if user.role == "agent" and user.id:
        params.append(user.id)
        return f"""support_agent_id in (
            select id from support_agents where profile_id = ${len(params)}::uuid
        )"""
    # A manager with no team, or an agent with no linked profile, sees nothing.
    # Failing closed is the right default for an access check.
    return "false"


async def list_calls(
    user,
    *,
    limit: int = 25,
    offset: int = 0,
    team_id: UUID | None = None,
    support_agent_id: UUID | None = None,
    status: str | None = None,
    grade: str | None = None,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    min_score: float | None = None,
    max_score: float | None = None,
    has_flags: bool | None = None,
    auto_failed: bool | None = None,
    topic: str | None = None,
    search: str | None = None,
    sort_by: str = "started_at",
    sort_dir: str = "desc",
) -> dict:
    where: list[str] = []
    params: list = []

    where.append(_scope_clause(user, params))

    def add(clause_template: str, value) -> None:
        params.append(value)
        where.append(clause_template.format(n=len(params)))

    if team_id:
        add("team_id = ${n}::uuid", team_id)
    if support_agent_id:
        add("support_agent_id = ${n}::uuid", support_agent_id)
    if status:
        add("status = ${n}::call_status", status)
    if grade:
        add("grade = ${n}", grade)
    if date_from:
        add("started_at >= ${n}", date_from)
    if date_to:
        add("started_at <= ${n}", date_to)
    if min_score is not None:
        add("score_percentage >= ${n}", min_score)
    if max_score is not None:
        add("score_percentage <= ${n}", max_score)
    if topic:
        add("${n} = any(topics)", topic)
    if has_flags is True:
        where.append("flag_count > 0")
    elif has_flags is False:
        where.append("coalesce(flag_count, 0) = 0")
    if auto_failed is not None:
        add("coalesce(auto_fail_triggered, false) = ${n}", auto_failed)

    if search:
        # Search the call code, the agent's name, and the transcript itself.
        # The transcript arm uses the GIN-indexed tsvector from migration 0004,
        # so it stays fast as the corpus grows.
        params.append(f"%{search}%")
        like_idx = len(params)
        params.append(search)
        fts_idx = len(params)
        where.append(
            f"""(call_code ilike ${like_idx}
                 or agent_name ilike ${like_idx}
                 or exists (select 1 from transcripts t
                             where t.call_id = v_call_overview.call_id
                               and t.search_vector @@ plainto_tsquery('english', ${fts_idx})))"""
        )

    where_sql = " and ".join(f"({w})" for w in where)
    order_col = _SORTABLE.get(sort_by, "started_at")
    order_dir = "asc" if str(sort_dir).lower() == "asc" else "desc"

    total = await db.fetchval(
        f"select count(*) from v_call_overview where {where_sql}", *params
    )

    params.extend([limit, offset])
    items = await db.fetch(
        f"""
        select * from v_call_overview
         where {where_sql}
         order by {order_col} {order_dir} nulls last, call_code
         limit ${len(params) - 1} offset ${len(params)}
        """,
        *params,
    )

    return {"items": items, "total": total or 0, "limit": limit, "offset": offset}


async def _assert_visible(user, call_id: UUID) -> None:
    params: list = []
    clause = _scope_clause(user, params)
    visible = await db.fetchval(
        f"select exists (select 1 from v_call_overview where call_id = $1 and ({clause}))",
        call_id, *params,
    )
    if not visible:
        # 404 rather than 403: telling an unauthorised caller that a call exists
        # is itself a small information leak.
        raise NotFound(f"Call {call_id} does not exist.")


async def get_call_detail(user, call_id: UUID) -> dict:
    """Everything the drill-down page needs, in one response.

    Deliberately one round trip rather than eight endpoints: the drill-down
    always renders all of it together, and a single payload keeps the frontend
    free of loading-state choreography.
    """
    await _assert_visible(user, call_id)

    overview = await db.fetchrow("select * from v_call_overview where call_id = $1", call_id)
    if not overview:
        raise NotFound(f"Call {call_id} does not exist.")

    transcript = await db.fetchrow(
        """
        select id, full_text, word_count, turn_count, language,
               transcription_provider, transcription_model, transcription_confidence
          from transcripts where call_id = $1
        """,
        call_id,
    )

    turns = await db.fetch(
        """
        select id, turn_index, speaker::text as speaker, speaker_label, text,
               start_ms, end_ms, char_start, char_end
          from transcript_turns
         where call_id = $1
         order by turn_index
        """,
        call_id,
    )

    evaluation_id = overview.get("evaluation_id")
    scores: list = []
    sections: list = []
    subsections: list = []
    sentiment_timeline: list = []
    flags: list = []
    summary = None
    statistics = None
    agent_runs: list = []

    if evaluation_id:
        # Criterion scores with their citations aggregated inline. One query
        # instead of N+1 — a call has ~31 scores and each may carry several
        # citations.
        scores = await db.fetch(
            """
            select cs.id, cs.criterion_code, cs.criterion_name, cs.subsection_code,
                   cs.section_code, cs.scoring_type::text as scoring_type,
                   cs.weight_snapshot, cs.is_critical_snapshot, cs.raw_score,
                   cs.max_score, cs.normalized, cs.confidence, cs.reasoning,
                   cs.is_applicable, cs.na_reason,
                   coalesce(
                     (select jsonb_agg(jsonb_build_object(
                        'id', sc.id, 'turn_index', sc.turn_index,
                        'quoted_text', sc.quoted_text, 'char_start', sc.char_start,
                        'char_end', sc.char_end, 'polarity', sc.polarity,
                        'relevance', sc.relevance) order by sc.turn_index)
                        from score_citations sc where sc.criterion_score_id = cs.id),
                     '[]'::jsonb) as citations
              from criterion_scores cs
              left join criteria c on c.id = cs.criterion_id
             where cs.evaluation_id = $1
             order by coalesce(c.display_order, 999), cs.criterion_code
            """,
            evaluation_id,
        )
        # Ordered by the rubric's own display_order, not alphabetically. A
        # scorecard read out of sequence is disorienting: the reviewer expects
        # Opening -> Communication -> Resolution -> Compliance -> Closing,
        # which is the order the call itself happened in.
        sections = await db.fetch(
            """
            select ss.section_code, ss.section_name, ss.weight_snapshot, ss.normalized,
                   ss.subsections_total, ss.subsections_scored
              from section_scores ss
              left join sections s on s.id = ss.section_id
             where ss.evaluation_id = $1
             order by coalesce(s.display_order, 999), ss.section_code
            """,
            evaluation_id,
        )
        subsections = await db.fetch(
            """
            select sub.subsection_code, sub.subsection_name, sub.section_code,
                   sub.weight_snapshot, sub.normalized, sub.criteria_total,
                   sub.criteria_scored
              from subsection_scores sub
              left join subsections ss on ss.id = sub.subsection_id
              left join sections s on s.id = ss.section_id
             where sub.evaluation_id = $1
             order by coalesce(s.display_order, 999), coalesce(ss.display_order, 999),
                      sub.subsection_code
            """,
            evaluation_id,
        )
        sentiment_timeline = await db.fetch(
            """
            select turn_index, speaker::text as speaker, score,
                   label::text as label, emotions
              from sentiment_timeline where evaluation_id = $1 order by turn_index
            """,
            evaluation_id,
        )
        flags = await db.fetch(
            """
            select id, flag_type, severity::text as severity, title, description,
                   confidence, turn_index, quoted_text, char_start, char_end,
                   is_acknowledged, is_false_positive, reviewer_notes
              from risk_flags where evaluation_id = $1
             order by case severity
                        when 'critical' then 0 when 'high' then 1
                        when 'medium' then 2 else 3 end
            """,
            evaluation_id,
        )
        summary = await db.fetchrow(
            """
            select headline, summary, customer_intent, resolution_status, outcome,
                   key_issues, topics, next_actions
              from call_summaries where evaluation_id = $1
            """,
            evaluation_id,
        )
        statistics = await db.fetchrow(
            "select * from call_statistics where evaluation_id = $1", evaluation_id
        )
        # The pipeline trace. This is what makes the multi-agent design visible
        # in the UI rather than merely claimed in the report.
        agent_runs = await db.fetch(
            """
            select agent_name, step_order, status::text as status, model,
                   prompt_version, input_tokens, output_tokens, latency_ms,
                   attempt_count, error_message, started_at, completed_at
              from agent_runs where evaluation_id = $1 order by step_order
            """,
            evaluation_id,
        )

    evaluations_history = await db.fetch(
        """
        select id, framework_version_id, status::text as status, score_percentage,
               grade, auto_fail_triggered, is_current, trigger_reason,
               model_used, created_at, completed_at
          from evaluations where call_id = $1 order by created_at desc
        """,
        call_id,
    )

    return {
        "call": overview,
        "transcript": transcript,
        "turns": turns,
        "evaluation_id": evaluation_id,
        "criterion_scores": scores,
        "section_scores": sections,
        "subsection_scores": subsections,
        "summary": summary,
        "sentiment_timeline": sentiment_timeline,
        "risk_flags": flags,
        "statistics": statistics,
        "agent_runs": agent_runs,
        "evaluation_history": evaluations_history,
    }


async def get_transcript(user, call_id: UUID) -> dict:
    await _assert_visible(user, call_id)
    transcript = await db.fetchrow(
        "select id, full_text, word_count, turn_count, language from transcripts where call_id = $1",
        call_id,
    )
    if not transcript:
        raise NotFound(f"Call {call_id} has no transcript.")
    turns = await db.fetch(
        """
        select turn_index, speaker::text as speaker, speaker_label, text,
               start_ms, char_start, char_end
          from transcript_turns where call_id = $1 order by turn_index
        """,
        call_id,
    )
    return {**transcript, "turns": turns}
