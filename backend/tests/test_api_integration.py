"""End-to-end API tests against the real seeded database."""

import io
import json

import pytest

from app import db

pytestmark = pytest.mark.asyncio


class TestHealthAndReference:
    async def test_health_reports_live_framework(self, client):
        r = await client.get("/health")
        assert r.status_code == 200
        body = r.json()
        assert body["database"] == "connected"
        assert body["active_criteria"] == 31
        assert body["framework_version"] == 1

    async def test_teams_and_agents(self, client):
        teams = (await client.get("/api/teams")).json()
        assert {t["code"] for t in teams} == {"BILLING", "TECH", "RETENTION"}

        agents = (await client.get("/api/agents")).json()
        assert len(agents) == 9


class TestFrameworkRead:
    async def test_active_tree_is_complete_and_balanced(self, client):
        tree = (await client.get("/api/framework/active")).json()
        assert tree["status"] == "published"
        assert len(tree["sections"]) == 5
        assert sum(s["weight"] for s in tree["sections"]) == 100

        for section in tree["sections"]:
            assert sum(ss["weight"] for ss in section["subsections"]) == 100
            for sub in section["subsections"]:
                assert sum(c["weight"] for c in sub["criteria"]) == 100

    async def test_guidance_is_exposed(self, client):
        """guidance drives the scoring prompt, so it must reach the API."""
        tree = (await client.get("/api/framework/active")).json()
        criteria = [
            c for s in tree["sections"] for ss in s["subsections"] for c in ss["criteria"]
        ]
        assert len(criteria) == 31
        assert all(c["guidance"] for c in criteria)

        critical = [c["code"] for c in criteria if c["is_critical"]]
        assert set(critical) == {"RECORDING_DISCLOSURE", "IDENTITY_VERIFICATION"}

    async def test_validation_passes_on_published_version(self, client):
        version_id = (await client.get("/api/framework/active")).json()["id"]
        result = (await client.get(f"/api/framework/versions/{version_id}/validate")).json()
        assert result["is_valid"] is True
        assert result["issues"] == []


class TestPublishedImmutability:
    """The core guarantee: a published rubric cannot be edited in place."""

    async def test_editing_published_criterion_is_rejected(self, client):
        tree = (await client.get("/api/framework/active")).json()
        criterion = tree["sections"][0]["subsections"][0]["criteria"][0]

        r = await client.patch(
            f"/api/framework/criteria/{criterion['id']}", json={"weight": 99}
        )
        assert r.status_code == 409
        assert "cannot be edited" in r.json()["error"]["message"].lower()

    async def test_deleting_published_section_is_rejected(self, client):
        tree = (await client.get("/api/framework/active")).json()
        r = await client.delete(f"/api/framework/sections/{tree['sections'][0]['id']}")
        assert r.status_code == 409

    async def test_adding_to_published_version_is_rejected(self, client):
        tree = (await client.get("/api/framework/active")).json()
        r = await client.post(
            "/api/framework/sections",
            json={
                "framework_version_id": tree["id"],
                "code": "SNEAKY",
                "name": "Should not be allowed",
                "weight": 10,
            },
        )
        assert r.status_code == 409


