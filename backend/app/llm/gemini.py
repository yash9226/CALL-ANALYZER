"""Gemini provider.

RELIABILITY IS THE HARD PART, NOT THE API CALL
----------------------------------------------
Google's free tier returns HTTP 503 "experiencing high demand" under load, and
sometimes simply hangs. This was observed repeatedly while building the project,
not anticipated defensively. A naive client would fail an entire 84-call
evaluation run because one request landed during a spike.

So every request walks two loops:

  for model in [primary, *fallbacks]:        # ladder
      for attempt in 1..max_retries:         # backoff
          try it

Retryable: 429 (rate limit), 500/502/503/504, timeouts, connection errors.
Not retryable: 400 (malformed request) and 403 (bad key) — retrying a broken
request just wastes the quota, so those fail immediately.

Structured output uses Gemini's native `responseSchema`, which constrains
decoding to the schema rather than asking the model nicely for JSON and hoping.
That removes an entire class of parse failures.
"""

import asyncio
import json
import logging
import time
from typing import Any

import httpx

from app.llm.base import LLMError, LLMResult, estimate_cost

log = logging.getLogger(__name__)

API_ROOT = "https://generativelanguage.googleapis.com/v1beta"

_RETRYABLE_STATUS = {408, 429, 500, 502, 503, 504}


