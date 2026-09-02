"""Deterministic offline provider.

THIS IS NOT A LOCAL LANGUAGE MODEL. There are no weights, no downloads, and
nothing runs on the machine's CPU or GPU. It is a keyword rule engine in plain
Python that returns schema-conformant fixtures. All real inference happens in
Google's API via GeminiProvider.

WHY IT EXISTS
-------------
1. A live demo cannot depend on a free-tier API being healthy. Google's Gemini
   endpoint returned HTTP 503 "experiencing high demand" repeatedly while this
   project was being built. MOCK_LLM=true makes the whole pipeline run with no
   network at all.
2. Integration tests need the pipeline to be fast, free and deterministic.
3. It doubles as a RULE-BASED BASELINE. Because it scores the same transcripts
   against the same rubric, the report can compare "keyword rules" against "LLM"
   on the seed data's ground-truth labels — which is a far stronger evaluation
   than reporting the LLM's numbers alone.

The rules deliberately produce plausible, varied output rather than random
numbers: a demo full of noise looks broken, and citations must point at real
turns for the highlighting UI to be meaningful.
"""

import hashlib
import json
from dataclasses import dataclass, field
from typing import Any

from app.llm.base import LLMResult


@dataclass(frozen=True)
class Rule:
    """Keyword heuristic for one criterion.

    `positive` phrases earn credit, `negative` phrases remove it. `na_unless`
    marks the criterion not-applicable when none of those phrases appear at all
    — which is how HOLD_ETIQUETTE correctly returns N/A on a call with no hold,
    exercising the same renormalisation path the real agent will.
    """

    positive: tuple[str, ...] = ()
    negative: tuple[str, ...] = ()
    na_unless: tuple[str, ...] = ()
    scope: str = "agent"          # agent | all | opening | closing
    needed_for_full: int = 2      # positive matches required to score 1.0