class TestDraftLifecycle:
    async def test_full_edit_and_publish_cycle(self, client, clean_framework):
        """The complete admin-panel journey, end to end."""
        # 1. Ask for an editable draft — clones the published version.
        draft = (await client.post("/api/framework/draft")).json()
        assert draft["status"] == "draft"
        assert draft["version_no"] == 2
        assert len(draft["sections"]) == 5

        # 2. Re-weight two sections, leaving the tree unbalanced (85 total).
        resolution = next(s for s in draft["sections"] if s["code"] == "RESOLUTION")
        closing = next(s for s in draft["sections"] if s["code"] == "CLOSING")

        assert (await client.patch(
            f"/api/framework/sections/{resolution['id']}", json={"weight": 50}
        )).status_code == 200
        assert (await client.patch(
            f"/api/framework/sections/{closing['id']}", json={"weight": 5}
        )).status_code == 200

        # 3. Validation must catch the imbalance.
        result = (await client.get(
            f"/api/framework/versions/{draft['id']}/validate"
        )).json()
        assert result["is_valid"] is False
        assert any(i["level"] == "section" for i in result["issues"])

        # 4. Publishing an unbalanced tree must be refused.
        r = await client.post(f"/api/framework/versions/{draft['id']}/publish")
        assert r.status_code == 409

        # 5. Auto-balance, then validation passes.
        normalised = (await client.post(
            f"/api/framework/versions/{draft['id']}/normalize"
        )).json()
        assert abs(sum(s["weight"] for s in normalised["sections"]) - 100) < 0.01

        result = (await client.get(
            f"/api/framework/versions/{draft['id']}/validate"
        )).json()
        assert result["is_valid"] is True

        # 6. Publish succeeds, and v1 is archived.
        publish = (await client.post(
            f"/api/framework/versions/{draft['id']}/publish"
        )).json()
        assert publish["archived_version_id"] is not None

        active = (await client.get("/api/framework/active")).json()
        assert active["version_no"] == 2

        # 7. The newly published version is itself now immutable.
        r = await client.patch(
            f"/api/framework/sections/{resolution['id']}", json={"weight": 1}
        )
        assert r.status_code == 409

    async def test_adding_a_criterion_to_a_draft(self, client, clean_framework):
        draft = (await client.post("/api/framework/draft")).json()
        subsection = draft["sections"][0]["subsections"][0]

        r = await client.post(
            "/api/framework/criteria",
            json={
                "subsection_id": subsection["id"],
                "code": "TEST_NEW_CRITERION",
                "name": "A criterion added at runtime",
                "weight": 10,
                "scoring_type": "scale_5",
                "max_score": 5,
                "guidance": "Score 5 when the agent does the new thing.",
                "is_critical": False,
            },
        )
        assert r.status_code == 201
        assert r.json()["code"] == "TEST_NEW_CRITERION"

        # Its subsection now sums to 110, so validation must flag it.
        result = (await client.get(
            f"/api/framework/versions/{draft['id']}/validate"
        )).json()
        assert result["is_valid"] is False
        assert any(i["level"] == "criterion" for i in result["issues"])

    async def test_duplicate_code_within_a_version_is_rejected(self, client, clean_framework):
        draft = (await client.post("/api/framework/draft")).json()
        r = await client.post(
            "/api/framework/sections",
            json={
                "framework_version_id": draft["id"],
                "code": "OPENING",          # already exists in this version
                "name": "Duplicate",
                "weight": 10,
            },
        )
        assert r.status_code == 409


class TestCalls:
    async def test_list_and_filter(self, client):
        all_calls = (await client.get("/api/calls?limit=5")).json()
        assert all_calls["total"] == 84
        assert len(all_calls["items"]) == 5

        teams = (await client.get("/api/teams")).json()
        billing = next(t for t in teams if t["code"] == "BILLING")
        filtered = (await client.get(f"/api/calls?team_id={billing['id']}")).json()
        assert filtered["total"] == billing["call_count"]

    async def test_full_text_search_hits_transcripts(self, client):
        """Search must reach into transcript content, not just call metadata."""
        result = (await client.get("/api/calls?search=router")).json()
        assert result["total"] > 0

    async def test_pagination_is_stable(self, client):
        first = (await client.get("/api/calls?limit=10&offset=0")).json()
        second = (await client.get("/api/calls?limit=10&offset=10")).json()
        assert not ({c["call_code"] for c in first["items"]}
                    & {c["call_code"] for c in second["items"]})

    async def test_drill_down_returns_transcript_and_turns(self, client):
        call = (await client.get("/api/calls?limit=1")).json()["items"][0]
        detail = (await client.get(f"/api/calls/{call['call_id']}")).json()

        assert detail["transcript"]["full_text"]
        assert len(detail["turns"]) == detail["transcript"]["turn_count"]

        # Once a call has been evaluated the drill-down must carry the whole
        # picture in one response: scores with citations, rollups, and the
        # agent-run trace. Before evaluation those are empty, and both states
        # are valid — so assert consistency rather than a fixed shape.
        if detail["evaluation_id"]:
            assert len(detail["criterion_scores"]) == 31
            assert len(detail["section_scores"]) == 5
            assert len(detail["subsection_scores"]) == 12
            assert detail["agent_runs"], "an evaluated call must expose its pipeline trace"
            assert any(s["citations"] for s in detail["criterion_scores"]), \
                "at least one score must cite the transcript"
        else:
            assert detail["criterion_scores"] == []

    async def test_turn_offsets_slice_back_exactly(self, client):
        """The citation invariant, verified through the API."""
        call = (await client.get("/api/calls?limit=1")).json()["items"][0]
        detail = (await client.get(f"/api/calls/{call['call_id']}")).json()
        full_text = detail["transcript"]["full_text"]

        for turn in detail["turns"]:
            sliced = full_text[turn["char_start"]:turn["char_end"]]
            assert sliced == f"{turn['speaker_label']}: {turn['text']}"

    async def test_unknown_call_is_404(self, client):
        r = await client.get("/api/calls/00000000-0000-4000-8000-000000000000")
        assert r.status_code == 404


