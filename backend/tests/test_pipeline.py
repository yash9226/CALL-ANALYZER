"""Pipeline and agent tests.

Runs in MOCK_LLM mode: deterministic, free, and no network. The pipeline logic
under test — orchestration, persistence, citation resolution, auto-fail — is
identical whichever provider supplies the judgements.
"""

import os

import pytest
import pytest_asyncio

from app import db
from app.config import get_settings
from app.llm import reset_provider
from app.llm.mock import evaluate_rule
from tests.conftest import drop_evaluation

@pytest_asyncio.fixture
async def mock_mode():
    """Force MOCK_LLM on for the duration of a test."""
    previous = os.environ.get("MOCK_LLM")
    os.environ["MOCK_LLM"] = "true"
    get_settings.cache_clear()
    reset_provider()
    yield
    if previous is None:
        os.environ.pop("MOCK_LLM", None)
    else:
        os.environ["MOCK_LLM"] = previous
    get_settings.cache_clear()
    reset_provider()


@pytest_asyncio.fixture
async def evaluated_call(client, mock_mode):
    """Evaluate one call and clean up afterwards."""
    from app.services import evaluation_service

    call = await db.fetchrow(
        """
        select c.id, c.call_code from calls c
          join transcripts t on t.call_id = c.id
         order by c.started_at desc limit 1
        """
    )
    result = await evaluation_service.run_evaluation(call["id"], trigger_reason="initial")
    yield {"call_id": call["id"], "call_code": call["call_code"], **result}
    await drop_evaluation(result["evaluation_id"])


class TestMockRuleEngine:
    """The mock is a rule-based baseline, not a language model. Rules are testable."""

    def test_detects_compliant_greeting(self):
        turns = [{"turn_index": 0, "speaker": "agent",
                  "text": "Thank you for calling Northwind Broadband, my name is Priya."}]
        assert evaluate_rule("GREETING_BRANDED", turns)["fraction"] == 1.0

    def test_detects_missing_recording_disclosure(self):
        turns = [{"turn_index": 0, "speaker": "agent", "text": "Hello, support desk."}]
        result = evaluate_rule("RECORDING_DISCLOSURE", turns)
        assert result["fraction"] == 0.0
        assert result["applicable"] is True

    def test_marks_na_when_situation_did_not_arise(self):
        """A call with no hold must yield N/A, not zero — this is what exercises
        the aggregator's renormalisation path."""
        turns = [{"turn_index": 0, "speaker": "agent", "text": "Let me check that for you."}]
        result = evaluate_rule("HOLD_ETIQUETTE", turns)
        assert result["applicable"] is False
        assert result["fraction"] is None

    def test_negative_only_rule_starts_at_full_marks(self):
        turns = [{"turn_index": 0, "speaker": "agent", "text": "I will look into that."}]
        result = evaluate_rule("NO_UNAUTHORIZED_PROMISE", turns)
        assert result["fraction"] == 1.0
        assert "No violations" in result["reason"]

    def test_negative_only_rule_penalises_a_violation(self):
        turns = [{"turn_index": 0, "speaker": "agent",
                  "text": "I guarantee it will be fixed by tomorrow."}]
        assert evaluate_rule("NO_UNAUTHORIZED_PROMISE", turns)["fraction"] < 1.0

    def test_scope_restricts_judgement_to_the_relevant_part_of_the_call(self):
        """A 'thank you' in the closing must not rescue a greeting criterion."""
        turns = [
            {"turn_index": 0, "speaker": "agent", "text": "Hello, support desk."},
            {"turn_index": 1, "speaker": "customer", "text": "Hi."},
            {"turn_index": 2, "speaker": "agent", "text": "Okay."},
            {"turn_index": 3, "speaker": "agent", "text": "Okay."},
            {"turn_index": 4, "speaker": "agent",
             "text": "Thank you for calling Northwind Broadband, my name is Priya."},
        ]
        assert evaluate_rule("GREETING_BRANDED", turns)["fraction"] < 1.0

    def test_every_scored_criterion_gets_a_citation(self):
        """An uncited score is exactly what this project exists to avoid."""
        turns = [{"turn_index": 0, "speaker": "agent", "text": "Hello."}]
        for code in ("GREETING_BRANDED", "RECORDING_DISCLOSURE", "OFFER_ADDITIONAL_HELP"):
            result = evaluate_rule(code, turns)
            if result["applicable"]:
                assert result["citations"], f"{code} produced a score with no citation"


class TestPipelineGraph:
    def test_graph_shape_is_declared_correctly(self):
        from app.pipeline.graph import render_mermaid

        mermaid = render_mermaid()
        for node in ("preprocessing", "scoring", "sentiment", "risk", "summary", "aggregation"):
            assert node in mermaid
        # Fan-out: preprocessing feeds all four parallel agents.
        for parallel in ("scoring", "sentiment", "risk", "summary"):
            assert f"preprocessing --> {parallel}" in mermaid
            assert f"{parallel} --> aggregation" in mermaid


