"""Assistant tests.

The router and retrieval paths are exercised in MOCK mode. The security
properties of the SQL path live in test_sql_guard.py; these cover the service
behaviour around it — scoping, the index-mismatch guard, and grounding.
"""

import os

import pytest
import pytest_asyncio
from dataclasses import replace

from app import db
from app.config import get_settings
from app.llm import reset_provider
from app.security import DEV_USER
from app.services import chat_service, embedding_service


@pytest_asyncio.fixture
async def mock_mode():
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


class TestChunking:
    def test_chunks_break_on_turn_boundaries(self):
        turns = [
            {"turn_index": i, "speaker": "agent", "speaker_label": "Agent",
             "text": "word " * 60, "char_start": i * 400, "char_end": i * 400 + 300}
            for i in range(8)
        ]
        chunks = embedding_service.build_chunks(turns)
        assert len(chunks) > 1
        for c in chunks:
            assert c["turn_start"] <= c["turn_end"]

    def test_chunks_overlap_by_one_turn(self):
        """A question and its answer sit in adjacent turns. Without overlap, a
        hard cut between them makes both halves unretrievable for the query that
        wanted them together."""
        turns = [
            {"turn_index": i, "speaker": "agent", "speaker_label": "Agent",
             "text": "word " * 60, "char_start": i * 400, "char_end": i * 400 + 300}
            for i in range(8)
        ]
        chunks = embedding_service.build_chunks(turns)
        for a, b in zip(chunks, chunks[1:]):
            assert b["turn_start"] <= a["turn_end"]

    def test_empty_input(self):
        assert embedding_service.build_chunks([]) == []

    def test_single_short_turn_still_produces_a_chunk(self):
        chunks = embedding_service.build_chunks(
            [{"turn_index": 0, "speaker": "agent", "speaker_label": "Agent",
              "text": "Hello.", "char_start": 0, "char_end": 13}]
        )
        assert len(chunks) == 1


class TestRouting:
    async def test_analytical_question_routes_to_a_query(self, client, mock_mode):
        result = await chat_service.ask(DEV_USER, "Which agents scored lowest on empathy?")
        assert result["retrieval_mode"] == "analytical"
        assert result["generated_sql"]
        assert result["sql_error"] is None
        assert len(result["rows"]) > 0

    async def test_semantic_question_routes_to_transcripts(self, client, mock_mode):
        result = await chat_service.ask(
            DEV_USER, "Show me calls where the customer mentioned billing issues"
        )
        assert result["retrieval_mode"] == "semantic"
        assert result["citations"]
        assert all(c["call_code"] for c in result["citations"])

    async def test_every_citation_points_at_a_real_call(self, client, mock_mode):
        """A citation to a call that does not exist is worse than no citation."""
        result = await chat_service.ask(DEV_USER, "find calls about a router problem")
        for c in result["citations"]:
            exists = await db.fetchval(
                "select exists (select 1 from calls where id = $1::uuid)", c["call_id"]
            )
            assert exists, f"cited a non-existent call: {c['call_code']}"

    async def test_citations_carry_turn_ranges(self, client, mock_mode):
        """Turn ranges are what let a citation be traced back into the
        transcript, the same mechanism the scores use."""
        result = await chat_service.ask(DEV_USER, "find calls about cancellation")
        for c in result["citations"]:
            assert c["turn_start"] <= c["turn_end"]


class TestScoping:
    async def test_manager_only_sees_their_own_team(self, client, mock_mode):
        """The assistant must not become a way around the access model."""
        team = await db.fetchrow("select id, name from teams order by code limit 1")
        manager = replace(DEV_USER, role="manager", team_id=str(team["id"]), id=None)

        result = await chat_service.ask(manager, "find calls about billing")
        for c in result["citations"]:
            assert c["team_name"] == team["name"]

    async def test_agent_without_a_profile_sees_nothing(self, client, mock_mode):
        orphan = replace(DEV_USER, role="agent", team_id=None, id=None)
        result = await chat_service.ask(orphan, "find calls about billing")
        assert result["citations"] == []


