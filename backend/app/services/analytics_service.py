"""Dashboard analytics.

Every function here takes the same filter set (date range, team, agent) and
applies the caller's visibility scope, so a manager's dashboard is automatically
their team's dashboard without the frontend having to know that.

WHY THE QUERIES LIVE HERE RATHER THAN IN THE FRONTEND
-----------------------------------------------------
"Which agents scored lowest on empathy this week?" is an aggregation over
thousands of rows. Shipping those rows to the browser to be reduced in
JavaScript would be slow, would leak data the caller may not see, and would put
the definition of a metric in the client. Postgres does the aggregation; the API
returns the answer.

Comparisons against a previous period are computed in the same query where
possible, because a KPI card without a trend arrow is much less useful and a
second round trip per card would be wasteful.
"""

import logging
from datetime import datetime, timedelta, timezone
from uuid import UUID

from app import db

log = logging.getLogger(__name__)


def _scope(user, params: list) -> str:
    """Visibility predicate over v_call_overview. Fails closed."""
    if user.role == "admin":
        return "true"
    if user.role == "manager" and user.team_id:
        params.append(user.team_id)
        return f"team_id = ${len(params)}::uuid"
    if user.role == "agent" and user.id:
        params.append(user.id)
        return (f"support_agent_id in (select id from support_agents "
                f"where profile_id = ${len(params)}::uuid)")
    return "false"


def _filters(
    user, params: list, *,
    date_from: datetime | None, date_to: datetime | None,
    team_id: UUID | None, support_agent_id: UUID | None,
) -> str:
    clauses = [_scope(user, params)]
    if date_from:
        params.append(date_from)
        clauses.append(f"started_at >= ${len(params)}")
    if date_to:
        params.append(date_to)
        clauses.append(f"started_at <= ${len(params)}")
    if team_id:
        params.append(team_id)
        clauses.append(f"team_id = ${len(params)}::uuid")
    if support_agent_id:
        params.append(support_agent_id)
        clauses.append(f"support_agent_id = ${len(params)}::uuid")
    return " and ".join(f"({c})" for c in clauses)


def _default_window(date_from, date_to) -> tuple[datetime, datetime]:
    """Default to the last 6 weeks, which is the span of the seeded corpus."""
    to = date_to or datetime.now(timezone.utc)
    return (date_from or to - timedelta(weeks=6)), to


async def overview(
    user, *, date_from=None, date_to=None, team_id=None, support_agent_id=None
) -> dict:
    """Headline KPIs, each with a change against the preceding equal-length period.

    The comparison window is the same length immediately before the selected one,
    so "last 7 days" compares against the 7 days before that rather than an
    arbitrary baseline.
    """
    date_from, date_to = _default_window(date_from, date_to)
    span = date_to - date_from
    prev_from, prev_to = date_from - span, date_from

    async def window(start, end) -> dict:
        params: list = []
        where = _filters(user, params, date_from=start, date_to=end,
                         team_id=team_id, support_agent_id=support_agent_id)
        row = await db.fetchrow(
            f"""
            select count(*)                                              as total_calls,
                   count(evaluation_id)                                  as evaluated_calls,
                   round(avg(score_percentage), 2)                       as avg_score,
                   round(avg(sentiment_score), 3)                        as avg_sentiment,
                   round(avg(sentiment_delta), 3)                        as avg_sentiment_delta,
                   count(*) filter (where auto_fail_triggered)           as auto_fails,
                   coalesce(sum(critical_flag_count), 0)                 as critical_flags,
                   coalesce(sum(flag_count), 0)                          as total_flags,
                   round(avg(duration_seconds))                          as avg_duration_seconds,
                   count(distinct support_agent_id)                      as active_agents
              from v_call_overview
             where {where}
            """,
            *params,
        )
        return {k: (float(v) if hasattr(v, "quantize") else v) for k, v in row.items()}

    current = await window(date_from, date_to)
    previous = await window(prev_from, prev_to)

    def change(key: str) -> float | None:
        now, before = current.get(key), previous.get(key)
        if now is None or before in (None, 0):
            return None
        return round(((now - before) / before) * 100, 1)

    evaluated = current["evaluated_calls"] or 0
    return {
        "period": {"from": date_from.isoformat(), "to": date_to.isoformat()},
        "current": current,
        "previous": previous,
        "change_pct": {
            "avg_score": change("avg_score"),
            "total_calls": change("total_calls"),
            "auto_fails": change("auto_fails"),
            "avg_sentiment": change("avg_sentiment"),
            "critical_flags": change("critical_flags"),
        },
        "auto_fail_rate": round(100 * current["auto_fails"] / evaluated, 2) if evaluated else 0,
        "evaluation_coverage_pct": (
            round(100 * evaluated / current["total_calls"], 1) if current["total_calls"] else 0
        ),
    }


