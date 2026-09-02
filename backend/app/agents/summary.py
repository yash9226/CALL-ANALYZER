"""Summary agent — the manager-readable account of the call.

Deliberately produces STRUCTURED output, not just prose. `topics` becomes a
GIN-indexed text[] and `resolution_status` a constrained value, so "show me
unresolved billing calls" resolves as a fast structured query instead of a
semantic search. Prose alone would force every such question through the RAG
path, which is both slower and less reliable for questions that are really
filters.
"""

import logging

from app import db
from app.agents.base import Agent, PipelineContext, call_llm

log = logging.getLogger(__name__)

SYSTEM = """You summarise customer support calls for a team manager who has not \
listened to them. Be factual and concise. Never invent detail that is not in the \
transcript. Write plainly: no marketing tone, no filler."""

SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "headline": {"type": "STRING"},
        "summary": {"type": "STRING"},
        "customer_intent": {"type": "STRING"},
        "resolution_status": {
            "type": "STRING",
            "enum": ["resolved", "partially_resolved", "unresolved",
                     "escalated", "follow_up_scheduled"],
        },
        "outcome": {"type": "STRING"},
        "key_issues": {"type": "ARRAY", "items": {"type": "STRING"}},
        "topics": {"type": "ARRAY", "items": {"type": "STRING"}},
        "next_actions": {
            "type": "ARRAY",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "action": {"type": "STRING"},
                    "owner": {"type": "STRING"},
                    "due": {"type": "STRING"},
                },
                "required": ["action"],
            },
        },
    },
    "required": ["headline", "summary", "resolution_status", "topics"],
}


class SummaryAgent(Agent):
    name = "summary"
    step_order = 5
    prompt_version = "summary-v1"
    critical = False        # a missing summary degrades the result, it does not void it

    async def execute(self, ctx: PipelineContext) -> dict:
        call = ctx.call or {}
        prompt = f"""Summarise this customer support call for a manager reviewing it later.

## Call metadata
- Reference: {call.get('call_code')}
- Agent: {call.get('agent_name') or 'unknown'}
- Team: {call.get('team_name') or 'unknown'}
- Duration: {call.get('duration_seconds')} seconds

## Transcript
{ctx.transcript_for_prompt()}

## What to produce
- headline: one line, under 90 characters, naming the actual problem
- summary: three to five sentences covering what the customer wanted, what the \
agent did, and how it ended
- customer_intent: a short snake_case label, e.g. billing_dispute, service_outage
- resolution_status: one of the allowed values
- outcome: one sentence on where things stand now
- key_issues: the distinct problems raised, as short phrases
- topics: two to four lowercase snake_case tags for filtering, e.g. billing, \
refund, outage, plan_change
- next_actions: any follow-up the call committed to, with an owner and a \
timeframe where stated. Return an empty list if nothing was committed."""

        parsed, meta = await call_llm(
            prompt, SCHEMA,
            task="summary",
            context={"turns": ctx.turns, "call": call},
            system=SYSTEM, temperature=0.2,
        )

        topics = [str(t).lower().strip().replace(" ", "_") for t in (parsed.get("topics") or [])]

        await db.execute(
            """
            insert into call_summaries (evaluation_id, call_id, headline, summary,
                customer_intent, resolution_status, outcome, key_issues, topics, next_actions)
            values ($1,$2,$3,$4,$5,$6,$7,$8::jsonb,$9,$10::jsonb)
            on conflict (evaluation_id) do update set
                headline = excluded.headline, summary = excluded.summary,
                customer_intent = excluded.customer_intent,
                resolution_status = excluded.resolution_status,
                outcome = excluded.outcome, key_issues = excluded.key_issues,
                topics = excluded.topics, next_actions = excluded.next_actions
            """,
            ctx.evaluation_id, ctx.call_id,
            (parsed.get("headline") or "")[:300],
            parsed.get("summary") or "",
            parsed.get("customer_intent"),
            parsed.get("resolution_status"),
            parsed.get("outcome"),
            parsed.get("key_issues") or [],
            topics,
            parsed.get("next_actions") or [],
        )

        ctx.summary = parsed
        return {**parsed, "_llm_meta": meta}