class TestIndexIntegrity:
    async def test_coverage_reports_the_model_mix(self, client, mock_mode):
        status = await embedding_service.coverage()
        assert status["chunks"] > 0
        assert status["missing_vectors"] == 0
        assert status["current_model"] == "mock"

    async def test_search_refuses_a_mismatched_index(self, client, mock_mode):
        """Vectors from two embedding models share a coordinate space only by
        coincidence. Searching across them returns confidently-ranked nonsense,
        which the user cannot detect — so it must fail loudly instead."""
        await db.execute(
            "update transcript_chunks set embedding_model = 'some-other-model' "
            "where chunk_index = 0"
        )
        try:
            with pytest.raises(chat_service.IndexMismatch, match="different embedding model"):
                await chat_service._semantic_search("billing", DEV_USER)
        finally:
            await db.execute("update transcript_chunks set embedding_model = 'mock'")

    async def test_ask_degrades_instead_of_failing(self, client, mock_mode):
        """A mismatched index must not 500 the whole request — the answer says
        what is wrong rather than the endpoint erroring."""
        await db.execute(
            "update transcript_chunks set embedding_model = 'x' where chunk_index = 0"
        )
        try:
            result = await chat_service.ask(DEV_USER, "find calls about billing")
            assert result["index_error"]
            assert "rebuild" in result["answer"].lower() or "different embedding" in result["index_error"]
        finally:
            await db.execute("update transcript_chunks set embedding_model = 'mock'")


class TestChatApi:
    async def test_ask_endpoint_returns_the_grounding_trail(self, client):
        r = await client.post(
            "/api/chat/ask", json={"question": "Which agents scored lowest on empathy?"}
        )
        assert r.status_code == 200
        body = r.json()
        for field in ("answer", "retrieval_mode", "citations", "rows",
                      "generated_sql", "confidence", "model", "latency_ms"):
            assert field in body, f"missing {field}"

    async def test_index_status_endpoint(self, client):
        body = (await client.get("/api/chat/index/status")).json()
        assert body["with_transcript"] == 84
        assert body["embedded"] == 84
        assert "models_in_index" in body


class TestRetrievalFailsClosed:
    """Retrieval is an access path. An earlier version applied a filter only for
    managers, so an agent with no linked support_agents row fell through to NO
    filter and could retrieve every team's transcripts. These pin the closed
    default for each role."""

    async def test_agent_sees_only_their_own_calls(self, client, mock_mode):
        agent = await db.fetchrow(
            "select id, full_name from support_agents where is_active limit 1"
        )
        # Link a synthetic profile so the agent role resolves to a real row.
        profile_id = await db.fetchval(
            """
            insert into auth.users (id, email) values (gen_random_uuid(), 'agent-test@example.com')
            returning id
            """
        )
        await db.execute(
            "update profiles set role = 'agent' where id = $1", profile_id
        )
        await db.execute(
            "update support_agents set profile_id = $1 where id = $2", profile_id, agent["id"]
        )
        try:
            user = replace(DEV_USER, role="agent", team_id=None, id=str(profile_id))
            result = await chat_service.ask(user, "find calls about billing")
            for c in result["citations"]:
                assert c["agent_name"] == agent["full_name"], (
                    "an agent retrieved another agent's transcript"
                )
        finally:
            await db.execute(
                "update support_agents set profile_id = null where id = $1", agent["id"]
            )
            await db.execute("delete from auth.users where id = $1", profile_id)

    async def test_unknown_role_retrieves_nothing(self, client, mock_mode):
        stranger = replace(DEV_USER, role="agent", team_id=None, id=None)
        assert await chat_service._semantic_search("billing", stranger) == []

    async def test_manager_without_a_team_retrieves_nothing(self, client, mock_mode):
        orphan = replace(DEV_USER, role="manager", team_id=None, id=None)
        assert await chat_service._semantic_search("billing", orphan) == []