class TestEndToEndPipeline:
    async def test_all_six_agents_complete(self, evaluated_call):
        assert set(evaluated_call["agents_completed"]) == {
            "preprocessing", "scoring", "sentiment", "risk", "summary", "aggregation"
        }
        assert evaluated_call["agents_failed"] == []

    async def test_produces_a_scored_evaluation(self, evaluated_call):
        assert evaluated_call["score_percentage"] is not None
        assert 0 <= evaluated_call["score_percentage"] <= 100
        assert evaluated_call["grade"] in ("A", "B", "C", "D", "F")

    async def test_every_enabled_criterion_is_scored(self, evaluated_call):
        enabled = await db.fetchval(
            """
            select count(*) from criteria c
              join subsections ss on ss.id = c.subsection_id and ss.is_enabled
              join sections s on s.id = ss.section_id and s.is_enabled
              join framework_versions fv on fv.id = s.framework_version_id
             where fv.status = 'published' and c.is_enabled
            """
        )
        scored = await db.fetchval(
            "select count(*) from criterion_scores where evaluation_id = $1::uuid",
            evaluated_call["evaluation_id"],
        )
        assert scored == enabled == 31

    async def test_citations_resolve_to_exact_character_ranges(self, evaluated_call):
        """The explainability guarantee, verified through stored data."""
        mismatches = await db.fetchval(
            """
            select count(*)
              from score_citations sc
              join criterion_scores cs on cs.id = sc.criterion_score_id
              join transcript_turns tt on tt.id = sc.transcript_turn_id
              join transcripts t on t.id = tt.transcript_id
             where cs.evaluation_id = $1::uuid
               and substring(t.full_text from sc.char_start + 1
                             for sc.char_end - sc.char_start)
                   <> tt.speaker_label || ': ' || tt.text
            """,
            evaluated_call["evaluation_id"],
        )
        assert mismatches == 0

    async def test_every_agent_invocation_is_recorded(self, evaluated_call):
        runs = await db.fetch(
            """
            select agent_name, status::text as status, step_order
              from agent_runs where evaluation_id = $1::uuid order by step_order
            """,
            evaluated_call["evaluation_id"],
        )
        assert len(runs) == 5          # aggregation is not an LLM agent
        assert all(r["status"] == "completed" for r in runs)
        assert [r["agent_name"] for r in runs] == [
            "preprocessing", "scoring", "sentiment", "risk", "summary"
        ]

    async def test_rollups_are_written(self, evaluated_call):
        sections = await db.fetchval(
            "select count(*) from section_scores where evaluation_id = $1::uuid",
            evaluated_call["evaluation_id"],
        )
        subsections = await db.fetchval(
            "select count(*) from subsection_scores where evaluation_id = $1::uuid",
            evaluated_call["evaluation_id"],
        )
        assert sections == 5
        assert subsections == 12

    async def test_framework_snapshot_is_stored(self, evaluated_call):
        """The evaluation must stay explainable even if the rubric is deleted."""
        snapshot = await db.fetchval(
            "select framework_snapshot from evaluations where id = $1::uuid",
            evaluated_call["evaluation_id"],
        )
        assert snapshot is not None
        assert len(snapshot["subsections"]) == 12
        criteria = [c for ss in snapshot["subsections"] for c in ss["criteria"]]
        assert len(criteria) == 31
        assert all(c.get("guidance") for c in criteria)

    async def test_statistics_are_computed_without_an_llm(self, evaluated_call):
        stats = await db.fetchrow(
            "select * from call_statistics where evaluation_id = $1::uuid",
            evaluated_call["evaluation_id"],
        )
        assert stats["agent_turn_count"] > 0
        assert stats["customer_turn_count"] > 0
        assert 0 < float(stats["agent_talk_ratio"]) < 1

        preprocessing = await db.fetchrow(
            """
            select input_tokens, output_tokens from agent_runs
             where evaluation_id = $1::uuid and agent_name = 'preprocessing'
            """,
            evaluated_call["evaluation_id"],
        )
        assert preprocessing["input_tokens"] == 0
        assert preprocessing["output_tokens"] == 0

    async def test_summary_produces_structured_topics(self, evaluated_call):
        summary = await db.fetchrow(
            "select * from call_summaries where evaluation_id = $1::uuid",
            evaluated_call["evaluation_id"],
        )
        assert summary["headline"]
        assert summary["resolution_status"] in (
            "resolved", "partially_resolved", "unresolved", "escalated", "follow_up_scheduled"
        )
        assert isinstance(summary["topics"], list) and summary["topics"]

    async def test_sentiment_trajectory_is_derived_not_guessed(self, evaluated_call):
        sentiment = await db.fetchrow(
            "select * from sentiment_analyses where evaluation_id = $1::uuid",
            evaluated_call["evaluation_id"],
        )
        if sentiment:
            delta = float(sentiment["sentiment_delta"])
            opening = float(sentiment["opening_score"])
            closing = float(sentiment["closing_score"])
            assert abs(delta - (closing - opening)) < 0.01


