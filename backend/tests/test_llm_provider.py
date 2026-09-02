"""LLM provider tests.

The retry and fallback logic is tested against a stubbed transport rather than
the live API. That matters because the behaviour worth testing is exactly what
happens when the API MISBEHAVES — 503s, timeouts, malformed responses — and you
cannot ask Google to produce those on demand.
"""

import json

import httpx
import pytest

from app.llm.base import LLMError, estimate_cost
from app.llm.gemini import GeminiProvider


def _ok(payload: dict, tokens: tuple[int, int] = (100, 50)) -> httpx.Response:
    return httpx.Response(
        200,
        json={
            "candidates": [{"content": {"parts": [{"text": json.dumps(payload)}]}}],
            "usageMetadata": {
                "promptTokenCount": tokens[0], "candidatesTokenCount": tokens[1]
            },
        },
    )


def _make_provider(handler, **kwargs) -> GeminiProvider:
    provider = GeminiProvider(
        api_key="test-key",
        default_model="model-a",
        fallback_models=["model-b", "model-c"],
        backoff_base_seconds=0,          # no real sleeping in tests
        max_retries=kwargs.pop("max_retries", 3),
        **kwargs,
    )
    provider._client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    return provider


SCHEMA = {"type": "OBJECT", "properties": {"score": {"type": "NUMBER"}}}


class TestRetryBehaviour:
    async def test_succeeds_first_time(self):
        provider = _make_provider(lambda r: _ok({"score": 4}))
        result = await provider.generate_json("prompt", SCHEMA)
        assert result.parsed == {"score": 4}
        assert result.attempts == 1
        await provider.close()

    async def test_retries_a_503_then_succeeds(self):
        """Gemini's free tier returns 503 under load. This is the case the
        retry loop exists for, and it was observed repeatedly in practice."""
        calls = {"n": 0}

        def handler(request):
            calls["n"] += 1
            if calls["n"] < 3:
                return httpx.Response(503, json={"error": {"message": "high demand"}})
            return _ok({"score": 5})

        provider = _make_provider(handler)
        result = await provider.generate_json("prompt", SCHEMA)
        assert result.parsed == {"score": 5}
        assert result.attempts == 3
        await provider.close()

    async def test_retries_a_timeout(self):
        calls = {"n": 0}

        def handler(request):
            calls["n"] += 1
            if calls["n"] == 1:
                raise httpx.ReadTimeout("timed out", request=request)
            return _ok({"score": 3})

        provider = _make_provider(handler)
        result = await provider.generate_json("prompt", SCHEMA)
        assert result.attempts == 2
        await provider.close()

    async def test_does_not_retry_a_400(self):
        """A malformed request fails identically forever. Retrying it only burns
        quota, so it must break out immediately."""
        calls = {"n": 0}

        def handler(request):
            calls["n"] += 1
            return httpx.Response(400, json={"error": {"message": "bad request"}})

        provider = _make_provider(handler)
        with pytest.raises(LLMError):
            await provider.generate_json("prompt", SCHEMA)
        # One attempt per model in the ladder, never repeated within a model.
        assert calls["n"] == 3
        await provider.close()

    async def test_does_not_retry_a_403(self):
        provider = _make_provider(lambda r: httpx.Response(403, json={"error": {}}))
        with pytest.raises(LLMError):
            await provider.generate_json("prompt", SCHEMA)
        await provider.close()


class TestFallbackLadder:
    async def test_falls_through_to_the_next_model(self):
        seen: list[str] = []

        def handler(request):
            model = str(request.url).split("/models/")[1].split(":")[0]
            seen.append(model)
            if model == "model-a":
                return httpx.Response(503, json={"error": {}})
            return _ok({"score": 4})

        provider = _make_provider(handler)
        result = await provider.generate_json("prompt", SCHEMA)
        assert result.model == "model-b"
        assert result.fallback_chain == ["model-a"]
        assert seen.count("model-a") == 3       # exhausted its retries first
        await provider.close()

    async def test_reports_every_model_tried_when_all_fail(self):
        provider = _make_provider(lambda r: httpx.Response(503, json={"error": {}}))
        with pytest.raises(LLMError) as exc:
            await provider.generate_json("prompt", SCHEMA)
        assert exc.value.models_tried == ["model-a", "model-b", "model-c"]
        assert exc.value.attempts == 9          # 3 models x 3 retries
        await provider.close()


class TestResponseHandling:
    async def test_truncated_json_raises_a_clear_error(self):
        """responseSchema makes this rare, but hitting maxOutputTokens can still
        cut valid JSON in half."""
        def handler(request):
            return httpx.Response(200, json={
                "candidates": [{"content": {"parts": [{"text": '{\"score\": 4'}]}}],
            })

        provider = _make_provider(handler)
        with pytest.raises(LLMError, match="not valid JSON"):
            await provider.generate_json("prompt", SCHEMA)
        await provider.close()

    async def test_blocked_response_names_the_finish_reason(self):
        def handler(request):
            return httpx.Response(200, json={"candidates": [{"finishReason": "SAFETY"}]})

        provider = _make_provider(handler)
        with pytest.raises(LLMError, match="SAFETY"):
            await provider.generate_json("prompt", SCHEMA)
        await provider.close()

    async def test_schema_is_sent_for_constrained_decoding(self):
        """Structured output must use Gemini's responseSchema, not a prompt
        instruction — that is what removes JSON parse failures as a class."""
        captured = {}

        def handler(request):
            captured.update(json.loads(request.content))
            return _ok({"score": 4})

        provider = _make_provider(handler)
        await provider.generate_json("prompt", SCHEMA, system="be terse")
        assert captured["generationConfig"]["responseMimeType"] == "application/json"
        assert captured["generationConfig"]["responseSchema"] == SCHEMA
        assert captured["systemInstruction"]["parts"][0]["text"] == "be terse"
        await provider.close()


class TestEmbeddings:
    async def test_requests_the_configured_dimensionality(self):
        """768, not the native 3072: pgvector's HNSW index caps at 2000."""
        captured = {}

        def handler(request):
            captured.update(json.loads(request.content))
            return httpx.Response(200, json={"embedding": {"values": [0.1] * 768}})

        provider = _make_provider(handler)
        vectors = await provider.embed(["hello"], dimensions=768)
        assert captured["outputDimensionality"] == 768
        assert len(vectors[0]) == 768
        await provider.close()


class TestMockProvider:
    async def test_produces_deterministic_embeddings(self):
        from app.llm.mock import MockProvider

        provider = MockProvider()
        first = await provider.embed(["billing dispute"])
        second = await provider.embed(["billing dispute"])
        assert first == second
        assert len(first[0]) == 768
        # Normalised, so cosine similarity is well behaved.
        assert abs(sum(v * v for v in first[0]) - 1.0) < 1e-6

    async def test_different_text_gives_different_vectors(self):
        from app.llm.mock import MockProvider

        provider = MockProvider()
        vectors = await provider.embed(["billing dispute", "router setup"])
        assert vectors[0] != vectors[1]


class TestCostEstimation:
    def test_prices_a_known_model(self):
        assert estimate_cost("gemini-3.6-flash", 1_000_000, 0) == 0.30

    def test_mock_is_free(self):
        assert estimate_cost("mock", 999_999, 999_999) == 0.0

    def test_unknown_model_does_not_crash(self):
        assert estimate_cost("some-future-model", 1000, 1000) == 0.0
