"""Chunking and embedding transcripts for retrieval.

CHUNKING ON TURN BOUNDARIES
---------------------------
Chunks are cut between speaker turns, never mid-sentence. Two reasons:

1. A retrieved passage is always a coherent slice of conversation. A chunk that
   starts halfway through the agent's explanation reads as nonsense when the
   chatbot quotes it back.
2. Every chunk keeps the turn indices and character offsets it spans, so an
   answer can cite exact turns — the same citation mechanism the scores use.

Each chunk carries one turn of overlap with the next. Support conversations run
as question-then-answer across two turns, so a hard cut between them would split
the question from its answer and make both halves unretrievable for the query
that wanted them together.

DENORMALISED FILTER COLUMNS
---------------------------
team_id, support_agent_id and call_started_at are copied onto each chunk so a
vector search can be pre-filtered inside the same scan ("only this team, only
last month") rather than retrieving broadly and joining the excess away.
"""

import logging
from uuid import UUID

from app import db
from app.config import get_settings
from app.llm import get_provider

log = logging.getLogger(__name__)

# Sized so a chunk holds a few exchanges: long enough to carry context, short
# enough that the embedding is about one topic rather than an average of five.
TARGET_CHARS = 900
MAX_CHARS = 1400


def build_chunks(turns: list[dict]) -> list[dict]:
    """Group turns into overlapping chunks aligned to turn boundaries."""
    if not turns:
        return []

    chunks: list[dict] = []
    current: list[dict] = []
    size = 0

    def flush() -> None:
        nonlocal current, size
        if not current:
            return
        chunks.append({
            "chunk_index": len(chunks),
            "content": "\n".join(
                f"{t.get('speaker_label') or t['speaker'].title()}: {t['text']}" for t in current
            ),
            "turn_start": current[0]["turn_index"],
            "turn_end": current[-1]["turn_index"],
            "char_start": current[0]["char_start"],
            "char_end": current[-1]["char_end"],
        })
        # Carry the last turn forward: a question and its answer must be able to
        # land in the same chunk as whichever one the query matches.
        current = [current[-1]]
        size = len(current[0]["text"])

    for turn in turns:
        length = len(turn["text"]) + len(turn.get("speaker_label") or "") + 2
        if current and size + length > TARGET_CHARS:
            flush()
        current.append(turn)
        size += length
        if size >= MAX_CHARS:
            flush()

    # Flush the tail, but not if it is only the carried-over overlap turn —
    # that would create a duplicate chunk containing nothing new.
    if len(current) > 1 or (len(current) == 1 and not chunks):
        chunks.append({
            "chunk_index": len(chunks),
            "content": "\n".join(
                f"{t.get('speaker_label') or t['speaker'].title()}: {t['text']}" for t in current
            ),
            "turn_start": current[0]["turn_index"],
            "turn_end": current[-1]["turn_index"],
            "char_start": current[0]["char_start"],
            "char_end": current[-1]["char_end"],
        })

    return chunks


async def embed_call(call_id: UUID, *, force: bool = False) -> dict:
    """Chunk and embed one call's transcript."""
    settings = get_settings()

    model = "mock" if settings.mock_llm else settings.gemini_embedding_model
    existing = await db.fetchrow(
        """
        select count(*) as n, count(*) filter (where embedding_model is distinct from $2) as stale
          from transcript_chunks where call_id = $1
        """,
        call_id, model,
    )
    if existing["n"] and not existing["stale"] and not force:
        return {"call_id": str(call_id), "skipped": "already embedded", "chunks": existing["n"]}

    call = await db.fetchrow(
        """
        select c.id, c.team_id, c.support_agent_id, c.started_at, t.id as transcript_id
          from calls c join transcripts t on t.call_id = c.id
         where c.id = $1
        """,
        call_id,
    )
    if not call:
        return {"call_id": str(call_id), "skipped": "no transcript"}

    turns = await db.fetch(
        """
        select turn_index, speaker::text as speaker, speaker_label, text, char_start, char_end
          from transcript_turns where call_id = $1 order by turn_index
        """,
        call_id,
    )

    chunks = build_chunks(turns)
    if not chunks:
        return {"call_id": str(call_id), "skipped": "no turns"}

    provider = get_provider()
    vectors = await provider.embed(
        [c["content"] for c in chunks], dimensions=settings.embedding_dimensions
    )

    pool = db.get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            await conn.execute("delete from transcript_chunks where call_id = $1", call_id)
            for chunk, vector in zip(chunks, vectors):
                await conn.execute(
                    """
                    insert into transcript_chunks (transcript_id, call_id, chunk_index, content,
                        turn_start, turn_end, char_start, char_end, embedding, embedding_model,
                        token_count, team_id, support_agent_id, call_started_at)
                    values ($1,$2,$3,$4,$5,$6,$7,$8,$9::vector,$10,$11,$12,$13,$14)
                    """,
                    call["transcript_id"], call_id, chunk["chunk_index"], chunk["content"],
                    chunk["turn_start"], chunk["turn_end"], chunk["char_start"], chunk["char_end"],
                    # asyncpg has no native vector codec, so the literal form is
                    # built here and cast in SQL.
                    "[" + ",".join(f"{v:.6f}" for v in vector) + "]",
                    settings.gemini_embedding_model if not settings.mock_llm else "mock",
                    len(chunk["content"]) // 4,
                    call["team_id"], call["support_agent_id"], call["started_at"],
                )

    log.info("embedded call %s into %s chunks", call_id, len(chunks))
    return {"call_id": str(call_id), "chunks": len(chunks)}