# ── Rule table, keyed by criterion code ─────────────────────────────────────
RULES: dict[str, Rule] = {
    # OPENING
    "GREETING_BRANDED": Rule(
        positive=("thank you for calling", "my name is", "this is", "northwind", "speaking"),
        scope="opening", needed_for_full=3),
    "PURPOSE_CAPTURE": Rule(
        positive=("how can i help", "what can i do", "how may i help", "what can i help"),
        scope="opening", needed_for_full=1),
    "TONE_OPENING": Rule(
        positive=("thank you", "happy to", "of course", "certainly", "good morning",
                  "good afternoon"),
        negative=("what's the account number", "support desk"),
        scope="opening", needed_for_full=2),
    "EXPECTATION_SETTING": Rule(
        positive=("let me", "i'm going to", "this will take", "i will", "give me a moment",
                  "about ninety seconds", "one moment"),
        scope="agent", needed_for_full=2),
    "HOLD_ETIQUETTE": Rule(
        positive=("alright if i put you on", "thank you for holding", "appreciate your patience",
                  "short hold"),
        na_unless=("hold", "holding", "one moment"),
        scope="agent", needed_for_full=2),

    # COMMUNICATION
    "PLAIN_LANGUAGE": Rule(
        positive=("in other words", "what that means", "so basically", "put simply",
                  "let me explain"),
        negative=("pppoe", "olt", "cpe", "proration"),
        scope="agent", needed_for_full=1),
    "JARGON_AVOIDANCE": Rule(
        positive=("which means", "that is", "in other words"),
        negative=("pppoe", "olt", "cpe", "ont ", "distribution point", "proration",
                  "sync", "megabit"),
        scope="agent", needed_for_full=1),
    "PACE_AND_CLARITY": Rule(
        positive=("first", "then", "next", "finally", "two steps", "let me separate"),
        scope="agent", needed_for_full=2),
    "NO_INTERRUPTION": Rule(
        negative=("as i was saying", "if you'd let me finish", "let me finish"),
        scope="agent", needed_for_full=1),
    "PARAPHRASE_CONFIRM": Rule(
        positive=("so what you're saying", "just to confirm", "let me make sure",
                  "if i understand", "that explains it", "so this is"),
        scope="agent", needed_for_full=1),
    "PROBING_QUESTIONS": Rule(
        positive=("can you tell me", "could you confirm", "what colour", "when did",
                  "have you", "which one", "can you see"),
        scope="agent", needed_for_full=2),
    "ACKNOWLEDGE_EMOTION": Rule(
        positive=("i can hear how", "i understand how", "completely understand",
                  "i'd feel the same", "frustrating", "not acceptable", "i'm sorry you"),
        scope="agent", needed_for_full=2),
    "EMPATHY_STATEMENT": Rule(
        positive=("understand", "i'm sorry", "i apologise", "that's a fair",
                  "not going to argue", "i appreciate", "i'd feel the same"),
        scope="agent", needed_for_full=2),
    "POSITIVE_TONE": Rule(
        positive=("happy to", "absolutely", "of course", "wonderful", "not a problem",
                  "take your time"),
        negative=("that's the policy", "nothing i can do", "it's in the terms",
                  "you'd have to check", "prices go up"),
        scope="agent", needed_for_full=2),

    # RESOLUTION
    "ROOT_CAUSE_ID": Rule(
        positive=("that explains", "the cause", "what happened is", "which is why",
                  "so this is a", "it looks like", "i can see both", "that's the whole problem"),
        scope="agent", needed_for_full=2),
    "ACCOUNT_REVIEW": Rule(
        positive=("i can see", "your account", "your plan", "your line", "last payment",
                  "your invoice", "on the 3rd", "averaging about"),
        scope="agent", needed_for_full=2),
    "SOLUTION_ACCURACY": Rule(
        positive=("i'm raising", "i've applied", "i'm re-issuing", "i've pushed",
                  "i've logged", "i can offer", "applied from"),
        negative=("probably", "i'm not sure", "you'd have to check", "when it's fixed"),
        scope="agent", needed_for_full=2),
    "STEP_GUIDANCE": Rule(
        positive=("first", "second", "then", "move it to", "connect to", "can you see",
                  "run a speed test", "two steps"),
        scope="agent", needed_for_full=3),
    "FIRST_CONTACT_RESOLUTION": Rule(
        negative=("call us back", "engineer visit", "someone will get back",
                  "i'll escalate", "book an engineer", "another week"),
        scope="agent", needed_for_full=1),
    "CONFIRM_RESOLUTION": Rule(
        positive=("is the issue fully resolved", "does that work", "is that sorted",
                  "just to confirm before we finish", "tell me if it works"),
        scope="agent", needed_for_full=1),
    "OFFER_ADDITIONAL_HELP": Rule(
        positive=("anything else", "is there anything"),
        scope="agent", needed_for_full=1),

    # COMPLIANCE
    "RECORDING_DISCLOSURE": Rule(
        positive=("call is recorded", "this call is recorded", "recorded for quality",
                  "the call is recorded", "monitored"),
        scope="opening", needed_for_full=1),
    "IDENTITY_VERIFICATION": Rule(
        positive=("confirm the registered", "last four digits", "account number",
                  "billing postcode", "you're fully verified", "second check"),
        scope="agent", needed_for_full=2),
    "DATA_PRIVACY_ADHERENCE": Rule(
        negative=("your password", "full card number", "cvv", "read me your card"),
        scope="agent", needed_for_full=1),
    "NO_UNAUTHORIZED_PROMISE": Rule(
        negative=("i guarantee", "i promise it will", "definitely get that refunded",
                  "guarantee it'll be"),
        scope="agent", needed_for_full=1),
    "CORRECT_ESCALATION": Rule(
        positive=("escalates automatically", "straight to the field team", "priority",
                  "reference nw-"),
        na_unless=("escalate", "transfer", "field team", "engineering", "billing team"),
        scope="agent", needed_for_full=1),
    "ACCURATE_PRICING_INFO": Rule(
        positive=("plus 18 percent gst", "plus gst", "total per month", "fixed for twelve months",
                  "per month", "rupees"),
        na_unless=("1,299", "1,099", "949", "rupees", "gst", "plan at", "charge"),
        scope="agent", needed_for_full=2),

    # CLOSING
    "SUMMARIZE_ACTIONS": Rule(
        positive=("to summarise", "so i've", "i've raised", "that's been raised",
                  "here's what", "i've also"),
        scope="closing", needed_for_full=2),
    "NEXT_STEPS_CLEAR": Rule(
        positive=("within two hours", "within three working days", "within twenty-four",
                  "you'll get", "you'll receive", "starting from", "by 6pm"),
        negative=("someone will update you", "give it another week"),
        scope="closing", needed_for_full=1),
    "THANK_CUSTOMER": Rule(
        positive=("thank you so much", "thank you for your patience", "thanks for calling",
                  "thank you for choosing", "i appreciate"),
        scope="closing", needed_for_full=1),
    "BRANDED_CLOSE": Rule(
        positive=("northwind", "have a good", "thank you for choosing"),
        scope="closing", needed_for_full=2),
}

