"""Criteria-scoring agent — the core of the evaluation.

BATCHING: ONE REQUEST PER SUB-SECTION
------------------------------------
The seeded rubric has 31 criteria across 12 sub-sections. Scoring each criterion
in its own request would mean 31 calls per evaluation — slow, expensive, and
worse quality, because the model would judge "acknowledges emotion" with no
sight of "uses empathy statements" even though the same passage informs both.

One request per sub-section gives 12 calls, keeps related criteria in a shared
judgement context, and still keeps each prompt small enough to reason carefully.
Sub-sections are the natural unit: they are what the rubric author grouped
together in the first place.

CITATIONS BY TURN INDEX, NEVER BY QUOTED TEXT
---------------------------------------------
The model is instructed to cite turn numbers. We resolve those to the character
offsets already stored on `transcript_turns`. Asking for quoted text instead
would require string-matching the model's output back into the transcript, and
models paraphrase, normalise whitespace and silently fix typos — so that match
fails constantly. Citing an index cannot drift.

THE FRAMEWORK IS THE PROMPT
---------------------------
Each criterion's `guidance` column is injected verbatim. That is the mechanism
behind "configurable without code changes": an admin rewriting guidance in the
UI changes how the next evaluation scores, with no deploy.
"""

import asyncio
import logging

from app import db
from app.agents.base import Agent, PipelineContext, call_llm

log = logging.getLogger(__name__)

SYSTEM = """You are an experienced contact-centre quality assessor. You evaluate \
customer support call transcripts against a defined rubric.

Rules you must follow:
- Judge ONLY what the transcript shows. Never assume behaviour that is not present.
- Cite evidence by TURN NUMBER, using the [n] markers in the transcript.
- If a criterion genuinely does not apply to this call, mark it not applicable \
rather than scoring it zero. Scoring an inapplicable criterion zero unfairly \
penalises the agent.
- Be consistent and calibrated. Reserve full marks for behaviour that clearly \
meets the guidance, and do not award partial credit for behaviour that is absent.
- State your confidence honestly. Low confidence on an ambiguous call is more \
useful than false certainty."""

# Gemini's structured-output dialect (uppercase type names).
SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "scores": {
            "type": "ARRAY",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "criterion_code": {"type": "STRING"},
                    "is_applicable": {"type": "BOOLEAN"},
                    "na_reason": {"type": "STRING"},
                    "score": {"type": "NUMBER"},
                    "confidence": {"type": "NUMBER"},
                    "reasoning": {"type": "STRING"},
                    "citations": {
                        "type": "ARRAY",
                        "items": {
                            "type": "OBJECT",
                            "properties": {
                                "turn_index": {"type": "INTEGER"},
                                "quote": {"type": "STRING"},
                                "polarity": {
                                    "type": "STRING",
                                    "enum": ["supporting", "detracting", "neutral"],
                                },
                            },
                            "required": ["turn_index", "polarity"],
                        },
                    },
                },
                "required": ["criterion_code", "is_applicable", "reasoning"],
            },
        }
    },
    "required": ["scores"],
}


