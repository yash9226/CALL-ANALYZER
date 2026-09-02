# Architecture

Growing document. Phase 8 turns this into the report write-up; it is written as
we build so nothing has to be reconstructed from memory later.

---

## 1. System overview

```
                    ┌──────────────────────────────────────┐
                    │            React frontend            │
                    │  Dashboard · Drill-down · Admin      │
                    │  panel · Chat widget                 │
                    └───────────────┬──────────────────────┘
                                    │  REST (typed contract)
                    ┌───────────────▼──────────────────────┐
                    │          FastAPI backend             │
                    │  framework CRUD · ingestion ·         │
                    │  evaluation trigger · chat            │
                    └───┬───────────────┬──────────────┬───┘
                        │               │              │
         ┌──────────────▼───┐  ┌────────▼────────┐  ┌──▼──────────────┐
         │  Job queue       │  │ LangGraph       │  │ Hybrid retrieval│
         │  (Postgres,      │  │ agent pipeline  │  │ vector + FTS    │
         │  SKIP LOCKED)    │  │                 │  │ + SQL           │
         └──────────┬───────┘  └────────┬────────┘  └──┬──────────────┘
                    │                   │              │
                    └───────────────────┼──────────────┘
                                        │
                    ┌───────────────────▼──────────────────┐
                    │      Supabase / Postgres 17          │
                    │  rubric tree · calls · transcripts   │
                    │  scores · citations · pgvector · RLS │
                    └──────────────────────────────────────┘
                                        │
                    ┌───────────────────▼──────────────────┐
                    │        Gemini API (no local models)  │
                    │  scoring · summary · sentiment ·     │
                    │  risk · embeddings · transcription   │
                    └──────────────────────────────────────┘
```

n8n sits alongside as the **ingestion workflow**: batch upload webhook →
validate → enqueue → notify on completion. It orchestrates *around* the
pipeline, not inside it — the agent graph stays in code so it can be tested and
version-controlled.

---

## 2. The dynamic quality framework

The requirement: business users add, edit, enable, disable and re-weight
Sections → Sub-sections → Criteria with no code change, and historical scores
must stay valid after they do.

**Solution: versioned copy-on-write.**

```
framework_versions ──1:N──> sections ──1:N──> subsections ──1:N──> criteria
      │
      └─ status: draft (editable) | published (immutable) | archived (immutable)
```

- At most one `published` version exists — enforced by a partial unique index,
  not application code.
- A published tree is **immutable at the database level**. The
  `guard_published_framework()` trigger rejects any INSERT/UPDATE/DELETE
  beneath it.
- The admin UI edits a **draft**, created by `clone_framework_version()` on
  first edit. `publish_framework_version()` validates weights, archives the
  incumbent, and promotes the draft atomically.
- `evaluations.framework_version_id` is `ON DELETE RESTRICT`, so an archived
  version physically cannot be deleted while scores reference it.

### Configurability without deploys

`criteria.guidance` is free text, editable in the admin panel, and injected
verbatim into the scoring agent's prompt. Rewriting it changes scoring
behaviour on the next evaluation. That is the mechanism — not a config file, not
a feature flag.

---

## 3. The scoring engine

### Two kinds of change, two costs

This is the central design decision of the project.

| Change | What is needed | Cost |
|---|---|---|
| Re-weight, enable, disable | Re-run the arithmetic over scores that already exist | **Zero LLM calls**, milliseconds |
| Add or edit a criterion | No score exists for that leaf — the transcript must genuinely be re-read | One LLM call per affected call, queued |

`reproject_evaluations_to_version()` applies both: it recomputes everything it
can instantly and enqueues jobs only for evaluations with `missing_criteria > 0`.
The API surfaces this as *"1,204 calls updated instantly · 87 queued for
re-scoring"*.

Treating every framework edit as "re-run everything" would make a weight tweak
cost thousands of API calls.

### Rollup

```
criterion raw_score / max_score  ──> normalized (0..1)
        │ × weight, renormalised over applicable + enabled siblings
        ▼
subsection normalized (0..1)
        │ × subsection weight
        ▼
section normalized (0..1)
        │ × section weight
        ▼
score_percentage (0..100) ──> grade A–F
```

**Renormalisation at every level** is what makes disable and N/A behave
correctly. Each level divides by the sum of weights that actually contributed,
not by 100. Disable three criteria and the survivors scale up to fill the gap,
instead of the section silently capping at 40%.

**Auto-fail** is applied before weighting: a failed `is_critical` criterion
forces the call to 0 and records `auto_fail_reason`, so a zero is never
unexplained.

**Cross-version matching** is by code path
(`section_code`/`subsection_code`/`criterion_code`), never uuid — a cloned
version has all-new uuids for semantically identical nodes.

### Verified

`supabase/tests/scoring_engine_test.sql`, all passing:

| Test | Asserts |
|---|---|
| T1 | Uniform 80% across 31 criteria → exactly 80.000, grade B |
| T2 | N/A removed from denominator (`OPEN_SETUP` = 1.0, not 0.55) |
| T3 | Critical failure → 0.000 with `auto_fail_triggered` |
| T4 | `RESOLUTION` 30%→70% moves the score 65%→85%, zero LLM calls |

