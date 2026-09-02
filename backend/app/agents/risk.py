"""Risk and compliance agent.

Detects what a manager needs to see FIRST, independent of the score: missed
disclosures, unauthorised promises, churn signals, escalation risk, abusive
language, PII exposure.

Separate from scoring for two reasons:

1. Different consumer. Scores feed coaching over weeks; flags feed a triage
   queue today. A call can score 88% and still contain a legal threat.
2. Different failure mode. A missed flag is worse than a wrong score, so this
   agent is instructed to err toward flagging, and the triage columns
   (`is_acknowledged`, `is_false_positive`) let a human close the loop. That
   feedback is also the data you would use to tune the prompt later.
"""

import logging

from app import db
from app.agents.base import Agent, PipelineContext, call_llm

log = logging.getLogger(__name__)

FLAG_TYPES = [
    "escalation_risk", "churn_risk", "missed_disclosure", "policy_violation",
    "unauthorized_promise", "pii_exposure", "abusive_language", "legal_threat",
    "service_failure", "repeat_contact",
]

SYSTEM = """You are a compliance reviewer for a telecoms contact centre. You read \
call transcripts and flag risks a manager must act on.

Flag only what the transcript actually evidences — but when evidence is genuine, \
flag it even if you are not certain, and say so in your confidence score. A \
missed compliance breach is far more costly than a flag a manager dismisses in \
five seconds.

Return an empty list when the call is genuinely clean. Do not invent risks to \
appear thorough."""

SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "flags": {
            "type": "ARRAY",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "flag_type": {"type": "STRING", "enum": FLAG_TYPES},
                    "severity": {"type": "STRING",
                                 "enum": ["low", "medium", "high", "critical"]},
                    "title": {"type": "STRING"},
                    "description": {"type": "STRING"},
                    "confidence": {"type": "NUMBER"},
                    "turn_index": {"type": "INTEGER"},
                    "quoted_text": {"type": "STRING"},
                },
                "required": ["flag_type", "severity", "title", "description"],
            },
        }
    },
    "required": ["flags"],
}


class RiskAgent(Agent):
    name = "risk"
    step_order = 4
    prompt_version = "risk-v1"
    critical = False

    async def execute(self, ctx: PipelineContext) -> dict:
        prompt = f"""Review this customer support call for compliance and risk issues.

## Transcript
Each line is prefixed with its turn number. Cite these numbers.

{ctx.transcript_for_prompt()}

## What to look for
- missed_disclosure — the call-recording notice or identity verification was \
skipped, or came after account details were already discussed
- unauthorized_promise — a guaranteed refund, waiver, credit or fix deadline the \
agent cannot actually control
- policy_violation — dismissing a valid complaint, refusing a warranted \
escalation, a blind transfer
- churn_risk — the customer states or implies they intend to leave
- escalation_risk — repeat contact about the same unresolved issue, or rising anger
- pii_exposure — full card numbers read back, a password requested, data \
collected that is irrelevant to the issue
- abusive_language — from either party
- legal_threat — the customer mentions a regulator, ombudsman, lawyer or legal action
- service_failure — a systemic fault this call reveals

## Severity guide
- critical: regulatory breach, or the customer is leaving now
- high: a compliance step was missed, or an unauthorised commitment was made
- medium: process was not followed, the customer is clearly dissatisfied
- low: minor, worth noting only

For each flag give the turn number and the exact quote that evidences it. \
Return an empty list if the call is clean."""

        parsed, meta = await call_llm(
            prompt, SCHEMA,
            task="risk",
            context={"turns": ctx.turns},
            system=SYSTEM,
        )

        flags = parsed.get("flags") or []
        turn_ids = {t["turn_index"]: t for t in ctx.turns}

        pool = db.get_pool()
        async with pool.acquire() as conn:
            async with conn.transaction():
                # Re-running replaces this agent's flags, but only those a human
                # has NOT already triaged — discarding a reviewer's decision
                # would be worse than a duplicate.
                await conn.execute(
                    """
                    delete from risk_flags
                     where evaluation_id = $1 and not is_acknowledged
                    """,
                    ctx.evaluation_id,
                )

                stored = 0
                for flag in flags:
                    turn = turn_ids.get(flag.get("turn_index"))
                    await conn.execute(
                        """
                        insert into risk_flags (evaluation_id, call_id, flag_type, severity,
                            title, description, confidence, turn_id, turn_index,
                            quoted_text, char_start, char_end)
                        values ($1,$2,$3,$4::risk_severity,$5,$6,$7,$8,$9,$10,$11,$12)
                        """,
                        ctx.evaluation_id, ctx.call_id,
                        flag.get("flag_type", "policy_violation"),
                        flag.get("severity", "medium"),
                        (flag.get("title") or "Unspecified risk")[:300],
                        flag.get("description") or "",
                        flag.get("confidence"),
                        turn["id"] if turn else None,
                        flag.get("turn_index") if turn else None,
                        (flag.get("quoted_text") or (turn["text"] if turn else None)),
                        turn["char_start"] if turn else None,
                        turn["char_end"] if turn else None,
                    )
                    stored += 1

        ctx.risk_flags = flags
        by_severity: dict[str, int] = {}
        for flag in flags:
            key = flag.get("severity", "medium")
            by_severity[key] = by_severity.get(key, 0) + 1

        return {"flags_raised": stored, "by_severity": by_severity, "_llm_meta": meta}
