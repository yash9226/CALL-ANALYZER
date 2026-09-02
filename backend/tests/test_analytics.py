"""Dashboard analytics tests.

Two things worth defending here:

1. **Scoping.** Analytics aggregate across the whole corpus, so a scoping bug
   leaks another team's numbers in a form the user cannot see is wrong. The
   filters must be derived from the caller's profile, never trusted from the
   request.
2. **Metric definitions.** `fail_rate_pct` excluding N/A, and the histogram
   emitting empty bands, are decisions a chart silently depends on.
"""

from dataclasses import replace

import pytest

from app import db
from app.security import DEV_USER
from app.services import analytics_service as svc


@pytest.fixture
def admin():
    return DEV_USER


@pytest.fixture
def make_manager():
    def _make(team_id):
        return replace(DEV_USER, role="manager", team_id=str(team_id), id=None)
    return _make


class TestOverview:
    async def test_reports_the_seeded_corpus(self, client, admin):
        result = await svc.overview(admin)
        assert result["current"]["total_calls"] == 84
        assert result["current"]["evaluated_calls"] == 84
        assert result["evaluation_coverage_pct"] == 100.0
        assert 0 < result["current"]["avg_score"] < 100

    async def test_includes_a_comparison_window(self, client, admin):
        result = await svc.overview(admin)
        assert "previous" in result
        assert "change_pct" in result
        assert result["period"]["from"] < result["period"]["to"]

    async def test_auto_fail_rate_is_a_percentage_of_evaluated_calls(self, client, admin):
        result = await svc.overview(admin)
        expected = round(
            100 * result["current"]["auto_fails"] / result["current"]["evaluated_calls"], 2
        )
        assert result["auto_fail_rate"] == expected


class TestScoping:
    async def test_manager_sees_only_their_team(self, client, make_manager):
        teams = await db.fetch("select id, code from teams order by code")
        totals = []
        for team in teams:
            result = await svc.overview(make_manager(team["id"]))
            totals.append(result["current"]["total_calls"])
            # Every call in a scoped view must belong to that team.
            agents = await svc.agent_leaderboard(make_manager(team["id"]))
            assert all(str(a["team_id"]) == str(team["id"]) for a in agents)

        assert sum(totals) == 84          # the teams partition the corpus
        assert all(t < 84 for t in totals)  # and none of them sees all of it

    async def test_scope_fails_closed_for_a_manager_with_no_team(self, client):
        orphan = replace(DEV_USER, role="manager", team_id=None, id=None)
        result = await svc.overview(orphan)
        # No team means no data, not all data.
        assert result["current"]["total_calls"] == 0

    async def test_scope_fails_closed_for_an_agent_with_no_profile(self, client):
        orphan = replace(DEV_USER, role="agent", team_id=None, id=None)
        result = await svc.overview(orphan)
        assert result["current"]["total_calls"] == 0


class TestSectionsAndCriteria:
    async def test_sections_cover_the_whole_rubric_weakest_first(self, client, admin):
        sections = await svc.section_performance(admin)
        assert len(sections) == 5
        scores = [s["avg_score"] for s in sections]
        assert scores == sorted(scores)
        assert sum(s["weight"] for s in sections) == 100

    async def test_criteria_are_ordered_worst_first(self, client, admin):
        criteria = await svc.criterion_performance(admin, limit=10)
        scores = [c["avg_score"] for c in criteria]
        assert scores == sorted(scores)

    async def test_fail_rate_excludes_not_applicable_scores(self, client, admin):
        """A criterion that rarely applies must not be reported as widely failed."""
        criteria = await svc.criterion_performance(admin, limit=500)
        hold = next(c for c in criteria if c["criterion_code"] == "HOLD_ETIQUETTE")
        assert hold["not_applicable"] > 0

        failed = await db.fetchval(
            """
            select count(*) from criterion_scores
             where criterion_code = 'HOLD_ETIQUETTE' and is_applicable and normalized < 0.5
            """
        )
        expected = round(100.0 * failed / hold["scored"], 2)
        assert abs(hold["fail_rate_pct"] - expected) < 0.01

    async def test_worst_first_can_be_reversed(self, client, admin):
        best = await svc.criterion_performance(admin, limit=5, worst_first=False)
        scores = [c["avg_score"] for c in best]
        assert scores == sorted(scores, reverse=True)


class TestLeaderboard:
    async def test_reports_consistency_not_just_average(self, client, admin):
        """A steady 78 and an erratic 60-95 average the same but coach differently."""
        agents = await svc.agent_leaderboard(admin)
        assert len(agents) == 9
        assert all(a["score_stddev"] is not None for a in agents)

    async def test_ordered_by_score_descending(self, client, admin):
        agents = await svc.agent_leaderboard(admin)
        scores = [a["avg_score"] for a in agents]
        assert scores == sorted(scores, reverse=True)

    async def test_call_counts_sum_to_the_corpus(self, client, admin):
        agents = await svc.agent_leaderboard(admin)
        assert sum(a["calls"] for a in agents) == 84


class TestDistribution:
    async def test_emits_every_band_including_empty_ones(self, client, admin):
        """A stable x-axis: collapsing empty bands would misrepresent the shape."""
        result = await svc.score_distribution(admin)
        assert len(result["bands"]) == 10
        assert [b["band"] for b in result["bands"]] == list(range(0, 100, 10))

    async def test_bands_and_grades_agree_on_the_total(self, client, admin):
        result = await svc.score_distribution(admin)
        assert sum(b["calls"] for b in result["bands"]) == sum(result["grades"].values()) == 84


class TestFlagsAndTopics:
    async def test_flag_summary_totals_agree(self, client, admin):
        result = await svc.flag_summary(admin)
        assert result["total"] == sum(result["by_severity"].values())
        assert all(not f["is_acknowledged"] for f in result["recent_open"])

    async def test_recent_flags_are_severity_ordered(self, client, admin):
        result = await svc.flag_summary(admin, limit=50)
        rank = {"critical": 0, "high": 1, "medium": 2, "low": 3}
        ranks = [rank[f["severity"]] for f in result["recent_open"]]
        assert ranks == sorted(ranks)

    async def test_topics_come_from_the_summary_agent(self, client, admin):
        topics = await svc.topic_breakdown(admin)
        assert topics
        assert {"billing", "technical", "retention"} <= {t["topic"] for t in topics}
        counts = [t["calls"] for t in topics]
        assert counts == sorted(counts, reverse=True)


class TestTrend:
    async def test_weekly_buckets_cover_the_corpus(self, client, admin):
        weeks = await svc.trend(admin, granularity="week")
        assert len(weeks) >= 6
        assert sum(w["calls"] for w in weeks) == 84
        buckets = [w["bucket"] for w in weeks]
        assert buckets == sorted(buckets)

    async def test_granularity_changes_the_bucket_count(self, client, admin):
        days = await svc.trend(admin, granularity="day")
        weeks = await svc.trend(admin, granularity="week")
        assert len(days) > len(weeks)


class TestAnalyticsApi:
    async def test_every_endpoint_responds(self, client):
        for path in ("overview", "trend", "sections", "criteria", "agents",
                     "distribution", "flags", "topics"):
            r = await client.get(f"/api/analytics/{path}")
            assert r.status_code == 200, f"/api/analytics/{path} returned {r.status_code}"

    async def test_date_filter_narrows_results(self, client):
        wide = (await client.get("/api/analytics/overview")).json()
        narrow = (await client.get(
            "/api/analytics/overview?date_from=2026-08-25T00:00:00Z"
        )).json()
        assert narrow["current"]["total_calls"] < wide["current"]["total_calls"]
