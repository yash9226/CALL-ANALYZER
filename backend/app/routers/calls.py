"""Reading calls: list with filters, and the full drill-down."""

from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Query

from app.security import CurrentUserDep
from app.services import call_service as svc

router = APIRouter(prefix="/api/calls", tags=["calls"])


@router.get("")
async def list_calls(
    user: CurrentUserDep,
    limit: int = Query(25, ge=1, le=200),
    offset: int = Query(0, ge=0),
    team_id: UUID | None = None,
    support_agent_id: UUID | None = None,
    status: str | None = Query(None, description="pending|transcribing|transcribed|evaluating|evaluated|failed"),
    grade: str | None = Query(None, description="A|B|C|D|F"),
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    min_score: float | None = Query(None, ge=0, le=100),
    max_score: float | None = Query(None, ge=0, le=100),
    has_flags: bool | None = None,
    auto_failed: bool | None = None,
    topic: str | None = Query(None, description="Match a single topic tag"),
    search: str | None = Query(None, description="Call code, agent name, or transcript full-text"),
    sort_by: str = Query("started_at", description="started_at|score|duration|agent|sentiment"),
    sort_dir: str = Query("desc", description="asc|desc"),
):
    """Paginated call list. Results are scoped to what the caller may see."""
    return await svc.list_calls(
        user, limit=limit, offset=offset, team_id=team_id,
        support_agent_id=support_agent_id, status=status, grade=grade,
        date_from=date_from, date_to=date_to, min_score=min_score, max_score=max_score,
        has_flags=has_flags, auto_failed=auto_failed, topic=topic, search=search,
        sort_by=sort_by, sort_dir=sort_dir,
    )


@router.get("/{call_id}")
async def get_call(call_id: UUID, user: CurrentUserDep):
    """Everything the drill-down page renders, in a single response:
    transcript and turns, per-criterion scores with citations, section rollups,
    summary, sentiment timeline, risk flags, statistics, the agent-run trace,
    and the evaluation history.
    """
    return await svc.get_call_detail(user, call_id)


@router.get("/{call_id}/transcript")
async def get_transcript(call_id: UUID, user: CurrentUserDep):
    """Transcript plus turns with character offsets, for citation highlighting."""
    return await svc.get_transcript(user, call_id)
