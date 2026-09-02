"""Preprocessing agent — deterministic, zero LLM cost.

Runs first and does two jobs:

1. Computes conversation statistics (talk ratio, question count, interruption
   proxy) and writes them to `call_statistics`.
2. Injects those statistics into the pipeline context so the SCORING agent can
   use them as evidence. Telling the model "the agent spoke 84% of the time"
   measurably improves its judgement on listening criteria, because that fact is
   genuinely hard to infer from reading a transcript linearly.

It costs nothing and it makes every downstream agent better, which is why it is
a distinct step rather than a helper function.
"""

import logging

from app import db
from app.agents.base import Agent, PipelineContext
from app.services.transcript_parser import ParsedTranscript, ParsedTurn, compute_statistics

log = logging.getLogger(__name__)


class PreprocessingAgent(Agent):
    name = "preprocessing"
    step_order = 1
    critical = True          # everything downstream depends on the turns loading
    uses_llm = False

    async def execute(self, ctx: PipelineContext) -> dict:
        if not ctx.turns:
            raise ValueError(f"Call {ctx.call_id} has no transcript turns to evaluate.")

        # Reuse the parser's statistics implementation rather than a second copy
        # that could drift from it.
        parsed = ParsedTranscript(
            full_text=ctx.full_text,
            turns=[
                ParsedTurn(
                    turn_index=t["turn_index"], speaker=t["speaker"],
                    speaker_label=t.get("speaker_label") or t["speaker"].title(),
                    text=t["text"], char_start=t["char_start"], char_end=t["char_end"],
                )
                for t in ctx.turns
            ],
        )
        stats = compute_statistics(parsed)
        stats["detected_language"] = ctx.call.get("language", "en")

        await db.execute(
            """
            insert into call_statistics (evaluation_id, call_id, agent_turn_count,
                customer_turn_count, agent_word_count, customer_word_count,
                agent_talk_ratio, longest_agent_turn_words, interruption_count,
                question_count_agent, filler_word_count, detected_language)
            values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            on conflict (evaluation_id) do update set
                agent_turn_count = excluded.agent_turn_count,
                customer_turn_count = excluded.customer_turn_count,
                agent_word_count = excluded.agent_word_count,
                customer_word_count = excluded.customer_word_count,
                agent_talk_ratio = excluded.agent_talk_ratio,
                longest_agent_turn_words = excluded.longest_agent_turn_words,
                interruption_count = excluded.interruption_count,
                question_count_agent = excluded.question_count_agent,
                filler_word_count = excluded.filler_word_count
            """,
            ctx.evaluation_id, ctx.call_id, stats["agent_turn_count"],
            stats["customer_turn_count"], stats["agent_word_count"],
            stats["customer_word_count"], stats["agent_talk_ratio"],
            stats["longest_agent_turn_words"], stats["interruption_count"],
            stats["question_count_agent"], stats["filler_word_count"],
            stats["detected_language"],
        )

        ctx.statistics = stats
        return stats
