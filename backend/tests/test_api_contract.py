"""Contract tests: the API must keep matching frontend/src/lib/api.ts.

WHY THIS FILE EXISTS
--------------------
The frontend is generated externally (Lovable) against the TypeScript types in
`frontend/src/lib/api.ts`. Those types are hand-written, so nothing automatically
stops the backend from drifting away from them — a renamed field would compile
fine on both sides and simply render as `undefined` in production.

These tests freeze the field names the frontend depends on. If someone renames a
column or reshapes a response, the failure says so here rather than surfacing as
a blank cell in a dashboard three weeks later.

When a change is intentional: update api.ts AND the expected set below, in the
same commit.
"""


def assert_fields(payload: dict, expected: set[str], label: str) -> None:
    """Every expected field must be present. Extra fields are allowed —
    adding data is backwards-compatible; removing or renaming is not."""
    missing = expected - set(payload)
    assert not missing, f"{label} is missing field(s) the frontend expects: {sorted(missing)}"


class TestCallOverviewContract:
    async def test_call_list_item_shape(self, client):
        body = (await client.get("/api/calls?limit=1")).json()
        assert_fields(body, {"items", "total", "limit", "offset"}, "Paginated")
        assert_fields(
            body["items"][0],
            {
                "call_id", "call_code", "started_at", "duration_seconds", "status",
                "channel", "direction", "support_agent_id", "agent_code", "agent_name",
                "team_id", "team_name", "evaluation_id", "score_percentage", "grade",
                "auto_fail_triggered", "framework_version_id", "headline",
                "resolution_status", "topics", "sentiment_label", "sentiment_score",
                "sentiment_delta", "sentiment_trajectory", "flag_count",
                "critical_flag_count",
            },
            "CallOverview",
        )


class TestCallDetailContract:
    async def test_top_level_shape(self, client):
        call = (await client.get("/api/calls?limit=1")).json()["items"][0]
        detail = (await client.get(f"/api/calls/{call['call_id']}")).json()
        assert_fields(
            detail,
            {
                "call", "transcript", "turns", "evaluation_id", "criterion_scores",
                "section_scores", "subsection_scores", "summary", "sentiment_timeline",
                "risk_flags", "statistics", "agent_runs", "evaluation_history",
            },
            "CallDetail",
        )

    async def test_turn_carries_citation_offsets(self, client):
        """char_start/char_end are what the UI highlights with. Without them the
        frontend would have to text-search, which is the exact failure mode this
        design avoids."""
        call = (await client.get("/api/calls?limit=1")).json()["items"][0]
        detail = (await client.get(f"/api/calls/{call['call_id']}")).json()
        assert_fields(
            detail["turns"][0],
            {"id", "turn_index", "speaker", "speaker_label", "text",
             "start_ms", "end_ms", "char_start", "char_end"},
            "TranscriptTurn",
        )

    async def test_criterion_score_and_citation_shape(self, client):
        call = (await client.get("/api/calls?limit=1")).json()["items"][0]
        detail = (await client.get(f"/api/calls/{call['call_id']}")).json()
        score = detail["criterion_scores"][0]
        assert_fields(
            score,
            {"id", "criterion_code", "criterion_name", "subsection_code", "section_code",
             "scoring_type", "weight_snapshot", "is_critical_snapshot", "raw_score",
             "max_score", "normalized", "confidence", "reasoning", "is_applicable",
             "na_reason", "citations"},
            "CriterionScore",
        )

        cited = next(s for s in detail["criterion_scores"] if s["citations"])
        assert_fields(
            cited["citations"][0],
            {"id", "turn_index", "quoted_text", "char_start", "char_end",
             "polarity", "relevance"},
            "ScoreCitation",
        )

    async def test_agent_run_shape_supports_the_pipeline_tab(self, client):
        call = (await client.get("/api/calls?limit=1")).json()["items"][0]
        detail = (await client.get(f"/api/calls/{call['call_id']}")).json()
        assert_fields(
            detail["agent_runs"][0],
            {"agent_name", "step_order", "status", "model", "prompt_version",
             "input_tokens", "output_tokens", "latency_ms", "attempt_count",
             "error_message", "started_at", "completed_at"},
            "AgentRun",
        )


