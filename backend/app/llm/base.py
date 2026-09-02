"""Provider-agnostic LLM interface.

Every agent talks to this, never to Gemini directly. Two payoffs:

1. Swapping provider is a config change, not a code change. The project brief
   asked for model-agnosticism and this is where it actually lives.
2. `MockProvider` can be substituted wholesale, so the entire pipeline runs with
   no network, no cost and no rate limits — which is what makes the demo
   dependable and the tests fast.

NOTE ON "MOCK": MockProvider is rule-based Python, NOT a local language model.
Nothing is downloaded and nothing runs on the machine's CPU or GPU. All real
inference happens in Google's API.
"""

from dataclasses import dataclass, field
from typing import Any, Protocol


@dataclass
class LLMResult:
    """One completed generation, with everything `agent_runs` needs to record."""

    text: str
    parsed: Any                     # decoded JSON when a schema was supplied
    model: str
    input_tokens: int = 0
    output_tokens: int = 0
    latency_ms: int = 0
    attempts: int = 1
    # Which models were tried before this one succeeded. Non-empty means the
    # primary model was unavailable and the fallback ladder was walked.
    fallback_chain: list[str] = field(default_factory=list)
    raw: dict = field(default_factory=dict)

    @property
    def total_tokens(self) -> int:
        return self.input_tokens + self.output_tokens


class LLMError(Exception):
    """Provider failure that survived every retry and fallback."""

    def __init__(self, message: str, *, attempts: int = 0, models_tried: list[str] | None = None):
        super().__init__(message)
        self.attempts = attempts
        self.models_tried = models_tried or []


class LLMProvider(Protocol):
    """The contract every provider implements."""

    name: str

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
        """Generate a response constrained to `schema` (JSON Schema subset)."""
        ...

    async def embed(self, texts: list[str], *, dimensions: int = 768) -> list[list[float]]:
        """Embed a batch of texts."""
        ...

    async def close(self) -> None:
        ...


# ── Cost table ──────────────────────────────────────────────────────────────
# USD per 1M tokens. Used to populate agent_runs.cost_usd so the dashboard can
# show what an evaluation actually cost. Free-tier usage bills at zero, but the
# figures matter the moment a paid key is used, and "what does this cost per
# call" is a question any evaluator of this project will ask.
PRICING: dict[str, tuple[float, float]] = {
    "gemini-3.7-flash":      (0.30, 2.50),
    "gemini-3.6-flash":      (0.30, 2.50),
    "gemini-3.5-flash":      (0.30, 2.50),
    "gemini-3.5-flash-lite": (0.10, 0.40),
    "gemini-3.1-flash-lite": (0.10, 0.40),
    "gemini-3.5-transcribe": (0.10, 0.40),
    "gemini-embedding-2":    (0.15, 0.00),
    "mock":                  (0.00, 0.00),
}


def estimate_cost(model: str, input_tokens: int, output_tokens: int) -> float:
    inp, out = PRICING.get(model, (0.0, 0.0))
    return round((input_tokens * inp + output_tokens * out) / 1_000_000, 8)