def build_prompt(ctx: PipelineContext, subsection: dict) -> str:
    """Render the prompt for one sub-section."""
    stats = ctx.statistics or {}
    call = ctx.call or {}

    lines: list[str] = []
    for c in subsection["criteria"]:
        scale = (
            "Score 1 if met, 0 if not met."
            if c["scoring_type"] == "binary"
            else f"Score from {c['min_score']} to {c['max_score']}."
        )
        block = [
            f"### {c['code']} — {c['name']}",
            f"Weight within this sub-section: {c['weight']}%",
            f"Scoring: {scale}",
        ]
        if c.get("description"):
            block.append(f"What it measures: {c['description']}")
        if c.get("guidance"):
            # Verbatim. This is the configurability mechanism.
            block.append(f"Scoring guidance: {c['guidance']}")
        if c.get("is_critical"):
            block.append(
                "⚠ CRITICAL: failing this criterion zeroes the entire call score. "
                "Score it 0 only on clear evidence of absence."
            )
        if c.get("allow_na"):
            block.append(
                "This criterion MAY be marked not applicable if the situation it "
                "measures did not arise in this call."
            )
        else:
            block.append("This criterion always applies and must be scored.")
        if c.get("examples"):
            for ex in c["examples"][:3]:
                block.append(f"Example — score {ex.get('score')}: {ex.get('example')}")
        lines.append("\n".join(block))

    stats_block = ""
    if stats:
        ratio = stats.get("agent_talk_ratio")
        stats_block = (
            "\n## Measured conversation statistics\n"
            "These are computed facts, not judgements. Use them as evidence.\n"
            f"- Agent turns: {stats.get('agent_turn_count')}, "
            f"customer turns: {stats.get('customer_turn_count')}\n"
            f"- Agent share of words spoken: "
            f"{f'{ratio:.0%}' if ratio is not None else 'unknown'}\n"
            f"- Questions asked by the agent: {stats.get('question_count_agent')}\n"
            f"- Possible interruptions detected: {stats.get('interruption_count')}\n"
        )

    return f"""Evaluate this customer support call against the sub-section below.

## Call metadata
- Call reference: {call.get('call_code')}
- Duration: {call.get('duration_seconds')} seconds
- Handling team: {call.get('team_name') or 'unknown'}
{stats_block}
## Transcript
Each line is prefixed with its turn number in square brackets. \
Cite these numbers as evidence.

{ctx.transcript_for_prompt()}

## Rubric sub-section: {subsection['name']} ({subsection['code']})
{subsection.get('description') or ''}

Score EVERY criterion below. Return one entry per criterion, using the exact \
criterion_code given.

{chr(10).join(lines)}

## Output requirements
For each criterion return:
- criterion_code — exactly as written above
- is_applicable — false only where the criterion permits it and the situation did not arise
- na_reason — why, when is_applicable is false
- score — numeric, within the stated range (omit when not applicable)
- confidence — 0.0 to 1.0, your honest certainty
- reasoning — one or two sentences explaining the score
- citations — the turn numbers that justify it, with polarity 'supporting' for \
evidence of good practice and 'detracting' for evidence of a failure. Cite at \
least one turn for every criterion you score, including those you score zero."""