_DEFAULT_RULE = Rule(positive=("thank you", "i can", "let me"), needed_for_full=2)


def _scoped_turns(turns: list[dict], scope: str) -> list[dict]:
    """Restrict evaluation to the part of the call a criterion is about.

    Judging the greeting against the whole transcript would let a 'thank you'
    in the closing rescue a criterion about the first ten seconds.
    """
    agent = [t for t in turns if t.get("speaker") == "agent"]
    if scope == "opening":
        return agent[:3]
    if scope == "closing":
        return agent[-3:]
    if scope == "all":
        return turns
    return agent


def evaluate_rule(code: str, turns: list[dict]) -> dict:
    """Score one criterion. Returns score fraction, applicability and evidence."""
    rule = RULES.get(code, _DEFAULT_RULE)
    scoped = _scoped_turns(turns, rule.scope)
    haystack = " ".join(t.get("text", "").lower() for t in scoped)
    whole_call = " ".join(t.get("text", "").lower() for t in turns)

    if rule.na_unless and not any(p in whole_call for p in rule.na_unless):
        return {
            "fraction": None, "applicable": False,
            "reason": "This criterion does not apply — the situation it measures did not arise.",
            "citations": [],
        }

    hits = [p for p in rule.positive if p in haystack]
    misses = [n for n in rule.negative if n in haystack]

    if rule.positive:
        fraction = min(1.0, len(hits) / rule.needed_for_full)
    else:
        # Negative-only rules (NO_INTERRUPTION, NO_UNAUTHORIZED_PROMISE) start
        # from full marks and lose them on a violation.
        fraction = 1.0
    fraction = max(0.0, fraction - 0.5 * len(misses))

    citations = []
    for turn in scoped:
        lowered = turn.get("text", "").lower()
        for phrase in hits[:2]:
            if phrase in lowered:
                citations.append({
                    "turn_index": turn["turn_index"],
                    "quote": turn["text"][:220],
                    "polarity": "supporting",
                })
                break
        if len(citations) >= 2:
            break
    for turn in scoped:
        lowered = turn.get("text", "").lower()
        if any(n in lowered for n in misses):
            citations.append({
                "turn_index": turn["turn_index"],
                "quote": turn["text"][:220],
                "polarity": "detracting",
            })
            break

    # Always cite something. An uncited score is exactly what this project
    # exists to avoid, and a scored-zero criterion still has evidence: the turn
    # where the expected behaviour should have appeared.
    if not citations and scoped:
        citations.append({
            "turn_index": scoped[0]["turn_index"],
            "quote": scoped[0]["text"][:220],
            "polarity": "detracting" if fraction < 0.5 else "neutral",
        })

    if not rule.positive:
        # Negative-only rules (NO_INTERRUPTION, NO_UNAUTHORIZED_PROMISE) are
        # scored by absence, so "matched expected behaviour" would read as
        # nonsense with nothing in the parentheses.
        reason = (
            "No violations detected."
            if fraction >= 0.9
            else f"Violation detected: {', '.join(misses[:2])}."
        )
    elif fraction >= 0.9:
        reason = f"Clearly met. Matched expected behaviour ({', '.join(hits[:3])})."
    elif fraction >= 0.5:
        reason = f"Partially met. Some expected behaviour present ({', '.join(hits[:2]) or 'limited evidence'})."
    else:
        reason = (
            f"Not met. Expected behaviour was absent"
            + (f", and detracting language was present ({', '.join(misses[:2])})." if misses else ".")
        )

    return {"fraction": fraction, "applicable": True, "reason": reason, "citations": citations}


