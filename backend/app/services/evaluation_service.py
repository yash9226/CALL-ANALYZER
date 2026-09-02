"""Creating, running and re-running evaluations.

PROMOTION IS DEFERRED UNTIL SUCCESS
-----------------------------------
A new evaluation is inserted with `is_current = false` and only promoted once it
completes. So a failed re-run cannot destroy a perfectly good previous result —
the dashboard keeps showing the last evaluation that actually worked, and the
failed attempt stays in the history for diagnosis.

The previous evaluation is linked via `supersedes`, giving an audit trail of why
a call's score changed: new rubric, new model, or a manual re-run.
"""

import logging
from uuid import UUID

from app import db
from app.agents.base import PipelineContext
from app.errors import Conflict, NotFound
from app.pipeline.graph import get_graph

log = logging.getLogger(__name__)


async def load_context(
    call_id: UUID, evaluation_id: UUID, framework_version_id: UUID
) -> PipelineContext:
    """Assemble everything the pipeline needs, in three queries."""
    call = await db.fetchrow(
        """
        select c.id, c.call_code, c.duration_seconds, c.started_at, c.language,
               c.channel::text as channel, c.direction::text as direction, c.metadata,
               sa.full_name as agent_name, sa.agent_code, t.name as team_name
          from calls c
          left join support_agents sa on sa.id = c.support_agent_id
          left join teams t on t.id = c.team_id
         where c.id = $1
        """,
        call_id,
    )
    if not call:
        raise NotFound(f"Call {call_id} does not exist.")

    transcript = await db.fetchrow(
        "select id, full_text from transcripts where call_id = $1", call_id
    )
    if not transcript:
        raise Conflict(
            f"Call {call['call_code']} has no transcript. Ingest one before evaluating."
        )

    turns = await db.fetch(
        """
        select id, turn_index, speaker::text as speaker, speaker_label, text,
               char_start, char_end, start_ms
          from transcript_turns where call_id = $1 order by turn_index
        """,
        call_id,
    )

    # The rubric, flattened to enabled sub-sections with their enabled criteria.
    # Disabled nodes are excluded here rather than filtered later, so a disabled
    # criterion is never sent to the model and never billed for.
    rows = await db.fetch(
        """
        select ss.id as ss_id, ss.code as ss_code, ss.name as ss_name,
               ss.description as ss_desc, ss.weight as ss_weight, ss.display_order as ss_order,
               s.code as s_code, s.display_order as s_order,
               c.id as c_id, c.code as c_code, c.name as c_name, c.description as c_desc,
               c.weight as c_weight, c.scoring_type::text as c_type, c.max_score, c.min_score,
               c.guidance, c.examples, c.is_critical, c.allow_na, c.display_order as c_order
          from sections s
          join subsections ss on ss.section_id = s.id and ss.is_enabled
          join criteria c on c.subsection_id = ss.id and c.is_enabled
         where s.framework_version_id = $1 and s.is_enabled
         order by s.display_order, ss.display_order, c.display_order
        """,
        framework_version_id,
    )
    if not rows:
        raise Conflict(
            f"Framework version {framework_version_id} has no enabled criteria to score against."
        )

    subsections: dict[UUID, dict] = {}
    for r in rows:
        bucket = subsections.setdefault(r["ss_id"], {
            "id": r["ss_id"], "code": r["ss_code"], "name": r["ss_name"],
            "description": r["ss_desc"], "weight": float(r["ss_weight"]),
            "section_code": r["s_code"], "criteria": [],
        })
        bucket["criteria"].append({
            "id": r["c_id"], "code": r["c_code"], "name": r["c_name"],
            "description": r["c_desc"], "weight": float(r["c_weight"]),
            "scoring_type": r["c_type"], "max_score": float(r["max_score"]),
            "min_score": float(r["min_score"]), "guidance": r["guidance"],
            "examples": r["examples"] or [], "is_critical": r["is_critical"],
            "allow_na": r["allow_na"],
        })

    return PipelineContext(
        call_id=call_id,
        evaluation_id=evaluation_id,
        framework_version_id=framework_version_id,
        call=dict(call),
        turns=turns,
        full_text=transcript["full_text"],
        subsections=list(subsections.values()),
    )


async def create_evaluation(
    call_id: UUID,
    framework_version_id: UUID | None = None,
    trigger_reason: str = "initial",
) -> UUID:
    """Insert a queued, NOT-yet-current evaluation."""
    if framework_version_id is None:
        framework_version_id = await db.fetchval(
            "select id from framework_versions where status = 'published'"
        )
        if not framework_version_id:
            raise Conflict("No published framework version exists. Publish one first.")

    previous = await db.fetchval(
        "select id from evaluations where call_id = $1 and is_current", call_id
    )

    return await db.fetchval(
        """
        insert into evaluations (call_id, framework_version_id, status, is_current,
                                 supersedes, trigger_reason, started_at)
        values ($1, $2, 'queued', false, $3, $4, now())
        returning id
        """,
        call_id, framework_version_id, previous, trigger_reason,
    )


