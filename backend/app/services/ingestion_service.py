"""Ingesting calls and transcripts.

Accepts a single call, or a CSV/JSON batch. Batch imports are deliberately
PARTIAL-TOLERANT: three bad rows in a 500-row CSV import 497 calls and record
three errors, rather than failing the whole upload. Every failure is written to
`ingestion_batches.error_log` with its row number, so a user can fix and re-upload
just the offending rows.

Re-uploading the same call_code UPDATES rather than duplicating, which makes an
interrupted import safe to simply run again.
"""

import csv
import io
import json
import logging
from datetime import datetime, timezone
from typing import Any
from uuid import UUID

from app import db
from app.errors import NotFound, ValidationError
from app.services import transcript_parser

log = logging.getLogger(__name__)

# Accepted CSV/JSON header spellings -> our canonical field name. Telephony
# exports never agree on naming, and an adapter here is far cheaper than asking
# users to reshape their file.
_FIELD_ALIASES = {
    "call_id": "call_code", "callid": "call_code", "call_code": "call_code",
    "id": "call_code", "conversation_id": "call_code",
    "agent_id": "agent_code", "agent_code": "agent_code", "agent": "agent_code",
    "transcript": "transcript", "text": "transcript", "conversation": "transcript",
    "body": "transcript", "content": "transcript",
    "timestamp": "started_at", "started_at": "started_at", "start_time": "started_at",
    "date": "started_at", "call_date": "started_at",
    "duration": "duration_seconds", "duration_seconds": "duration_seconds",
    "duration_secs": "duration_seconds", "length": "duration_seconds",
    "customer_id": "customer_ref", "customer_ref": "customer_ref", "customer": "customer_ref",
    "channel": "channel", "direction": "direction", "language": "language",
    "team": "team_code", "team_code": "team_code",
}

_KNOWN = set(_FIELD_ALIASES.values())


def normalise_row(row: dict[str, Any]) -> dict[str, Any]:
    """Map arbitrary column names onto our field names.

    Anything unrecognised is preserved under `metadata` rather than dropped, so
    ingestion is lossless even for columns we did not anticipate.
    """
    out: dict[str, Any] = {}
    extra: dict[str, Any] = {}

    for key, value in row.items():
        if key is None:
            continue
        canonical = _FIELD_ALIASES.get(str(key).strip().lower().replace(" ", "_"))
        if canonical:
            out[canonical] = value
        else:
            extra[str(key)] = value

    if extra:
        out["metadata"] = extra
    return out


def _parse_datetime(value: Any) -> datetime:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if value in (None, ""):
        return datetime.now(timezone.utc)

    text = str(value).strip().replace("Z", "+00:00")
    for parser in (
        datetime.fromisoformat,
        lambda s: datetime.strptime(s, "%Y-%m-%d %H:%M:%S"),
        lambda s: datetime.strptime(s, "%d/%m/%Y %H:%M"),
        lambda s: datetime.strptime(s, "%m/%d/%Y %H:%M"),
        lambda s: datetime.strptime(s, "%Y-%m-%d"),
    ):
        try:
            parsed = parser(text)
            return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
        except (ValueError, TypeError):
            continue
    raise ValidationError(f"Unrecognised timestamp format: {value!r}")


def _parse_int(value: Any) -> int | None:
    if value in (None, ""):
        return None
    try:
        return int(float(str(value).strip()))
    except (ValueError, TypeError):
        return None


async def _resolve_agent(agent_code: str | None) -> tuple[UUID | None, UUID | None]:
    """Resolve an agent code to (support_agent_id, team_id).

    Unknown agents do not fail the row. A call with an unattributed agent is
    still worth scoring; it simply will not appear on the leaderboard.
    """
    if not agent_code:
        return None, None
    row = await db.fetchrow(
        "select id, team_id from support_agents where agent_code = $1", str(agent_code).strip()
    )
    return (row["id"], row["team_id"]) if row else (None, None)