class TestEvaluationLifecycle:
    async def test_rerun_supersedes_and_keeps_history(self, client, mock_mode):
        from app.services import evaluation_service

        call = await db.fetchrow("select id from calls order by started_at limit 1")
        # Start from a known state: this call may already carry evaluations from
        # a batch run, and the assertion below counts rows.
        await db.execute("delete from evaluations where call_id = $1", call["id"])

        first = await evaluation_service.run_evaluation(call["id"], trigger_reason="initial")
        second = await evaluation_service.run_evaluation(
            call["id"], trigger_reason="manual_rerun"
        )

        rows = await db.fetch(
            "select id, is_current, supersedes from evaluations where call_id = $1 order by created_at",
            call["id"],
        )
        assert len(rows) == 2
        # Exactly one current, and it is the newer run.
        assert sum(1 for r in rows if r["is_current"]) == 1
        assert str(rows[1]["id"]) == second["evaluation_id"]
        assert rows[1]["is_current"] is True
        assert str(rows[1]["supersedes"]) == first["evaluation_id"]

        # Restore the call to having exactly one current evaluation, so the
        # seeded dataset stays complete for the dashboard.
        await db.execute("delete from evaluations where call_id = $1", call["id"])
        await evaluation_service.run_evaluation(call["id"], trigger_reason="initial")

    async def test_evaluating_a_call_without_a_transcript_is_refused(self, client, mock_mode):
        from app.errors import Conflict
        from app.services import evaluation_service

        call_id = await db.fetchval(
            """
            insert into calls (call_code, started_at, status, source)
            values ('TEST-NO-TRANSCRIPT', now(), 'pending', 'api')
            returning id
            """
        )
        try:
            with pytest.raises(Conflict, match="no transcript"):
                await evaluation_service.run_evaluation(call_id)
        finally:
            await db.execute("delete from calls where id = $1", call_id)


class TestPipelineApi:
    async def test_graph_endpoint_returns_mermaid_and_agent_list(self, client):
        body = (await client.get("/api/evaluations/pipeline/graph")).json()
        assert "preprocessing" in body["mermaid"]
        assert len(body["agents"]) == 6
        assert {a["name"] for a in body["agents"]} == {
            "preprocessing", "scoring", "sentiment", "risk", "summary", "aggregation"
        }

    async def test_inline_evaluation_through_the_api(self, client, mock_mode):
        call = await db.fetchrow("select id from calls order by started_at desc limit 1")
        r = await client.post(
            f"/api/evaluations/calls/{call['id']}",
            json={"run_inline": True, "trigger_reason": "manual_rerun"},
        )
        assert r.status_code == 202
        body = r.json()
        assert body["score_percentage"] is not None
        await drop_evaluation(body["evaluation_id"])

    async def test_queued_evaluation_creates_a_job(self, client, mock_mode):
        call = await db.fetchrow("select id from calls order by started_at limit 1")
        r = await client.post(f"/api/evaluations/calls/{call['id']}", json={})
        assert r.status_code == 202
        body = r.json()
        assert body["status"] == "queued"

        job = await db.fetchrow(
            "select status::text as status, job_type::text as job_type from jobs where id = $1::uuid",
            body["job_id"],
        )
        assert job["status"] == "queued"
        assert job["job_type"] == "evaluate"

        await db.execute("delete from jobs where id = $1::uuid", body["job_id"])
        await drop_evaluation(body["evaluation_id"])


class TestAgentRunTelemetry:
    """attempt_count must mean 'how many retries did this need', not 'how many
    requests did it make'. The scoring agent issues one request per sub-section,
    so summing raw attempts reported a clean 12-request run as 'retried x12' in
    the pipeline UI — a number that looked alarming and meant nothing."""

    async def test_clean_run_records_no_retries(self, evaluated_call):
        row = await db.fetchrow(
            """
            select attempt_count, parsed_output from agent_runs
             where evaluation_id = $1::uuid and agent_name = 'scoring'
            """,
            evaluated_call["evaluation_id"],
        )
        assert row["attempt_count"] == 1, (
            f"a run with no retries reported attempt_count={row['attempt_count']}"
        )

    async def test_request_count_is_reported_separately(self, evaluated_call):
        """The number of sub-section requests is still useful — it just is not
        the same thing as the retry count."""
        row = await db.fetchrow(
            """
            select parsed_output from agent_runs
             where evaluation_id = $1::uuid and agent_name = 'scoring'
            """,
            evaluated_call["evaluation_id"],
        )
        assert row["parsed_output"]["subsection_requests"] == 12