class TestIngestion:
    async def test_single_call_ingest(self, client, clean_calls):
        r = await client.post(
            "/api/ingestion/calls",
            json={
                "call_code": "TEST-INGEST-001",
                "agent_code": "AGT-1001",
                "transcript": (
                    "Agent: Thank you for calling Northwind, this is Priya, "
                    "the call is recorded.\n"
                    "Customer: My internet is down and I am frustrated.\n"
                    "Agent: I completely understand. Let me check the line now."
                ),
                "duration_seconds": 240,
                "started_at": "2026-09-01T10:30:00Z",
            },
        )
        assert r.status_code == 201
        body = r.json()
        assert body["turn_count"] == 3
        assert body["created"] is True
        assert body["agent_resolved"] is True

    async def test_reingest_updates_rather_than_duplicating(self, client, clean_calls):
        payload = {
            "call_code": "TEST-INGEST-002",
            "transcript": "Agent: First version.\nCustomer: Okay.",
            "agent_code": "AGT-1002",
        }
        first = (await client.post("/api/ingestion/calls", json=payload)).json()
        assert first["created"] is True

        payload["transcript"] = "Agent: Second version.\nCustomer: Okay.\nAgent: Anything else?"
        second = (await client.post("/api/ingestion/calls", json=payload)).json()
        assert second["created"] is False
        assert second["call_id"] == first["call_id"]
        assert second["turn_count"] == 3

        # The old turns must be gone, not merged — otherwise offsets would point
        # into a transcript that no longer exists.
        count = await db.fetchval(
            "select count(*) from transcript_turns where call_id = $1::uuid", first["call_id"]
        )
        assert count == 3

    async def test_json_turn_array_transcript(self, client, clean_calls):
        r = await client.post(
            "/api/ingestion/calls",
            json={
                "call_code": "TEST-INGEST-003",
                "agent_code": "AGT-1003",
                "transcript": [
                    {"speaker": "agent", "text": "Hello there.", "start_ms": 0},
                    {"speaker": "customer", "text": "Hi.", "start_ms": 1500},
                ],
            },
        )
        assert r.status_code == 201
        assert r.json()["turn_count"] == 2

    async def test_missing_transcript_is_rejected(self, client):
        r = await client.post(
            "/api/ingestion/calls", json={"call_code": "TEST-BAD", "transcript": ""}
        )
        assert r.status_code == 422

    async def test_csv_batch_tolerates_bad_rows(self, client, clean_calls):
        """Three good rows and one broken one must yield three calls, not zero."""
        csv_content = (
            "call_id,agent_id,transcript,duration,timestamp\n"
            "TEST-CSV-001,AGT-1001,\"Agent: Hello.\nCustomer: Hi.\",120,2026-08-01 10:00:00\n"
            "TEST-CSV-002,AGT-1004,\"Agent: Good day.\nCustomer: Hello.\",200,2026-08-02 11:00:00\n"
            "TEST-CSV-BAD,AGT-1001,,150,2026-08-03 12:00:00\n"
            "TEST-CSV-003,AGT-1009,\"Agent: Morning.\nCustomer: Hey.\",180,2026-08-04 09:00:00\n"
        )
        r = await client.post(
            "/api/ingestion/batch",
            files={"file": ("test_batch.csv", io.BytesIO(csv_content.encode()), "text/csv")},
        )
        assert r.status_code == 201
        body = r.json()
        assert body["succeeded"] == 3
        assert body["failed"] == 1
        assert body["errors"][0]["call_code"] == "TEST-CSV-BAD"

    async def test_json_batch_with_alias_columns(self, client, clean_calls):
        """conversation_id/body/agent must map onto our canonical field names."""
        payload = [
            {
                "conversation_id": "TEST-JSON-001",
                "agent": "AGT-1005",
                "body": "Agent: Hello.\nCustomer: Hi there.",
                "length": 90,
                "queue_name": "tech_tier1",     # unrecognised -> metadata
            }
        ]
        r = await client.post(
            "/api/ingestion/batch",
            files={"file": ("test_batch.json", io.BytesIO(json.dumps(payload).encode()),
                            "application/json")},
        )
        assert r.status_code == 201
        assert r.json()["succeeded"] == 1

        meta = await db.fetchval(
            "select metadata from calls where call_code = 'TEST-JSON-001'"
        )
        assert meta["queue_name"] == "tech_tier1"

    async def test_batch_is_recorded_with_error_log(self, client, clean_calls):
        csv_content = "call_id,transcript\nTEST-LOG-001,\"Agent: Hi.\"\nTEST-LOG-BAD,\n"
        r = await client.post(
            "/api/ingestion/batch",
            files={"file": ("test_log.csv", io.BytesIO(csv_content.encode()), "text/csv")},
        )
        batch_id = r.json()["batch_id"]

        batch = (await client.get(f"/api/ingestion/batches/{batch_id}")).json()
        assert batch["status"] == "completed_with_errors"
        assert batch["succeeded"] == 1
        assert batch["failed"] == 1
        assert len(batch["error_log"]) == 1