class ScoringAgent(Agent):
    name = "scoring"
    step_order = 2
    prompt_version = "scoring-v1"
    critical = True          # a call with no scores is not an evaluation

    # Sub-sections are scored concurrently, but bounded: firing 12 simultaneous
    # requests at a free-tier API is the fastest way to trigger the 503s the
    # retry ladder exists to survive.
    max_concurrency = 3

    async def execute(self, ctx: PipelineContext) -> dict:
        semaphore = asyncio.Semaphore(self.max_concurrency)
        aggregate = {"input_tokens": 0, "output_tokens": 0, "cost_usd": 0.0,
                     "attempts": 0, "model": None, "prompt": None, "raw_text": None}

        async def score_one(subsection: dict) -> list[dict]:
            async with semaphore:
                prompt = build_prompt(ctx, subsection)
                parsed, meta = await call_llm(
                    prompt, SCHEMA,
                    task="scoring",
                    context={"criteria": subsection["criteria"], "turns": ctx.turns},
                    system=SYSTEM,
                )
                aggregate["input_tokens"] += meta["input_tokens"]
                aggregate["output_tokens"] += meta["output_tokens"]
                aggregate["cost_usd"] += meta["cost_usd"]
                aggregate["attempts"] += meta["attempts"]
                aggregate["model"] = meta["model"]
                # Keep one representative prompt for the agent_runs trace rather
                # than twelve, which would bloat every row.
                aggregate["prompt"] = aggregate["prompt"] or prompt
                aggregate["raw_text"] = aggregate["raw_text"] or meta["raw_text"]

                valid_codes = {c["code"] for c in subsection["criteria"]}
                out = []
                for item in (parsed or {}).get("scores", []):
                    # A hallucinated criterion_code would silently create a score
                    # for a criterion that does not exist in this rubric version.
                    if item.get("criterion_code") not in valid_codes:
                        log.warning(
                            "scoring returned unknown criterion_code %r for %s — discarded",
                            item.get("criterion_code"), subsection["code"],
                        )
                        continue
                    item["_subsection_code"] = subsection["code"]
                    item["_section_code"] = subsection["section_code"]
                    out.append(item)
                return out

        results = await asyncio.gather(
            *(score_one(ss) for ss in ctx.subsections), return_exceptions=True
        )

        scores: list[dict] = []
        failed_subsections: list[str] = []
        for subsection, result in zip(ctx.subsections, results):
            if isinstance(result, Exception):
                # One sub-section failing must not discard the other eleven. The
                # aggregator renormalises over whatever was scored, and the
                # missing leaves show as unscored in the UI.
                log.error("sub-section %s failed to score: %s", subsection["code"], result)
                failed_subsections.append(subsection["code"])
                ctx.failures.append(f"scoring[{subsection['code']}]: {result}")
                continue
            scores.extend(result)

        if not scores:
            raise RuntimeError(
                f"Scoring produced no results across {len(ctx.subsections)} sub-sections."
            )

        await self._persist(ctx, scores)
        ctx.scores = scores

        return {
            "scored_criteria": len(scores),
            "failed_subsections": failed_subsections,
            "_llm_meta": aggregate,
        }

    async def _persist(self, ctx: PipelineContext, scores: list[dict]) -> None:
        """Write criterion scores and resolve citations to character offsets."""
        by_code = {
            c["code"]: (c, ss)
            for ss in ctx.subsections
            for c in ss["criteria"]
        }
        turn_ids = {t["turn_index"]: t for t in ctx.turns}

        pool = db.get_pool()
        async with pool.acquire() as conn:
            async with conn.transaction():
                # Idempotent: re-running the agent replaces its previous output
                # rather than accumulating duplicates.
                await conn.execute(
                    "delete from criterion_scores where evaluation_id = $1", ctx.evaluation_id
                )

                for item in scores:
                    code = item["criterion_code"]
                    criterion, subsection = by_code[code]

                    applicable = bool(item.get("is_applicable", True))
                    raw_score = item.get("score")
                    max_score = float(criterion["max_score"])
                    min_score = float(criterion["min_score"])

                    if applicable and raw_score is not None:
                        # Clamp: a model asked for 0-5 will occasionally return 6.
                        raw_score = max(min_score, min(max_score, float(raw_score)))
                        normalized = (
                            (raw_score - min_score) / (max_score - min_score)
                            if max_score > min_score else 0.0
                        )
                    else:
                        raw_score, normalized, applicable = None, None, False

                    score_id = await conn.fetchval(
                        """
                        insert into criterion_scores (evaluation_id, criterion_id,
                            criterion_code, criterion_name, subsection_code, section_code,
                            scoring_type, weight_snapshot, is_critical_snapshot,
                            raw_score, max_score, normalized, confidence, reasoning,
                            is_applicable, na_reason)
                        values ($1,$2,$3,$4,$5,$6,$7::scoring_type,$8,$9,$10,$11,$12,$13,$14,$15,$16)
                        returning id
                        """,
                        ctx.evaluation_id, criterion["id"], code, criterion["name"],
                        subsection["code"], subsection["section_code"],
                        criterion["scoring_type"], criterion["weight"],
                        criterion["is_critical"], raw_score, max_score, normalized,
                        item.get("confidence"), (item.get("reasoning") or "")[:4000],
                        applicable, (item.get("na_reason") or None),
                    )

                    for citation in (item.get("citations") or [])[:5]:
                        turn = turn_ids.get(citation.get("turn_index"))
                        if not turn:
                            # A cited turn that does not exist is a hallucination.
                            # Dropping it is correct: a citation pointing nowhere
                            # is worse than no citation.
                            log.warning(
                                "citation referenced missing turn %s on %s — dropped",
                                citation.get("turn_index"), code,
                            )
                            continue
                        await conn.execute(
                            """
                            insert into score_citations (criterion_score_id, transcript_turn_id,
                                turn_index, quoted_text, char_start, char_end, polarity, relevance)
                            values ($1, $2, $3, $4, $5, $6, $7, $8)
                            """,
                            score_id, turn["id"], turn["turn_index"],
                            # Store the model's quote when given, but the OFFSETS
                            # always come from the turn — so highlighting is exact
                            # even when the model paraphrased.
                            (citation.get("quote") or turn["text"])[:2000],
                            turn["char_start"], turn["char_end"],
                            citation.get("polarity", "supporting"),
                            citation.get("relevance"),
                        )