# ── Sentiment, risk and summary heuristics ──────────────────────────────────

_NEGATIVE_WORDS = ("frustrated", "angry", "ridiculous", "not happy", "unacceptable",
                   "terrible", "awful", "cancel", "complain", "dreading", "serious problem",
                   "not good enough", "third time", "still hasn't")
_POSITIVE_WORDS = ("thank you", "thanks", "appreciate", "helpful", "wonderful", "perfect",
                   "that's sorted", "huge difference", "more reasonable", "sensible")


def _sentiment_of(text: str) -> float:
    lowered = text.lower()
    neg = sum(1 for w in _NEGATIVE_WORDS if w in lowered)
    pos = sum(1 for w in _POSITIVE_WORDS if w in lowered)
    if neg == pos == 0:
        return 0.0
    return max(-1.0, min(1.0, (pos - neg) / max(1, pos + neg) * 0.8))


def _label_for(score: float) -> str:
    if score <= -0.6:
        return "very_negative"
    if score <= -0.15:
        return "negative"
    if score < 0.15:
        return "neutral"
    if score < 0.6:
        return "positive"
    return "very_positive"


_RISK_PATTERNS = [
    ("missed_disclosure", "high", "Call recording not disclosed",
     lambda c, a: not any(p in a for p in ("recorded", "monitored")),
     "No call-recording disclosure was found in the agent's turns."),
    ("missed_disclosure", "critical", "Customer identity not verified",
     lambda c, a: not any(p in a for p in ("account number", "confirm the registered",
                                           "last four", "postcode", "verified")),
     "Account details appear to have been discussed without identity verification."),
    ("unauthorized_promise", "high", "Unauthorised guarantee given",
     lambda c, a: any(p in a for p in ("i guarantee", "i promise it will",
                                       "definitely get that refunded")),
     "The agent guaranteed an outcome outside their authority."),
    ("churn_risk", "high", "Explicit cancellation intent",
     lambda c, a: any(p in c for p in ("want to cancel", "moving to a competitor",
                                       "just cancel it")),
     "The customer stated an intention to leave."),
    ("escalation_risk", "medium", "Repeat contact about an unresolved issue",
     lambda c, a: any(p in c for p in ("third time", "still hasn't", "last person said",
                                       "three weeks ago")),
     "The customer referenced previous unsuccessful contacts."),
    ("policy_violation", "medium", "Dismissive handling of a valid complaint",
     lambda c, a: any(p in a for p in ("nothing i can do", "that's the policy",
                                       "it's in the terms", "when it's fixed")),
     "The agent deflected responsibility rather than resolving or escalating."),
]