async def trend(
    user, *, granularity: str = "day", date_from=None, date_to=None,
    team_id=None, support_agent_id=None,
) -> list[dict]:
    """Score and volume over time, for the headline chart."""
    date_from, date_to = _default_window(date_from, date_to)
    bucket = {"day": "day", "week": "week", "month": "month"}.get(granularity, "day")

    params: list = []
    where = _filters(user, params, date_from=date_from, date_to=date_to,
                     team_id=team_id, support_agent_id=support_agent_id)
    rows = await db.fetch(
        f"""
        select date_trunc('{bucket}', started_at)::date as bucket,
               count(*)                                  as calls,
               count(evaluation_id)                      as evaluated,
               round(avg(score_percentage), 2)           as avg_score,
               round(avg(sentiment_score), 3)            as avg_sentiment,
               count(*) filter (where auto_fail_triggered) as auto_fails,
               coalesce(sum(critical_flag_count), 0)     as critical_flags
          from v_call_overview
         where {where}
         group by 1 order by 1
        """,
        *params,
    )
    return [{k: (float(v) if hasattr(v, "quantize") else v) for k, v in r.items()} for r in rows]


async def section_performance(
    user, *, date_from=None, date_to=None, team_id=None, support_agent_id=None
) -> list[dict]:
    """Average score per rubric section — the 'where are we weak' chart."""
    date_from, date_to = _default_window(date_from, date_to)
    params: list = []
    where = _filters(user, params, date_from=date_from, date_to=date_to,
                     team_id=team_id, support_agent_id=support_agent_id)
    rows = await db.fetch(
        f"""
        select ss.section_code, ss.section_name,
               round(avg(ss.weight_snapshot), 2)      as weight,
               round(avg(ss.normalized) * 100, 2)     as avg_score,
               count(*)                               as sample_size
          from section_scores ss
          join v_call_overview v on v.evaluation_id = ss.evaluation_id
         where {where}
         group by ss.section_code, ss.section_name
         order by avg_score asc nulls last
        """,
        *params,
    )
    return [{k: (float(v) if hasattr(v, "quantize") else v) for k, v in r.items()} for r in rows]


async def criterion_performance(
    user, *, date_from=None, date_to=None, team_id=None, support_agent_id=None,
    limit: int = 100, worst_first: bool = True,
) -> list[dict]:
    """Leaf-level performance with a fail rate — what a manager actually coaches on.

    `fail_rate_pct` counts scores below half marks among APPLICABLE ones. N/A
    scores are excluded from both numerator and denominator, so a criterion that
    rarely applies is not misreported as a widespread failure.
    """
    date_from, date_to = _default_window(date_from, date_to)
    params: list = []
    where = _filters(user, params, date_from=date_from, date_to=date_to,
                     team_id=team_id, support_agent_id=support_agent_id)
    params.append(limit)
    rows = await db.fetch(
        f"""
        select cs.section_code, cs.subsection_code, cs.criterion_code, cs.criterion_name,
               cs.is_critical_snapshot                                        as is_critical,
               count(*) filter (where cs.is_applicable)                       as scored,
               count(*) filter (where not cs.is_applicable)                   as not_applicable,
               round(avg(cs.normalized) filter (where cs.is_applicable) * 100, 2) as avg_score,
               round(avg(cs.confidence), 3)                                   as avg_confidence,
               round(100.0 * count(*) filter (where cs.is_applicable and cs.normalized < 0.5)
                     / nullif(count(*) filter (where cs.is_applicable), 0), 2) as fail_rate_pct
          from criterion_scores cs
          join v_call_overview v on v.evaluation_id = cs.evaluation_id
         where {where}
         group by cs.section_code, cs.subsection_code, cs.criterion_code,
                  cs.criterion_name, cs.is_critical_snapshot
        having count(*) filter (where cs.is_applicable) > 0
         order by avg_score {"asc" if worst_first else "desc"} nulls last
         limit ${len(params)}
        """,
        *params,
    )
    return [{k: (float(v) if hasattr(v, "quantize") else v) for k, v in r.items()} for r in rows]


async def agent_leaderboard(
    user, *, date_from=None, date_to=None, team_id=None, limit: int = 50
) -> list[dict]:
    """Per-agent aggregates.

    `score_stddev` is included deliberately: a consistent 78 and an erratic
    60–95 average the same but are completely different coaching problems.
    """
    date_from, date_to = _default_window(date_from, date_to)
    params: list = []
    where = _filters(user, params, date_from=date_from, date_to=date_to,
                     team_id=team_id, support_agent_id=None)
    params.append(limit)
    rows = await db.fetch(
        f"""
        select support_agent_id, agent_code, agent_name, team_id, team_name,
               count(*)                                      as calls,
               count(evaluation_id)                          as evaluated,
               round(avg(score_percentage), 2)               as avg_score,
               round(min(score_percentage), 2)               as min_score,
               round(max(score_percentage), 2)               as max_score,
               round(stddev_pop(score_percentage), 2)        as score_stddev,
               count(*) filter (where auto_fail_triggered)   as auto_fails,
               round(avg(sentiment_delta), 3)                as avg_sentiment_delta,
               coalesce(sum(critical_flag_count), 0)         as critical_flags,
               round(avg(duration_seconds))                  as avg_duration_seconds,
               max(started_at)                               as last_call_at
          from v_call_overview
         where {where} and support_agent_id is not null
         group by support_agent_id, agent_code, agent_name, team_id, team_name
         order by avg_score desc nulls last
         limit ${len(params)}
        """,
        *params,
    )
    return [{k: (float(v) if hasattr(v, "quantize") else v) for k, v in r.items()} for r in rows]


