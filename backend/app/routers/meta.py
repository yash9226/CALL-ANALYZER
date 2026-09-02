"""Reference data and health."""

from fastapi import APIRouter

from app import db
from app.config import get_settings
from app.security import CurrentUserDep

router = APIRouter(tags=["meta"])


@router.get("/health")
async def health():
    """Liveness plus a real database round trip.

    Reports which framework version is live and how much data is loaded, which
    makes it a genuinely useful first call when something looks wrong.
    """
    settings = get_settings()
    try:
        stats = await db.fetchrow(
            """
            select (select count(*) from calls)                                as calls,
                   (select count(*) from evaluations where is_current)         as evaluations,
                   (select count(*) from criteria where is_enabled)            as active_criteria,
                   (select version_no from framework_versions
                     where status = 'published')                               as framework_version
            """
        )
        db_ok = True
    except Exception:  # noqa: BLE001
        stats, db_ok = {}, False

    return {
        "status": "ok" if db_ok else "degraded",
        "database": "connected" if db_ok else "unavailable",
        "auth_dev_bypass": settings.auth_dev_bypass,
        "mock_llm": settings.mock_llm,
        **({k: v for k, v in stats.items()} if stats else {}),
    }


@router.get("/api/teams")
async def list_teams(_: CurrentUserDep):
    return await db.fetch(
        """
        select t.id, t.code, t.name, t.description, t.is_active,
               (select count(*) from support_agents sa
                 where sa.team_id = t.id and sa.is_active) as agent_count,
               (select count(*) from calls c where c.team_id = t.id) as call_count
          from teams t
         where t.is_active
         order by t.name
        """
    )


@router.get("/api/agents")
async def list_agents(_: CurrentUserDep):
    """Agent roster with their scorecard aggregates, for filters and the leaderboard."""
    return await db.fetch(
        "select * from v_agent_scorecard order by avg_score desc nulls last"
    )
