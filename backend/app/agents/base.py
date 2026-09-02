"""Agent base class and the shared pipeline context.

EVERY AGENT INVOCATION IS RECORDED
----------------------------------
`Agent.run()` wraps each agent in an `agent_runs` row capturing the prompt hash,
model, raw and parsed output, token counts, latency and retry count. That table
is what makes the multi-agent design *inspectable* rather than merely asserted:
open any call in the UI and you see five discrete agent invocations with their
own inputs and outputs.

It is also the debugging tool. When a score looks wrong, the exact prompt that
produced it is one query away.

FAILURE POLICY
--------------
An agent declares whether it is `critical`. A failed critical agent (scoring)
fails the evaluation, because a call with no scores is not an evaluation. A
failed non-critical agent (sentiment, risk, summary) is recorded as failed and
the pipeline continues — a missing summary is a degraded result, not a reason to
throw away 31 perfectly good scores.
"""

import hashlib
import json
import logging
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any
from uuid import UUID

from app import db
from app.llm import LLMError, estimate_cost, get_provider

log = logging.getLogger(__name__)


@dataclass
class PipelineContext:
    """State threaded through the pipeline. Each agent reads it and adds to it."""

    call_id: UUID
    evaluation_id: UUID
    framework_version_id: UUID

    call: dict = field(default_factory=dict)
    turns: list[dict] = field(default_factory=list)
    full_text: str = ""
    # The rubric tree flattened for prompting: one entry per enabled subsection,
    # each carrying its enabled criteria with their guidance text.
    subsections: list[dict] = field(default_factory=list)

    # Outputs, filled in as agents complete.
    statistics: dict = field(default_factory=dict)
    scores: list[dict] = field(default_factory=list)
    summary: dict = field(default_factory=dict)
    sentiment: dict = field(default_factory=dict)
    risk_flags: list[dict] = field(default_factory=list)

    # Telemetry, accumulated across every agent.
    total_input_tokens: int = 0
    total_output_tokens: int = 0
    total_cost_usd: float = 0.0
    models_used: set[str] = field(default_factory=set)
    failures: list[str] = field(default_factory=list)

    def turn_by_index(self, index: int) -> dict | None:
        return next((t for t in self.turns if t["turn_index"] == index), None)

    def transcript_for_prompt(self, max_chars: int = 60_000) -> str:
        """Render the transcript with explicit turn numbers.

        The numbers are not decoration: the scoring agent cites a TURN INDEX
        rather than quoting free text, and the API resolves that index to stored
        character offsets. That is what makes highlighting exact instead of a
        fuzzy string match against a paraphrase.
        """
        lines = [
            f"[{t['turn_index']}] {t.get('speaker_label') or t['speaker'].title()}: {t['text']}"
            for t in self.turns
        ]
        rendered = "\n".join(lines)
        if len(rendered) > max_chars:
            # Keep both ends: openings carry compliance behaviour, closings carry
            # wrap-up behaviour. Dropping the tail would systematically penalise
            # the CLOSING section on long calls.
            head = rendered[: max_chars // 2]
            tail = rendered[-max_chars // 2 :]
            rendered = f"{head}\n\n[... middle of call omitted for length ...]\n\n{tail}"
        return rendered


class Agent(ABC):
    """One step in the pipeline."""

    name: str = "agent"
    step_order: int = 0
    prompt_version: str = "v1"
    critical: bool = False
    # Agents that compute rather than prompt (preprocessing) skip LLM plumbing.
    uses_llm: bool = True

    @abstractmethod
    async def execute(self, ctx: PipelineContext) -> Any:
        """Do the work. Raise on failure; run() handles recording."""

    async def run(self, ctx: PipelineContext) -> Any:
        run_id = await db.fetchval(
            """
            insert into agent_runs (evaluation_id, call_id, agent_name, step_order,
                                    status, prompt_version, started_at)
            values ($1, $2, $3, $4, 'running', $5, now())
            returning id
            """,
            ctx.evaluation_id, ctx.call_id, self.name, self.step_order, self.prompt_version,
        )

        started = time.perf_counter()
        try:
            result = await self.execute(ctx)
        except Exception as exc:  # noqa: BLE001 - recorded, then re-raised if critical
            latency = int((time.perf_counter() - started) * 1000)
            attempts = getattr(exc, "attempts", 1)
            await db.execute(
                """
                update agent_runs
                   set status = 'failed', error_type = $2, error_message = $3,
                       latency_ms = $4, attempt_count = $5, completed_at = now()
                 where id = $1
                """,
                run_id, type(exc).__name__, str(exc)[:2000], latency, attempts,
            )
            ctx.failures.append(f"{self.name}: {exc}")
            log.error("agent %s failed for call %s: %s", self.name, ctx.call_id, exc)

            if self.critical:
                raise
            return None

        latency = int((time.perf_counter() - started) * 1000)
        meta = getattr(result, "_llm_meta", None) if not isinstance(result, dict) else None
        meta = meta or (result.pop("_llm_meta", None) if isinstance(result, dict) else None) or {}

        from app.config import get_settings
        capture = get_settings().debug_capture_io

        await db.execute(
            """
            update agent_runs
               set status = 'completed', model = $2, prompt_hash = $3,
                   input_tokens = $4, output_tokens = $5, cost_usd = $6,
                   latency_ms = $7, attempt_count = $8,
                   input_payload = $9::jsonb, raw_output = $10::jsonb,
                   parsed_output = $11::jsonb, completed_at = now()
             where id = $1
            """,
            run_id,
            meta.get("model"),
            meta.get("prompt_hash"),
            meta.get("input_tokens", 0),
            meta.get("output_tokens", 0),
            meta.get("cost_usd", 0.0),
            latency,
            meta.get("attempts", 1),
            {"prompt": meta.get("prompt")} if capture and meta.get("prompt") else None,
            {"text": meta.get("raw_text")} if capture and meta.get("raw_text") else None,
            result if capture and isinstance(result, (dict, list)) else None,
        )

        ctx.total_input_tokens += meta.get("input_tokens", 0)
        ctx.total_output_tokens += meta.get("output_tokens", 0)
        ctx.total_cost_usd += meta.get("cost_usd", 0.0)
        if meta.get("model"):
            ctx.models_used.add(meta["model"])

        log.info(
            "agent %s completed for call %s in %sms (%s tokens)",
            self.name, ctx.call_id, latency,
            meta.get("input_tokens", 0) + meta.get("output_tokens", 0),
        )
        return result


async def call_llm(
    prompt: str,
    schema: dict,
    *,
    task: str,
    context: dict,
    system: str | None = None,
    model: str | None = None,
    temperature: float = 0.1,
) -> tuple[Any, dict]:
    """Invoke the provider and return (parsed_output, telemetry).

    `task` and `context` are consumed by MockProvider to pick a handler; the
    Gemini provider ignores them and uses the rendered prompt.
    """
    provider = get_provider()

    kwargs: dict[str, Any] = {"system": system, "model": model, "temperature": temperature}
    if provider.name == "mock":
        kwargs |= {"task": task, "context": context}

    result = await provider.generate_json(prompt, schema, **kwargs)

    telemetry = {
        "model": result.model,
        "prompt_hash": hashlib.sha256(prompt.encode()).hexdigest()[:32],
        "prompt": prompt,
        "raw_text": result.text[:20000],
        "input_tokens": result.input_tokens,
        "output_tokens": result.output_tokens,
        "cost_usd": estimate_cost(result.model, result.input_tokens, result.output_tokens),
        "attempts": result.attempts,
        "fallback_chain": result.fallback_chain,
    }
    return result.parsed, telemetry


__all__ = ["Agent", "PipelineContext", "call_llm", "LLMError"]
