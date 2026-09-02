"""Triggering and inspecting evaluations."""

from uuid import UUID

from fastapi import APIRouter, Query, status
from pydantic import BaseModel, Field

from app import db
from app.config import get_settings
from app.pipeline.graph import render_mermaid
from app.security import AdminDep, CurrentUserDep
from app.services import evaluation_service as svc

router = APIRouter(prefix="/api/evaluations", tags=["evaluations"])


class EvaluateRequest(BaseModel):
    framework_version_id: UUID | None = Field(
        None, description="Defaults to the currently published version"
    )
    trigger_reason: str = "manual_rerun"
    # Inline runs are for demos and single calls; batches must be queued so an
    # HTTP request never blocks on 84 pipeline runs.
    run_inline: bool = Field(
        False, description="Run now and return the result, rather than queueing"
    )


class BulkEvaluateRequest(BaseModel):
    call_ids: list[UUID] | None = Field(None, description="Omit to evaluate all unevaluated calls")
    framework_version_id: UUID | None = None
    trigger_reason: str = "manual_rerun"
    limit: int = Field(200, ge=1, le=2000)


@router.get("/pipeline/graph")
async def pipeline_graph(_: CurrentUserDep):
    """The compiled pipeline as Mermaid source.

    Generated from the graph that actually executes, so the architecture diagram
    in the report cannot drift from the implementation.
    """
    settings = get_settings()
    return {
        "mermaid": render_mermaid(),
        "agents": [
            {"name": "preprocessing", "step": 1, "uses_llm": False,
             "output": "call_statistics"},
            {"name": "scoring", "step": 2, "uses_llm": True,
             "output": "criterion_scores + score_citations"},
            {"name": "sentiment", "step": 3, "uses_llm": True,
             "output": "sentiment_analyses + sentiment_timeline"},
            {"name": "risk", "step": 4, "uses_llm": True, "output": "risk_flags"},
            {"name": "summary", "step": 5, "uses_llm": True, "output": "call_summaries"},
            {"name": "aggregation", "step": 6, "uses_llm": False,
             "output": "subsection_scores + section_scores + evaluations"},
        ],
        "provider": "mock (rule-based fixtures, no API calls)" if settings.mock_llm
                    else settings.llm_provider,
        "model": "mock" if settings.mock_llm else settings.gemini_scoring_model,
    }


@router.post("/calls/{call_id}", status_code=status.HTTP_202_ACCEPTED)
async def evaluate_call(call_id: UUID, body: EvaluateRequest, _: AdminDep):
    """Evaluate one call — queued by default, or inline with `run_inline`."""
    if body.run_inline:
        return await svc.run_evaluation(
            call_id, body.framework_version_id, body.trigger_reason
        )
    return await svc.enqueue_evaluation(
        call_id, body.framework_version_id, body.trigger_reason, priority=200
    )


@router.post("/bulk", status_code=status.HTTP_202_ACCEPTED)
async def evaluate_bulk(body: BulkEvaluateRequest, _: AdminDep):
    """Queue many calls. Omit call_ids to pick up everything not yet evaluated."""
    call_ids = body.call_ids
    if not call_ids:
        rows = await db.fetch(
            """
            select c.id from calls c
             where c.status in ('transcribed', 'failed')
               and exists (select 1 from transcripts t where t.call_id = c.id)
             order by c.started_at desc
             limit $1
            """,
            body.limit,
        )
        call_ids = [r["id"] for r in rows]

    return await svc.enqueue_many(call_ids, body.trigger_reason)


@router.get("/{evaluation_id}")
async def get_evaluation(evaluation_id: UUID, _: CurrentUserDep):
    """Evaluation detail including the per-agent execution trace."""
    return await svc.get_evaluation(evaluation_id)


@router.get("/jobs/queue")
async def job_queue(
    _: CurrentUserDep,
    status_filter: str | None = Query(None, alias="status"),
    limit: int = Query(50, ge=1, le=500),
):
    """Current job queue, for the ingestion/progress UI."""
    rows = await db.fetch(
        """
        select j.id, j.job_type::text as job_type, j.status::text as status, j.priority,
               j.attempts, j.max_attempts, j.error_message, j.created_at,
               j.started_at, j.completed_at, c.call_code
          from jobs j left join calls c on c.id = j.call_id
         where ($1::text is null or j.status::text = $1)
         order by j.created_at desc
         limit $2
        """,
        status_filter, limit,
    )
    counts = await db.fetch(
        "select status::text as status, count(*) as n from jobs group by status"
    )
    return {"jobs": rows, "counts": {c["status"]: c["n"] for c in counts}}
