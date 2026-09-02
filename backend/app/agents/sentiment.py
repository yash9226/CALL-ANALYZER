"""Sentiment agent — the customer's emotional trajectory across the call.

WHY TRAJECTORY, NOT AVERAGE
---------------------------
A call that opens at -0.8 and closes at +0.4 is a SUCCESS: the agent turned an
angry customer around. Its average sentiment is still negative, so an average
would score it the same as a call that was mildly unhappy throughout — and would
hide the single most useful coaching signal in the dataset.

`sentiment_delta` (closing minus opening) is therefore the headline metric, and
the per-turn timeline drives the sparkline in the drill-down.

Only CUSTOMER turns are scored. Agent sentiment is largely scripted and adds
noise to the trajectory without adding signal.
"""

import logging

from app import db
from app.agents.base import Agent, PipelineContext, call_llm

log = logging.getLogger(__name__)

SYSTEM = """You analyse customer emotion in support call transcripts. Judge only \
the CUSTOMER's turns. Score sentiment from -1.0 (furious) through 0.0 (neutral) \
to +1.0 (delighted). Be calibrated: mild irritation is around -0.3, not -0.9. \
Reserve extremes for genuinely extreme language."""

_LABELS = ["very_negative", "negative", "neutral", "positive", "very_positive"]

SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "overall_score": {"type": "NUMBER"},
        "overall_label": {"type": "STRING", "enum": _LABELS},
        "opening_score": {"type": "NUMBER"},
        "closing_score": {"type": "NUMBER"},
        "trajectory": {
            "type": "STRING",
            "enum": ["improving", "declining", "stable", "volatile", "recovered"],
        },
        "dominant_emotions": {"type": "OBJECT", "properties": {}},
        "analysis_notes": {"type": "STRING"},
        "timeline": {
            "type": "ARRAY",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "turn_index": {"type": "INTEGER"},
                    "score": {"type": "NUMBER"},
                    "label": {"type": "STRING", "enum": _LABELS},
                },
                "required": ["turn_index", "score", "label"],
            },
        },
    },
    "required": ["overall_score", "overall_label", "timeline"],
}


def _clamp(value, low=-1.0, high=1.0, default=0.0) -> float:
    try:
        return max(low, min(high, float(value)))
    except (TypeError, ValueError):
        return default


class SentimentAgent(Agent):
    name = "sentiment"
    step_order = 3
    prompt_version = "sentiment-v1"
    critical = False

    async def execute(self, ctx: PipelineContext) -> dict:
        customer_turns = [t for t in ctx.turns if t["speaker"] == "customer"]
        if not customer_turns:
            log.info("call %s has no customer turns — skipping sentiment", ctx.call_id)
            return {"skipped": "no customer turns"}

        rendered = "\n".join(f"[{t['turn_index']}] {t['text']}" for t in customer_turns)
        prompt = f"""Analyse the customer's emotional trajectory across this support call.

## Customer turns
Each line is prefixed with its turn number.

{rendered}

## What to produce
- A score for EVERY customer turn listed above, using its exact turn number
- opening_score: sentiment in the first customer turn
- closing_score: sentiment in the final customer turn
- overall_score and overall_label for the call as a whole
- trajectory: 'recovered' when the customer started clearly negative and ended \
positive; 'improving' for a gentler upward move; 'declining' for a downward one; \
'volatile' when it swings sharply in both directions; 'stable' otherwise
- dominant_emotions: a map of emotion name to intensity 0.0-1.0, \
e.g. {{"frustration": 0.7, "relief": 0.4}}
- analysis_notes: one or two sentences on what drove the change"""

        parsed, meta = await call_llm(
            prompt, SCHEMA,
            task="sentiment",
            context={"turns": ctx.turns},
            system=SYSTEM,
        )

        timeline = parsed.get("timeline") or []
        valid_indices = {t["turn_index"] for t in customer_turns}
        timeline = [p for p in timeline if p.get("turn_index") in valid_indices]

        scores = [_clamp(p.get("score")) for p in timeline]
        opening = _clamp(parsed.get("opening_score"), default=scores[0] if scores else 0.0)
        closing = _clamp(parsed.get("closing_score"), default=scores[-1] if scores else 0.0)
        overall = _clamp(parsed.get("overall_score"),
                         default=sum(scores) / len(scores) if scores else 0.0)

        # Derived here rather than asked of the model: these are arithmetic, and
        # arithmetic should not be delegated to a language model.
        delta = round(closing - opening, 3)
        lowest = min(scores) if scores else 0.0
        lowest_turn = timeline[scores.index(lowest)]["turn_index"] if scores else None
        volatility = (
            (sum((s - overall) ** 2 for s in scores) / len(scores)) ** 0.5 if scores else 0.0
        )

        turn_ids = {t["turn_index"]: t for t in ctx.turns}

        pool = db.get_pool()
        async with pool.acquire() as conn:
            async with conn.transaction():
                await conn.execute(
                    "delete from sentiment_timeline where evaluation_id = $1", ctx.evaluation_id
                )
                await conn.execute(
                    """
                    insert into sentiment_analyses (evaluation_id, call_id, overall_label,
                        overall_score, opening_score, closing_score, sentiment_delta,
                        lowest_score, lowest_turn_index, volatility, trajectory,
                        dominant_emotions, analysis_notes)
                    values ($1,$2,$3::sentiment_label,$4,$5,$6,$7,$8,$9,$10,$11,$12::jsonb,$13)
                    on conflict (evaluation_id) do update set
                        overall_label = excluded.overall_label,
                        overall_score = excluded.overall_score,
                        opening_score = excluded.opening_score,
                        closing_score = excluded.closing_score,
                        sentiment_delta = excluded.sentiment_delta,
                        lowest_score = excluded.lowest_score,
                        lowest_turn_index = excluded.lowest_turn_index,
                        volatility = excluded.volatility,
                        trajectory = excluded.trajectory,
                        dominant_emotions = excluded.dominant_emotions,
                        analysis_notes = excluded.analysis_notes
                    """,
                    ctx.evaluation_id, ctx.call_id,
                    parsed.get("overall_label") or "neutral", overall, opening, closing,
                    delta, lowest, lowest_turn, round(volatility, 4),
                    parsed.get("trajectory"),
                    parsed.get("dominant_emotions") or {},
                    parsed.get("analysis_notes"),
                )

                for point in timeline:
                    turn = turn_ids.get(point["turn_index"])
                    if not turn:
                        continue
                    await conn.execute(
                        """
                        insert into sentiment_timeline (evaluation_id, call_id, turn_id,
                            turn_index, speaker, score, label, emotions)
                        values ($1,$2,$3,$4,$5::speaker_role,$6,$7::sentiment_label,$8::jsonb)
                        on conflict (evaluation_id, turn_index) do nothing
                        """,
                        ctx.evaluation_id, ctx.call_id, turn["id"], point["turn_index"],
                        turn["speaker"], _clamp(point.get("score")),
                        point.get("label") or "neutral", point.get("emotions") or {},
                    )

        ctx.sentiment = {**parsed, "sentiment_delta": delta}
        return {
            "overall_score": overall, "sentiment_delta": delta,
            "trajectory": parsed.get("trajectory"), "points": len(timeline),
            "_llm_meta": meta,
        }