class TestAnalyticsContract:
    async def test_overview_shape(self, client):
        body = (await client.get("/api/analytics/overview")).json()
        assert_fields(
            body,
            {"period", "current", "previous", "change_pct",
             "auto_fail_rate", "evaluation_coverage_pct"},
            "AnalyticsOverview",
        )
        assert_fields(
            body["current"],
            {"total_calls", "evaluated_calls", "avg_score", "avg_sentiment",
             "avg_sentiment_delta", "auto_fails", "critical_flags", "total_flags",
             "avg_duration_seconds", "active_agents"},
            "OverviewMetrics",
        )
        assert_fields(
            body["change_pct"],
            {"avg_score", "total_calls", "auto_fails", "avg_sentiment", "critical_flags"},
            "change_pct",
        )

    async def test_trend_point_shape(self, client):
        rows = (await client.get("/api/analytics/trend?granularity=week")).json()
        assert_fields(
            rows[0],
            {"bucket", "calls", "evaluated", "avg_score", "avg_sentiment",
             "auto_fails", "critical_flags"},
            "TrendPoint",
        )

    async def test_section_and_criterion_shapes(self, client):
        sections = (await client.get("/api/analytics/sections")).json()
        assert_fields(
            sections[0],
            {"section_code", "section_name", "weight", "avg_score", "sample_size"},
            "SectionPerformance",
        )

        criteria = (await client.get("/api/analytics/criteria?limit=1")).json()
        assert_fields(
            criteria[0],
            {"section_code", "subsection_code", "criterion_code", "criterion_name",
             "is_critical", "scored", "not_applicable", "avg_score",
             "avg_confidence", "fail_rate_pct"},
            "CriterionPerformance",
        )

    async def test_agent_scorecard_shape(self, client):
        rows = (await client.get("/api/analytics/agents")).json()
        assert_fields(
            rows[0],
            {"support_agent_id", "agent_code", "agent_name", "team_id", "team_name",
             "calls", "evaluated", "avg_score", "min_score", "max_score",
             "score_stddev", "auto_fails", "avg_sentiment_delta", "critical_flags",
             "avg_duration_seconds", "last_call_at"},
            "AgentScorecard",
        )

    async def test_distribution_always_returns_all_ten_bands(self, client):
        """The frontend renders a fixed x-axis and must not have to synthesise
        the empty bands itself."""
        body = (await client.get("/api/analytics/distribution")).json()
        assert_fields(body, {"bands", "grades"}, "ScoreDistribution")
        assert len(body["bands"]) == 10
        assert_fields(body["bands"][0], {"band", "label", "calls"}, "band")

    async def test_flag_summary_shape(self, client):
        body = (await client.get("/api/analytics/flags")).json()
        assert_fields(body, {"by_type", "by_severity", "total", "recent_open"}, "FlagSummary")
        if body["recent_open"]:
            assert_fields(
                body["recent_open"][0],
                {"id", "flag_type", "severity", "title", "description", "confidence",
                 "is_acknowledged", "created_at", "call_id", "call_code",
                 "agent_name", "team_name"},
                "FlagSummary.recent_open",
            )

    async def test_topic_shape(self, client):
        rows = (await client.get("/api/analytics/topics")).json()
        assert_fields(rows[0], {"topic", "calls", "avg_score", "avg_sentiment"},
                      "TopicBreakdown")


class TestFrameworkContract:
    async def test_version_and_tree_shape(self, client):
        tree = (await client.get("/api/framework/active")).json()
        assert_fields(
            tree,
            {"id", "version_no", "name", "description", "status", "notes", "cloned_from",
             "published_at", "archived_at", "created_at", "section_count",
             "subsection_count", "criterion_count", "evaluation_count", "sections"},
            "FrameworkVersionDetail",
        )
        section = tree["sections"][0]
        assert_fields(
            section,
            {"id", "framework_version_id", "code", "name", "description", "weight",
             "display_order", "is_enabled", "subsections"},
            "Section",
        )
        assert_fields(
            section["subsections"][0],
            {"id", "section_id", "code", "name", "description", "weight",
             "display_order", "is_enabled", "criteria"},
            "Subsection",
        )
        assert_fields(
            section["subsections"][0]["criteria"][0],
            {"id", "subsection_id", "code", "name", "description", "weight",
             "scoring_type", "max_score", "min_score", "guidance", "examples",
             "is_critical", "allow_na", "display_order", "is_enabled",
             "created_at", "updated_at"},
            "Criterion",
        )

    async def test_version_counts_are_populated_not_defaulted(self, client):
        """Presence is not enough. These fields are optional in the Pydantic
        model, so a backend that omits them serialises zeroes and the UI shows
        "0 sections" over a full tree — which is exactly what happened. Assert
        the values agree with the tree they describe."""
        tree = (await client.get("/api/framework/active")).json()

        actual_sections = len(tree["sections"])
        actual_subsections = sum(len(s["subsections"]) for s in tree["sections"])
        actual_criteria = sum(
            len(ss["criteria"]) for s in tree["sections"] for ss in s["subsections"]
        )

        assert tree["section_count"] == actual_sections == 5
        assert tree["subsection_count"] == actual_subsections == 12
        assert tree["criterion_count"] == actual_criteria == 31
        # The seeded corpus is evaluated against this version.
        assert tree["evaluation_count"] > 0

    async def test_validation_shape(self, client):
        version_id = (await client.get("/api/framework/active")).json()["id"]
        body = (await client.get(f"/api/framework/versions/{version_id}/validate")).json()
        assert_fields(body, {"is_valid", "issues"}, "ValidationResult")


class TestErrorEnvelopeContract:
    async def test_errors_use_the_documented_envelope(self, client):
        """ApiError in api.ts destructures error.code / error.message / error.details.
        A bare string body would break every error path in the UI."""
        tree = (await client.get("/api/framework/active")).json()
        criterion = tree["sections"][0]["subsections"][0]["criteria"][0]
        r = await client.patch(f"/api/framework/criteria/{criterion['id']}",
                               json={"weight": 99})
        assert r.status_code == 409
        body = r.json()
        assert "error" in body
        assert_fields(body["error"], {"code", "message", "details"}, "error envelope")


class TestMetaContract:
    async def test_team_shape(self, client):
        rows = (await client.get("/api/teams")).json()
        assert_fields(
            rows[0],
            {"id", "code", "name", "description", "is_active", "agent_count", "call_count"},
            "Team",
        )

    async def test_health_shape(self, client):
        body = (await client.get("/health")).json()
        assert_fields(body, {"status", "database", "auth_dev_bypass", "mock_llm"}, "Health")

    async def test_pipeline_graph_shape(self, client):
        body = (await client.get("/api/evaluations/pipeline/graph")).json()
        assert_fields(body, {"mermaid", "agents", "provider", "model"}, "PipelineGraph")
        assert_fields(body["agents"][0], {"name", "step", "uses_llm", "output"}, "agent")