class GeminiProvider:
    name = "gemini"

    def __init__(
        self,
        api_key: str,
        *,
        default_model: str = "gemini-3.6-flash",
        fallback_models: list[str] | None = None,
        embedding_model: str = "gemini-embedding-2",
        max_retries: int = 4,
        timeout_seconds: int = 120,
        backoff_base_seconds: int = 2,
    ):
        if not api_key:
            raise ValueError("GEMINI_API_KEY is not set.")
        self.api_key = api_key
        self.default_model = default_model
        self.embedding_model = embedding_model
        self.max_retries = max_retries
        self.backoff_base = backoff_base_seconds

        # The ladder always starts with the requested model, then any configured
        # fallbacks that are not already in it.
        self.fallback_models = [m for m in (fallback_models or []) if m != default_model]

        self._client = httpx.AsyncClient(
            timeout=httpx.Timeout(timeout_seconds, connect=15.0),
            limits=httpx.Limits(max_connections=8, max_keepalive_connections=4),
        )

    async def close(self) -> None:
        await self._client.aclose()

    # ── Core request with retry + fallback ──────────────────────────────────

    async def _post(self, path: str, payload: dict) -> tuple[dict, int, str, list[str]]:
        """POST with backoff across a model ladder.

        Returns (response_json, total_attempts, model_that_succeeded,
        models_that_failed_first).
        """
        model = path.split("/")[1].split(":")[0]
        ladder = [model, *self.fallback_models]

        attempts = 0
        tried: list[str] = []
        last_error = "unknown error"

        for candidate in ladder:
            candidate_path = path.replace(f"models/{model}:", f"models/{candidate}:", 1)
            url = f"{API_ROOT}/{candidate_path}"

            for attempt in range(1, self.max_retries + 1):
                attempts += 1
                try:
                    response = await self._client.post(
                        url,
                        json=payload,
                        headers={
                            "Content-Type": "application/json",
                            "x-goog-api-key": self.api_key,
                        },
                    )
                except (httpx.TimeoutException, httpx.TransportError) as exc:
                    last_error = f"{type(exc).__name__}: {exc}"
                    log.warning(
                        "gemini %s attempt %s/%s network failure: %s",
                        candidate, attempt, self.max_retries, last_error,
                    )
                else:
                    if response.status_code == 200:
                        # `tried` holds only the models that FAILED before this
                        # one. Returning the successful candidate explicitly is
                        # what makes agent_runs.model record the model that
                        # actually produced the output.
                        return response.json(), attempts, candidate, tried

                    body = response.text[:400]
                    last_error = f"HTTP {response.status_code}: {body}"

                    # A malformed request or a bad key will fail identically
                    # forever. Burning retries and quota on it helps nobody.
                    if response.status_code in (400, 401, 403, 404):
                        log.error("gemini %s non-retryable: %s", candidate, last_error)
                        break

                    if response.status_code not in _RETRYABLE_STATUS:
                        break

                    log.warning(
                        "gemini %s attempt %s/%s retryable: %s",
                        candidate, attempt, self.max_retries, last_error[:160],
                    )

                if attempt < self.max_retries:
                    # Exponential backoff with a small deterministic jitter, so
                    # concurrent workers do not retry in lockstep and re-create
                    # the very spike they are backing off from.
                    delay = self.backoff_base ** attempt + (attempts % 3) * 0.25
                    await asyncio.sleep(min(delay, 30))

            tried.append(candidate)
            if candidate != ladder[-1]:
                log.warning("gemini falling back from %s to next model", candidate)

        raise LLMError(
            f"All models exhausted after {attempts} attempts. Last error: {last_error}",
            attempts=attempts,
            models_tried=tried,
        )

    # ── Generation ──────────────────────────────────────────────────────────

    async def generate_json(
        self,
        prompt: str,
        schema: dict,
        *,
        system: str | None = None,
        model: str | None = None,
        temperature: float = 0.1,
        max_output_tokens: int = 8192,
    ) -> LLMResult:
        chosen = model or self.default_model
        started = time.perf_counter()

        payload: dict[str, Any] = {
            "contents": [{"role": "user", "parts": [{"text": prompt}]}],
            "generationConfig": {
                # Native constrained decoding. The model cannot emit a shape that
                # violates the schema, which removes JSON parse failures as a
                # class of bug rather than handling them after the fact.
                "responseMimeType": "application/json",
                "responseSchema": schema,
                # Low but non-zero: scoring should be near-deterministic, while
                # exactly 0 makes some models repeat degenerate phrasing.
                "temperature": temperature,
                "maxOutputTokens": max_output_tokens,
            },
        }
        if system:
            payload["systemInstruction"] = {"parts": [{"text": system}]}

        data, attempts, actual_model, failed_first = await self._post(
            f"models/{chosen}:generateContent", payload
        )
        latency_ms = int((time.perf_counter() - started) * 1000)

        try:
            text = data["candidates"][0]["content"]["parts"][0]["text"]
        except (KeyError, IndexError) as exc:
            finish = (data.get("candidates") or [{}])[0].get("finishReason", "unknown")
            raise LLMError(
                f"Gemini returned no usable content (finishReason={finish}): {exc}"
            ) from exc

        try:
            parsed = json.loads(text)
        except json.JSONDecodeError as exc:
            # Should be impossible with responseSchema, but a truncated response
            # (hitting maxOutputTokens) can still cut valid JSON in half.
            raise LLMError(f"Response was not valid JSON: {exc}. First 200 chars: {text[:200]}")

        usage = data.get("usageMetadata", {})
        return LLMResult(
            text=text,
            parsed=parsed,
            model=actual_model,
            input_tokens=usage.get("promptTokenCount", 0),
            output_tokens=usage.get("candidatesTokenCount", 0),
            latency_ms=latency_ms,
            attempts=attempts,
            fallback_chain=failed_first,
            raw=data,
        )

    # ── Embeddings ──────────────────────────────────────────────────────────

    async def embed(self, texts: list[str], *, dimensions: int = 768) -> list[list[float]]:
        """Embed texts one call at a time.

        768 dimensions rather than the model's native 3072: pgvector's HNSW
        index cannot exceed 2000, and the vector(768) column is fixed in
        migration 0008.
        """
        vectors: list[list[float]] = []
        for text in texts:
            data, _, _, _ = await self._post(
                f"models/{self.embedding_model}:embedContent",
                {
                    "content": {"parts": [{"text": text}]},
                    "outputDimensionality": dimensions,
                },
            )
            values = data.get("embedding", {}).get("values")
            if not values:
                raise LLMError(f"Embedding response contained no values: {str(data)[:200]}")
            vectors.append(values)
        return vectors

    async def transcribe(self, audio_bytes: bytes, mime_type: str, model: str) -> LLMResult:
        """Audio -> diarised transcript, via the API. No local model."""
        import base64

        started = time.perf_counter()
        payload = {
            "contents": [{
                "role": "user",
                "parts": [
                    {"text": (
                        "Transcribe this customer support call verbatim. Label every turn "
                        "as either 'Agent:' or 'Customer:' at the start of the line. "
                        "Do not summarise, correct, or omit anything."
                    )},
                    {"inlineData": {
                        "mimeType": mime_type,
                        "data": base64.b64encode(audio_bytes).decode(),
                    }},
                ],
            }],
            "generationConfig": {"temperature": 0.0},
        }
        data, attempts, actual_model, _ = await self._post(
            f"models/{model}:generateContent", payload
        )
        text = data["candidates"][0]["content"]["parts"][0]["text"]
        usage = data.get("usageMetadata", {})
        return LLMResult(
            text=text, parsed=None, model=actual_model,
            input_tokens=usage.get("promptTokenCount", 0),
            output_tokens=usage.get("candidatesTokenCount", 0),
            latency_ms=int((time.perf_counter() - started) * 1000),
            attempts=attempts, raw=data,
        )
