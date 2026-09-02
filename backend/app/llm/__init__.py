"""LLM provider factory.

`get_provider()` returns the configured provider as a process-wide singleton so
the HTTP connection pool is shared across every agent and worker task.
"""

import logging

from app.config import get_settings
from app.llm.base import LLMError, LLMProvider, LLMResult, estimate_cost
from app.llm.gemini import GeminiProvider
from app.llm.mock import MockProvider

log = logging.getLogger(__name__)

_provider: LLMProvider | None = None


def get_provider() -> LLMProvider:
    global _provider
    if _provider is not None:
        return _provider

    settings = get_settings()

    if settings.mock_llm:
        log.warning("MOCK_LLM is ON — using deterministic rule-based fixtures, no API calls")
        _provider = MockProvider()
    elif settings.llm_provider == "gemini":
        _provider = GeminiProvider(
            api_key=settings.gemini_api_key,
            default_model=settings.gemini_scoring_model,
            fallback_models=settings.fallback_model_list,
            embedding_model=settings.gemini_embedding_model,
            max_retries=settings.llm_max_retries,
            timeout_seconds=settings.llm_timeout_seconds,
            backoff_base_seconds=settings.llm_backoff_base_seconds,
        )
        log.info("LLM provider: gemini (%s)", settings.gemini_scoring_model)
    else:
        raise ValueError(f"Unknown LLM_PROVIDER: {settings.llm_provider}")

    return _provider


async def close_provider() -> None:
    global _provider
    if _provider is not None:
        await _provider.close()
        _provider = None


def reset_provider() -> None:
    """Drop the cached provider so tests can flip MOCK_LLM between cases."""
    global _provider
    _provider = None


__all__ = [
    "get_provider", "close_provider", "reset_provider",
    "LLMProvider", "LLMResult", "LLMError", "estimate_cost",
    "GeminiProvider", "MockProvider",
]