async def ingest_one(
    payload: dict[str, Any],
    *,
    batch_id: UUID | None = None,
    source: str = "api",
) -> dict:
    """Ingest a single call plus its transcript, inside one transaction.

    The call, transcript and every turn are written atomically. A half-written
    transcript — turns present, full_text missing — would break the citation
    invariant, so partial success is not an option at this level.
    """
    call_code = str(payload.get("call_code") or "").strip()
    if not call_code:
        raise ValidationError("call_code is required.")

    raw_transcript = payload.get("transcript")
    if not raw_transcript:
        raise ValidationError(f"[{call_code}] transcript is required.")

    # A JSON string holding a turn array is common in CSV exports.
    if isinstance(raw_transcript, str) and raw_transcript.lstrip().startswith("["):
        try:
            raw_transcript = json.loads(raw_transcript)
        except json.JSONDecodeError:
            pass

    parsed = transcript_parser.parse(raw_transcript)

    agent_id, team_id = await _resolve_agent(payload.get("agent_code"))
    started_at = _parse_datetime(payload.get("started_at"))
    duration = _parse_int(payload.get("duration_seconds"))

    metadata = payload.get("metadata") or {}
    if not isinstance(metadata, dict):
        metadata = {"raw": str(metadata)}

    pool = db.get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            call_row = await conn.fetchrow(
                """
                insert into calls (call_code, support_agent_id, team_id, customer_ref,
                                   direction, channel, source, language, started_at,
                                   duration_seconds, status, batch_id, metadata)
                values ($1, $2, $3, $4,
                        coalesce($5, 'inbound')::call_direction,
                        coalesce($6, 'phone')::call_channel,
                        $7::call_source,
                        coalesce($8, 'en'), $9, $10, 'transcribed', $11, $12::jsonb)
                on conflict (call_code) do update
                   set support_agent_id = excluded.support_agent_id,
                       team_id          = excluded.team_id,
                       customer_ref     = excluded.customer_ref,
                       started_at       = excluded.started_at,
                       duration_seconds = excluded.duration_seconds,
                       metadata         = excluded.metadata,
                       status           = 'transcribed',
                       updated_at       = now()
                returning id, call_code, (xmax = 0) as was_inserted
                """,
                call_code, agent_id, team_id, payload.get("customer_ref"),
                payload.get("direction"), payload.get("channel"), source,
                payload.get("language"), started_at, duration, batch_id,
                metadata,
            )
            call_id = call_row["id"]

            # Replace the transcript wholesale on re-ingest. Turns cascade, so
            # offsets can never end up pointing into a stale full_text.
            await conn.execute("delete from transcripts where call_id = $1", call_id)

            transcript_id = await conn.fetchval(
                """
                insert into transcripts (call_id, full_text, word_count, turn_count,
                                         language, transcription_provider)
                values ($1, $2, $3, $4, coalesce($5, 'en'), $6)
                returning id
                """,
                call_id, parsed.full_text, parsed.word_count, parsed.turn_count,
                payload.get("language"), payload.get("transcription_provider") or "import",
            )

            await conn.executemany(
                """
                insert into transcript_turns (transcript_id, call_id, turn_index, speaker,
                                              speaker_label, text, start_ms, char_start, char_end)
                values ($1, $2, $3, $4::speaker_role, $5, $6, $7, $8, $9)
                """,
                [
                    (transcript_id, call_id, t.turn_index, t.speaker, t.speaker_label,
                     t.text, t.start_ms, t.char_start, t.char_end)
                    for t in parsed.turns
                ],
            )

    return {
        "call_id": str(call_id),
        "call_code": call_code,
        "transcript_id": str(transcript_id),
        "turn_count": parsed.turn_count,
        "word_count": parsed.word_count,
        "created": call_row["was_inserted"],
        "agent_resolved": agent_id is not None,
    }


def parse_upload(filename: str, content: bytes) -> list[dict]:
    """Turn an uploaded CSV or JSON file into a list of normalised row dicts."""
    name = (filename or "").lower()

    try:
        text = content.decode("utf-8-sig")
    except UnicodeDecodeError:
        text = content.decode("latin-1")

    if name.endswith(".json") or text.lstrip().startswith(("[", "{")):
        data = json.loads(text)
        if isinstance(data, dict):
            # Tolerate {"calls": [...]} and {"data": [...]} wrappers.
            for key in ("calls", "data", "items", "records"):
                if isinstance(data.get(key), list):
                    data = data[key]
                    break
            else:
                data = [data]
        return [normalise_row(r) for r in data]

    if name.endswith(".csv") or "," in text.split("\n")[0]:
        return [normalise_row(r) for r in csv.DictReader(io.StringIO(text))]

    raise ValidationError("Unsupported file type. Upload a .csv or .json file.")


async def ingest_batch(
    filename: str, rows: list[dict], uploaded_by: UUID | None, max_rows: int
) -> dict:
    """Import many calls, tolerating per-row failure."""
    if not rows:
        raise ValidationError("File contains no rows.")
    if len(rows) > max_rows:
        raise ValidationError(f"File contains {len(rows)} rows; the limit is {max_rows}.")

    batch_id = await db.fetchval(
        """
        insert into ingestion_batches (filename, source, total_rows, status, uploaded_by)
        values ($1, 'upload_text', $2, 'processing', $3)
        returning id
        """,
        filename, len(rows), uploaded_by,
    )

    succeeded, failed, errors, created, updated = 0, 0, [], 0, 0

    for index, row in enumerate(rows, start=1):
        try:
            result = await ingest_one(row, batch_id=batch_id, source="upload_text")
            succeeded += 1
            created += 1 if result["created"] else 0
            updated += 0 if result["created"] else 1
        except Exception as exc:  # noqa: BLE001 - one bad row must not stop the import
            failed += 1
            errors.append({
                "row": index,
                "call_code": str(row.get("call_code") or "")[:64],
                "error": str(exc)[:400],
            })
            log.warning("ingestion row %s failed: %s", index, exc)

    await db.execute(
        """
        update ingestion_batches
           set succeeded = $2, failed = $3, error_log = $4::jsonb,
               status = $5, completed_at = now()
         where id = $1
        """,
        batch_id, succeeded, failed, errors,
        "completed" if failed == 0 else "completed_with_errors",
    )

    return {
        "batch_id": str(batch_id),
        "filename": filename,
        "total_rows": len(rows),
        "succeeded": succeeded,
        "failed": failed,
        "created": created,
        "updated": updated,
        "errors": errors[:50],   # cap the response; the full log lives in the batch row
    }


async def get_batch(batch_id: UUID) -> dict:
    row = await db.fetchrow("select * from ingestion_batches where id = $1", batch_id)
    if not row:
        raise NotFound(f"Ingestion batch {batch_id} does not exist.")
    return row


async def list_batches(limit: int = 50) -> list[dict]:
    return await db.fetch(
        "select * from ingestion_batches order by created_at desc limit $1", limit
    )
