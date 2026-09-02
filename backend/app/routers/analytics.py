"""Dashboard analytics endpoints.

Every endpoint accepts the same filter set, and results are scoped to what the
caller may see. A manager hitting /overview gets their team's overview without
passing team_id, because the scope is derived from their profile rather than
trusted from the request.
"""

from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Query

from app.security import CurrentUserDep
from app.services import analytics_service as svc

router = APIRouter(prefix="/api/analytics", tags=["analytics"])

# Shared query params. Declared once so every endpoint documents them identically.
DateFrom = Query(None, description="ISO 8601. Defaults to 6 weeks ago.")
DateTo = Query(None, description="ISO 8601. Defaults to now.")


@router.get("/overview")
async def overview(
    user: CurrentUserDep,
    date_from: datetime | None = DateFrom,
    date_to: datetime | None = DateTo,
    team_id: UUID | None = None,
    support_agent_id: UUID | None = None,
):
    """Headline KPIs with period-over-period change.

    `change_pct` compares against the immediately preceding window of equal
    length, so a 7-day view is measured against the 7 days before it.
    """
    return await svc.overview(user, date_from=date_from, date_to=date_to,
                              team_id=team_id, support_agent_id=support_agent_id)


@router.get("/trend")
async def trend(
    user: CurrentUserDep,
    granularity: str = Query("day", description="day | week | month"),
    date_from: datetime | None = DateFrom,
    date_to: datetime | None = DateTo,
    team_id: UUID | None = None,
    support_agent_id: UUID | None = None,
):
    """Score, volume and sentiment over time."""
    return await svc.trend(user, granularity=granularity, date_from=date_from,
                           date_to=date_to, team_id=team_id,
                           support_agent_id=support_agent_id)


@router.get("/sections")
async def sections(
    user: CurrentUserDep,
    date_from: datetime | None = DateFrom,
    date_to: datetime | None = DateTo,
    team_id: UUID | None = None,
    support_agent_id: UUID | None = None,
):
    """Average score per rubric section, weakest first."""
    return await svc.section_performance(user, date_from=date_from, date_to=date_to,
                                         team_id=team_id, support_agent_id=support_agent_id)


@router.get("/criteria")
async def criteria(
    user: CurrentUserDep,
    date_from: datetime | None = DateFrom,
    date_to: datetime | None = DateTo,
    team_id: UUID | None = None,
    support_agent_id: UUID | None = None,
    limit: int = Query(100, ge=1, le=500),
    worst_first: bool = Query(True, description="Order by weakest criterion first"),
):
    """Leaf-level performance with fail rates — the coaching list."""
    return await svc.criterion_performance(
        user, date_from=date_from, date_to=date_to, team_id=team_id,
        support_agent_id=support_agent_id, limit=limit, worst_first=worst_first,
    )


@router.get("/agents")
async def agents(
    user: CurrentUserDep,
    date_from: datetime | None = DateFrom,
    date_to: datetime | None = DateTo,
    team_id: UUID | None = None,
    limit: int = Query(50, ge=1, le=200),
):
    """Agent leaderboard, including score consistency (`score_stddev`)."""
    return await svc.agent_leaderboard(user, date_from=date_from, date_to=date_to,
                                       team_id=team_id, limit=limit)


@router.get("/distribution")
async def distribution(
    user: CurrentUserDep,
    date_from: datetime | None = DateFrom,
    date_to: datetime | None = DateTo,
    team_id: UUID | None = None,
    support_agent_id: UUID | None = None,
):
    """Score histogram in 10-point bands, plus grade counts."""
    return await svc.score_distribution(user, date_from=date_from, date_to=date_to,
                                        team_id=team_id, support_agent_id=support_agent_id)


@router.get("/flags")
async def flags(
    user: CurrentUserDep,
    date_from: datetime | None = DateFrom,
    date_to: datetime | None = DateTo,
    team_id: UUID | None = None,
    support_agent_id: UUID | None = None,
    limit: int = Query(20, ge=1, le=100),
):
    """Risk flag counts by type and severity, plus the most recent open flags."""
    return await svc.flag_summary(user, date_from=date_from, date_to=date_to,
                                  team_id=team_id, support_agent_id=support_agent_id,
                                  limit=limit)


@router.get("/topics")
async def topics(
    user: CurrentUserDep,
    date_from: datetime | None = DateFrom,
    date_to: datetime | None = DateTo,
    team_id: UUID | None = None,
    support_agent_id: UUID | None = None,
):
    """Call volume and average score by topic tag."""
    return await svc.topic_breakdown(user, date_from=date_from, date_to=date_to,
                                     team_id=team_id, support_agent_id=support_agent_id)