async def promote(evaluation_id: UUID, call_id: UUID) -> None:
    """Make this the evaluation the dashboard shows.

    Both writes happen in one transaction: the partial unique index allows only
    one current evaluation per call, so clearing and setting must be atomic.
    """
    pool = db.get_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            await conn.execute(
                "update evaluations set is_current = false where call_id = $1 and is_current",
                call_id,
            )
            await conn.execute(
                "update evaluations set is_current = true where id = $1", evaluation_id
            )


async def run_evaluation(
    call_id: UUID,
    framework_version_id: UUID | None = None,
    trigger_reason: str = "initial",
    evaluation_id: UUID | None = None,
) -> dict:
    """Run the full pipeline for one call."""
    if evaluation_id is None:
        evaluation_id = await create_evaluation(call_id, framework_version_id, trigger_reason)

    version_id = await db.fetchval(
        "select framework_version_id from evaluations where id = $1", evaluation_id
    )

    await db.execute(
        "update evaluations set status = 'running', started_at = now() where id = $1",
        evaluation_id,
    )
    await db.execute("update calls set status = 'evaluating' where id = $1", call_id)

    try:
        ctx = await load_context(call_id, evaluation_id, version_id)
        state = await get_graph().ainvoke(
            {"ctx": ctx, "completed": [], "failed": []},
            # A generous ceiling; the graph has 6 nodes, so hitting this means
            # something is genuinely wrong rather than merely slow.
            {"recursion_limit": 25},
        )
    except Exception as exc:  # noqa: BLE001
        await db.execute(
            """
            update evaluations
               set status = 'failed', error_message = $2, completed_at = now()
             where id = $1
            """,
            evaluation_id, str(exc)[:2000],
        )
        await db.execute("update calls set status = 'failed', error_message = $2 where id = $1",
                         call_id, str(exc)[:1000])
        log.exception("evaluation %s failed for call %s", evaluation_id, call_id)
        raise

    await promote(evaluation_id, call_id)

    row = await db.fetchrow(
        """
        select score_percentage, grade, auto_fail_triggered, auto_fail_reason,
               input_tokens, output_tokens, cost_usd, model_used, duration_ms
          from evaluations where id = $1
        """,
        evaluation_id,
    )

    return {
        "evaluation_id": str(evaluation_id),
        "call_id": str(call_id),
        "framework_version_id": str(version_id),
        "agents_completed": state.get("completed", []),
        "agents_failed": state.get("failed", []),
        **{k: (float(v) if hasattr(v, "quantize") else v) for k, v in row.items()},
    }


async def enqueue_evaluation(
    call_id: UUID, framework_version_id: UUID | None = None,
    trigger_reason: str = "manual_rerun", priority: int = 100,
) -> dict:
    """Queue an evaluation for the background worker instead of running it inline."""
    evaluation_id = await create_evaluation(call_id, framework_version_id, trigger_reason)
    job_id = await db.fetchval(
        """
        insert into jobs (job_type, call_id, evaluation_id, priority, payload)
        values ('evaluate', $1, $2, $3, $4::jsonb)
        returning id
        """,
        call_id, evaluation_id, priority, {"trigger_reason": trigger_reason},
    )
    return {"job_id": str(job_id), "evaluation_id": str(evaluation_id), "status": "queued"}


async def enqueue_many(call_ids: list[UUID], trigger_reason: str = "manual_rerun") -> dict:
    queued = [await enqueue_evaluation(cid, trigger_reason=trigger_reason) for cid in call_ids]
    return {"queued": len(queued), "jobs": queued}


async def get_evaluation(evaluation_id: UUID) -> dict:
    row = await db.fetchrow(
        """
        select e.*, e.status::text as status, c.call_code
          from evaluations e join calls c on c.id = e.call_id
         where e.id = $1
        """,
        evaluation_id,
    )
    if not row:
        raise NotFound(f"Evaluation {evaluation_id} does not exist.")

    row["agent_runs"] = await db.fetch(
        """
        select agent_name, step_order, status::text as status, model, prompt_version,
               input_tokens, output_tokens, cost_usd, latency_ms, attempt_count,
               error_type, error_message, started_at, completed_at
          from agent_runs where evaluation_id = $1 order by step_order, started_at
        """,
        evaluation_id,
    )
    return row
