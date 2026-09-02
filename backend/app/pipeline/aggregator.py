"""Aggregation — the final pipeline step.

Contains almost no logic, and that is the point. All the weighting, N/A
renormalisation and auto-fail handling lives in the Postgres function
`recompute_evaluation_scores()` (migration 0009), which is:

  * the same code path used when an admin re-weights the rubric, so a freshly
    evaluated call and a re-weighted historical one can never disagree
  * pure SQL, so it costs nothing and runs in milliseconds
  * independently tested by supabase/tests/scoring_engine_test.sql

Reimplementing the rollup in Python would create a second source of truth that
would eventually drift from the first.
"""

import logging

from app import db
from app.agents.base import PipelineContext

log = logging.getLogger(__name__)


async def aggregate(ctx: PipelineContext) -> dict:
    result = await db.fetchrow(
        "select score_percentage, grade, missing_criteria from recompute_evaluation_scores($1)",
        ctx.evaluation_id,
    )

    # Store the rubric tree used, so this evaluation stays fully explainable even
    # if every framework row were later deleted.
    snapshot = {
        "framework_version_id": str(ctx.framework_version_id),
        "subsections": [
            {
                "code": ss["code"], "name": ss["name"], "weight": float(ss["weight"]),
                "section_code": ss["section_code"],
                "criteria": [
                    {
                        "code": c["code"], "name": c["name"], "weight": float(c["weight"]),
                        "scoring_type": c["scoring_type"], "max_score": float(c["max_score"]),
                        "is_critical": c["is_critical"], "guidance": c.get("guidance"),
                    }
                    for c in ss["criteria"]
                ],
            }
            for ss in ctx.subsections
        ],
    }

    await db.execute(
        """
        update evaluations
           set status = 'completed',
               framework_snapshot = $2::jsonb,
               model_used = $3,
               input_tokens = $4,
               output_tokens = $5,
               cost_usd = $6,
               error_message = $7,
               completed_at = now(),
               duration_ms = extract(milliseconds from (now() - started_at))::int
                             + extract(seconds from (now() - started_at))::int * 1000
         where id = $1
        """,
        ctx.evaluation_id,
        snapshot,
        ", ".join(sorted(ctx.models_used)) or None,
        ctx.total_input_tokens,
        ctx.total_output_tokens,
        round(ctx.total_cost_usd, 8),
        # Non-critical agent failures are recorded but do not fail the run. The
        # UI shows the evaluation as completed with a caveat, which is honest:
        # 31 scores and no summary is a degraded result, not a void one.
        ("; ".join(ctx.failures)[:2000] or None),
    )

    await db.execute(
        "update calls set status = 'evaluated', updated_at = now() where id = $1", ctx.call_id
    )

    log.info(
        "evaluation %s aggregated: %s%% (grade %s), %s criteria missing",
        ctx.evaluation_id, result["score_percentage"], result["grade"],
        result["missing_criteria"],
    )
    return dict(result)