---

## 4. Explainability

Every criterion score links to the transcript turns that justified it.

The naive approach — have the LLM quote text and string-match it back — fails
constantly, because models paraphrase, normalise whitespace and silently fix
typos.

Instead:

1. `transcripts.full_text` is the canonical string, immutable once turns exist.
2. `transcript_turns` stores `char_start` / `char_end` **offsets into that
   string**.
3. The scoring agent cites a **turn index**, not free text.
4. The API resolves the turn's stored offsets into `score_citations`.
5. The UI highlights `full_text.slice(char_start, char_end)` — an exact range.

Citations carry a `polarity` (`supporting` / `detracting`) so the drill-down can
render green "what went well" against red "what was missed".

*Verified:* all 1,474 seeded turns slice back byte-exact from their offsets.

---

## 5. Data model notes

**Two agent concepts, deliberately separate.** `profiles` is who logs in;
`support_agents` is whose call is scored. Historical call data routinely
references agents with no login account, so coupling them would force fake auth
users for every CSV import.

**Snapshots over joins.** `criterion_scores` copies the criterion's name, code,
section path, weight and critical flag at scoring time. `evaluations` stores the
entire rubric tree as JSONB. A completed evaluation is therefore fully
renderable in isolation, even if the framework tables changed underneath it.

**Derived data keys on `evaluation_id`, not `call_id`.** Summaries, sentiment
and risk flags are products of a *pipeline run*. Re-running with a better model
yields a second comparable set rather than overwriting the first.

**Rollups are materialised; dashboards are plain views.** The rollups must
preserve the weights used at the time, which a live view could not reproduce.
The dashboard views are plain, because a plain view can never serve stale
numbers — and a re-weight must appear immediately.

---

## 6. The agent pipeline *(Phase 3)*

Five agents plus an aggregator, orchestrated as a LangGraph graph:

| Step | Agent | Output table |
|---|---|---|
| 1 | Preprocessing | `call_statistics` — deterministic, zero LLM cost |
| 2 | Criteria scoring | `criterion_scores` + `score_citations` |
| 3 | Sentiment | `sentiment_analyses`, `sentiment_timeline` |
| 4 | Risk / compliance | `risk_flags` |
| 5 | Summary | `call_summaries` |
| 6 | Aggregator | `subsection_scores`, `section_scores`, `evaluations` |

Steps 2–5 are independent and run concurrently; the aggregator joins them.

Every invocation writes an `agent_runs` row: prompt hash, model, raw and parsed
output, tokens, latency, retry count. That table is what makes the multi-agent
claim inspectable rather than rhetorical.

**Batching:** the scoring agent issues one request **per sub-section** (12
requests), not per criterion (31). Sub-section grouping keeps related criteria in
one judgement context, which improves consistency as well as cost.

**Reliability:** Gemini's free tier returns HTTP 503 under load — observed
directly during this build. The adapter therefore retries with exponential
backoff and walks a configured model fallback ladder, recording `attempt_count`
per step.

**`MOCK_LLM=true`** runs the whole pipeline against deterministic canned
responses: no API calls, no cost, no rate limits, identical output every run.
Essential for UI development, tests, and a live demo that cannot afford to
depend on a free-tier API being healthy.

---

## 7. Hybrid retrieval *(Phase 7)*

A manager asks two incompatible kinds of question:

| Question | Needs |
|---|---|
| *"Show me calls where the customer mentioned billing issues"* | Vector similarity over transcript chunks |
| *"Which agents scored lowest on empathy this week?"* | SQL aggregation — the answer exists in **no single transcript** |

A pure-RAG chatbot fails the second outright. So the router picks a path:
`semantic`, `analytical`, or `hybrid`.

The semantic path uses `search_transcript_chunks()`: pgvector similarity fused
with full-text rank via **Reciprocal Rank Fusion** (k = 60). RRF fuses by *rank*
rather than score, sidestepping the fact that cosine distance and `ts_rank` live
on incomparable scales. Keyword recall is what catches `FIBER-300` and
`error 651` — exactly the tokens embeddings blur away.

The analytical path generates SQL against the read-only dashboard views and
stores it in `chat_messages.generated_sql`, surfaced in the UI as a "how I
calculated this" panel. Auditable grounding, and a strong demo moment.

Chunks are cut **on turn boundaries**, so a retrieved passage is always a
coherent slice of conversation and remains citable back to exact turns.

---

## 8. Security

Three roles: **admin** (everything), **manager** (their team), **agent** (their
own calls). Enforced by RLS, with `can_access_call()` as the single shared
definition so policies across 10+ tables cannot drift apart.

The `SECURITY DEFINER` helpers are not optional: a policy on `profiles` that
reads `profiles` to find the caller's role would re-enter RLS and recurse
infinitely.

Chat sessions are private to their owner with **no admin override** — a
manager's questions to the assistant are their own, and an admin backdoor would
make people stop using it honestly.

The backend uses the `service_role` key and bypasses RLS. The policies protect
the path where the React client talks to Supabase directly, so a leaked anon key
cannot read another team's calls.