def current_model() -> str:
    settings = get_settings()
    return "mock" if settings.mock_llm else settings.gemini_embedding_model


async def embed_pending(limit: int = 500, force: bool = False) -> dict:
    """Embed calls that are unindexed OR indexed with a different model.

    The stale-model case matters more than it sounds. Vectors from two different
    models share a coordinate space only by coincidence, so cosine similarity
    between them is meaningless — a single call left on old embeddings quietly
    corrupts ranking for every query.

    It happens easily: an embedding run that fails partway leaves the old chunks
    in place, and a "skip calls that already have chunks" rule never revisits
    them. Observed exactly that way while indexing the real corpus.
    """
    model = current_model()

    rows = await db.fetch(
        """
        select c.id from calls c
          join transcripts t on t.call_id = c.id
         where $2
            or not exists (select 1 from transcript_chunks tc where tc.call_id = c.id)
            or exists (select 1 from transcript_chunks tc
                        where tc.call_id = c.id
                          and tc.embedding_model is distinct from $3)
         order by c.started_at desc
         limit $1
        """,
        limit, force, model,
    )

    embedded, chunks, failed = 0, 0, []
    for row in rows:
        try:
            result = await embed_call(row["id"], force=force)
            if result.get("chunks") and not result.get("skipped"):
                embedded += 1
                chunks += result["chunks"]
        except Exception as exc:  # noqa: BLE001 - one bad call must not stop the batch
            failed.append({"call_id": str(row["id"]), "error": str(exc)[:200]})
            log.warning("embedding failed for %s: %s", row["id"], exc)

    # The keyword arm of hybrid search drops corpus-common lexemes, so the
    # document-frequency view has to be rebuilt whenever the corpus changes.
    if embedded:
        await db.execute("select refresh_lexeme_df()")

    return {"calls_embedded": embedded, "chunks_created": chunks,
            "failed": len(failed), "errors": failed[:10]}


async def coverage() -> dict:
    """Index health, including the model mix.

    `stale_chunks` is the number embedded with a model other than the one
    currently configured. Any non-zero value means the index is comparing
    vectors from incompatible coordinate spaces, which silently degrades every
    search — so it is reported rather than left to be discovered.
    """
    model = current_model()
    row = await db.fetchrow(
        """
        select (select count(*) from calls c
                 where exists (select 1 from transcripts t where t.call_id = c.id)) as with_transcript,
               (select count(distinct call_id) from transcript_chunks)              as embedded,
               (select count(*) from transcript_chunks)                            as chunks,
               (select count(*) from transcript_chunks where embedding is null)     as missing_vectors,
               (select count(*) from transcript_chunks
                 where embedding_model is distinct from $1)                         as stale_chunks
        """,
        model,
    )
    models = await db.fetch(
        "select embedding_model, count(*) as chunks from transcript_chunks group by 1 order by 2 desc"
    )
    return {**dict(row), "current_model": model,
            "models_in_index": {m["embedding_model"]: m["chunks"] for m in models}}