async def score_distribution(
    user, *, date_from=None, date_to=None, team_id=None, support_agent_id=None
) -> dict:
    """Histogram in 10-point bands, plus grade counts.

    A distribution answers a question an average cannot: whether a team score of
    70 means everyone sits near 70, or half the team is at 95 and half at 45.
    """
    date_from, date_to = _default_window(date_from, date_to)
    params: list = []
    where = _filters(user, params, date_from=date_from, date_to=date_to,
                     team_id=team_id, support_agent_id=support_agent_id)

    bands = await db.fetch(
        f"""
        select least(floor(score_percentage / 10) * 10, 90)::int as band,
               count(*) as calls
          from v_call_overview
         where {where} and score_percentage is not null
         group by 1 order by 1
        """,
        *params,
    )
    grades = await db.fetch(
        f"""
        select grade, count(*) as calls
          from v_call_overview
         where {where} and grade is not null
         group by 1 order by 1
        """,
        *params,
    )

    by_band = {b["band"]: b["calls"] for b in bands}
    return {
        # Emit every band, including empty ones, so the chart has a stable x-axis
        # instead of collapsing gaps and misleading the reader.
        "bands": [
            {"band": b, "label": f"{b}-{b + 9}", "calls": by_band.get(b, 0)}
            for b in range(0, 100, 10)
        ],
        "grades": {g["grade"]: g["calls"] for g in grades},
    }


async def flag_summary(
    user, *, date_from=None, date_to=None, team_id=None, support_agent_id=None,
    limit: int = 20,
) -> dict:
    """Risk flags: counts by type and severity, plus the most recent open ones."""
    date_from, date_to = _default_window(date_from, date_to)
    params: list = []
    where = _filters(user, params, date_from=date_from, date_to=date_to,
                     team_id=team_id, support_agent_id=support_agent_id)

    by_type = await db.fetch(
        f"""
        select rf.flag_type, rf.severity::text as severity, count(*) as count
          from risk_flags rf
          join v_call_overview v on v.evaluation_id = rf.evaluation_id
         where {where} and not rf.is_false_positive
         group by rf.flag_type, rf.severity
         order by count desc
        """,
        *params,
    )

    params.append(limit)
    recent = await db.fetch(
        f"""
        select rf.id, rf.flag_type, rf.severity::text as severity, rf.title,
               rf.description, rf.confidence, rf.is_acknowledged, rf.created_at,
               v.call_id, v.call_code, v.agent_name, v.team_name
          from risk_flags rf
          join v_call_overview v on v.evaluation_id = rf.evaluation_id
         where {where} and not rf.is_false_positive and not rf.is_acknowledged
         order by case rf.severity
                    when 'critical' then 0 when 'high' then 1
                    when 'medium' then 2 else 3 end, rf.created_at desc
         limit ${len(params)}
        """,
        *params,
    )

    severity_totals: dict[str, int] = {}
    for row in by_type:
        severity_totals[row["severity"]] = severity_totals.get(row["severity"], 0) + row["count"]

    return {
        "by_type": by_type,
        "by_severity": severity_totals,
        "total": sum(severity_totals.values()),
        "recent_open": recent,
    }


async def topic_breakdown(
    user, *, date_from=None, date_to=None, team_id=None, support_agent_id=None
) -> list[dict]:
    """Call volume and score by topic.

    Reads the GIN-indexed topics[] the summary agent produces, so "what are
    people calling about, and where do we handle it worst" is a single indexed
    query rather than a semantic search.
    """
    date_from, date_to = _default_window(date_from, date_to)
    params: list = []
    where = _filters(user, params, date_from=date_from, date_to=date_to,
                     team_id=team_id, support_agent_id=support_agent_id)
    rows = await db.fetch(
        f"""
        select topic,
               count(*)                          as calls,
               round(avg(score_percentage), 2)   as avg_score,
               round(avg(sentiment_score), 3)    as avg_sentiment
          from v_call_overview, unnest(coalesce(topics, '{{}}')) as topic
         where {where}
         group by topic
         order by calls desc
        """,
        *params,
    )
    return [{k: (float(v) if hasattr(v, "quantize") else v) for k, v in r.items()} for r in rows]