class MockProvider:
    """Rule-based provider. Same interface as GeminiProvider, zero network."""

    name = "mock"

    def __init__(self, *args, **kwargs):
        self.calls: list[dict] = []      # inspected by tests

    async def close(self) -> None:
        return None

    async def generate_json(
        self,
        prompt: str,
        schema: dict,
        *,
        system: str | None = None,
        model: str | None = None,
        temperature: float = 0.1,
        max_output_tokens: int = 8192,
        task: str | None = None,
        context: dict | None = None,
    ) -> LLMResult:
        context = context or {}
        self.calls.append({"task": task, "prompt_chars": len(prompt)})

        handler = {
            "scoring": self._score,
            "summary": self._summary,
            "sentiment": self._sentiment,
            "risk": self._risk,
        }.get(task or "", self._generic)

        parsed = handler(context, schema)
        text = json.dumps(parsed)

        # Token counts approximate 4 chars/token, so cost and usage charts have
        # sensible shapes in mock mode rather than sitting flat at zero.
        return LLMResult(
            text=text,
            parsed=parsed,
            model="mock",
            input_tokens=len(prompt) // 4,
            output_tokens=len(text) // 4,
            latency_ms=12,
            attempts=1,
        )

    # ── Task handlers ───────────────────────────────────────────────────────

    def _score(self, context: dict, _schema: dict) -> dict:
        turns = context.get("turns", [])
        results = []
        for criterion in context.get("criteria", []):
            outcome = evaluate_rule(criterion["code"], turns)
            max_score = float(criterion.get("max_score", 5))

            if not outcome["applicable"]:
                results.append({
                    "criterion_code": criterion["code"],
                    "is_applicable": False,
                    "na_reason": outcome["reason"],
                    "score": None, "confidence": 0.9,
                    "reasoning": outcome["reason"], "citations": [],
                })
                continue

            raw = round(outcome["fraction"] * max_score, 2)
            if criterion.get("scoring_type") == "binary":
                raw = 1.0 if outcome["fraction"] >= 0.5 else 0.0

            results.append({
                "criterion_code": criterion["code"],
                "is_applicable": True,
                "score": raw,
                # Deliberately below 1.0: these are heuristics, and overstating
                # confidence would make the confidence column meaningless.
                "confidence": 0.72,
                "reasoning": outcome["reason"],
                "citations": outcome["citations"],
            })
        return {"scores": results}

    def _summary(self, context: dict, _schema: dict) -> dict:
        turns = context.get("turns", [])
        meta = context.get("call", {})
        customer = " ".join(t["text"] for t in turns if t.get("speaker") == "customer")
        agent = " ".join(t["text"] for t in turns if t.get("speaker") == "agent")
        lowered = customer.lower()

        topic_map = [
            (("charged twice", "duplicate", "double"), "billing", "billing_dispute",
             "Duplicate charge on the customer's account"),
            (("bill went up", "bill is wrong", "400 rupees"), "billing", "billing_dispute",
             "Unexpected increase in the monthly bill"),
            (("refund",), "billing", "refund_status", "Outstanding refund not received"),
            (("internet has been completely down", "connection keeps dropping", "down since"),
             "technical", "service_outage", "Loss of service"),
            (("megabits", "speed", "slow"), "technical", "performance_complaint",
             "Broadband speed below the subscribed rate"),
            (("router", "can't get it working"), "technical", "setup_assistance",
             "New router installation assistance"),
            (("cancel", "competitor"), "retention", "cancellation_request",
             "Customer requested cancellation"),
            (("contract is up", "renew"), "retention", "contract_renewal",
             "Contract renewal options discussed"),
        ]
        topics, intent, headline = ["general"], "general_enquiry", "Customer support call"
        for needles, topic, detected_intent, detected_headline in topic_map:
            if any(n in lowered for n in needles):
                topics, intent, headline = [topic], detected_intent, detected_headline
                break

        agent_lower = agent.lower()
        if any(p in agent_lower for p in ("i'm raising", "i've applied", "i've re-issued",
                                          "applied from", "that's it, that's the whole problem")):
            resolution = "resolved"
        elif any(p in agent_lower for p in ("i'll escalate", "engineering will look",
                                            "someone will update")):
            resolution = "escalated"
        elif any(p in agent_lower for p in ("repair crew", "by 6pm", "you'll get a text")):
            resolution = "follow_up_scheduled"
        else:
            resolution = "partially_resolved"

        return {
            "headline": headline,
            "summary": (
                f"The customer contacted support regarding {headline.lower()}. "
                f"The agent handled the enquiry across {len(turns)} conversational turns "
                f"and the call concluded as '{resolution.replace('_', ' ')}'."
            ),
            "customer_intent": intent,
            "resolution_status": resolution,
            "outcome": f"Call ended {resolution.replace('_', ' ')}.",
            "key_issues": [headline],
            "topics": topics,
            "next_actions": (
                [{"action": "Verify the committed action completed", "owner": "supervisor",
                  "due": "48h"}]
                if resolution != "resolved" else []
            ),
        }

    def _sentiment(self, context: dict, _schema: dict) -> dict:
        turns = [t for t in context.get("turns", []) if t.get("speaker") == "customer"]
        timeline = [
            {
                "turn_index": t["turn_index"],
                "score": round(_sentiment_of(t["text"]), 3),
                "label": _label_for(_sentiment_of(t["text"])),
                "emotions": {},
            }
            for t in turns
        ]
        scores = [p["score"] for p in timeline] or [0.0]
        opening, closing = scores[0], scores[-1]
        overall = round(sum(scores) / len(scores), 3)
        delta = round(closing - opening, 3)

        if delta > 0.25:
            trajectory = "recovered" if opening < -0.2 else "improving"
        elif delta < -0.25:
            trajectory = "declining"
        elif max(scores) - min(scores) > 0.7:
            trajectory = "volatile"
        else:
            trajectory = "stable"

        spread = (sum((s - overall) ** 2 for s in scores) / len(scores)) ** 0.5
        lowest = min(scores)

        return {
            "overall_score": overall,
            "overall_label": _label_for(overall),
            "opening_score": round(opening, 3),
            "closing_score": round(closing, 3),
            "sentiment_delta": delta,
            "lowest_score": round(lowest, 3),
            "lowest_turn_index": timeline[scores.index(lowest)]["turn_index"] if timeline else None,
            "volatility": round(spread, 4),
            "trajectory": trajectory,
            "dominant_emotions": {"frustration": 0.6} if overall < -0.2 else {"neutral": 0.5},
            "analysis_notes": f"Customer sentiment moved from {opening:+.2f} to {closing:+.2f}.",
            "timeline": timeline,
        }

    def _risk(self, context: dict, _schema: dict) -> dict:
        turns = context.get("turns", [])
        customer = " ".join(t["text"].lower() for t in turns if t.get("speaker") == "customer")
        agent = " ".join(t["text"].lower() for t in turns if t.get("speaker") == "agent")

        flags = []
        for flag_type, severity, title, predicate, description in _RISK_PATTERNS:
            if predicate(customer, agent):
                turn_index = next(
                    (t["turn_index"] for t in turns
                     if any(w in t["text"].lower() for w in title.lower().split()[:2])),
                    turns[0]["turn_index"] if turns else 0,
                )
                quote = next(
                    (t["text"][:220] for t in turns if t["turn_index"] == turn_index), ""
                )
                flags.append({
                    "flag_type": flag_type, "severity": severity, "title": title,
                    "description": description, "confidence": 0.7,
                    "turn_index": turn_index, "quoted_text": quote,
                })
        return {"flags": flags}

    def _generic(self, context: dict, schema: dict) -> Any:
        """Schema-shaped filler for any task without a dedicated handler."""
        seed = int(hashlib.sha256(json.dumps(context, default=str).encode()).hexdigest()[:8], 16)

        def build(node: dict) -> Any:
            kind = str(node.get("type", "STRING")).upper()
            if kind == "OBJECT":
                return {k: build(v) for k, v in (node.get("properties") or {}).items()}
            if kind == "ARRAY":
                return [build(node.get("items", {"type": "STRING"}))]
            if kind in ("NUMBER", "INTEGER"):
                return seed % 5
            if kind == "BOOLEAN":
                return bool(seed % 2)
            return "mock"

        return build(schema)

    async def embed(self, texts: list[str], *, dimensions: int = 768) -> list[list[float]]:
        """Deterministic pseudo-embeddings.

        Derived from a hash of the text, so identical text always yields an
        identical vector and cosine similarity is stable across runs. They carry
        no semantic meaning — retrieval quality can only be judged with real
        embeddings.
        """
        vectors = []
        for text in texts:
            digest = hashlib.sha256(text.encode()).digest()
            raw = [(digest[i % len(digest)] - 128) / 128.0 for i in range(dimensions)]
            norm = sum(v * v for v in raw) ** 0.5 or 1.0
            vectors.append([v / norm for v in raw])
        return vectors
