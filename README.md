# CALL-ANALYZER

**AI-powered customer support call intelligence platform.**

Support teams generate thousands of call transcripts. Managers have no scalable
way to review them. CALL-ANALYZER evaluates every call against a **hierarchical,
business-configurable quality framework** using a multi-agent AI pipeline, and
makes every score explainable down to the exact sentence that justified it.

> **Status: Phase 3 of 8 complete.** Schema, scoring engine, backend API and the
> five-agent evaluation pipeline are built and verified — **93 backend tests**
> and 4 SQL scoring-engine assertions passing, with all 84 seeded calls
> evaluated end to end. See [CODEMAP.md](CODEMAP.md) for what every file
> does.

---

## What makes this more than a wrapper around one LLM call

| | |
|---|---|
| **Configurable rubric, no code changes** | Sections → Sub-sections → Criteria live entirely in the database. Business users add, re-weight, enable and disable them from an admin panel. Criterion guidance text is injected straight into the scoring prompt. |
| **Re-weighting costs nothing** | Changing weights re-scores the entire call history with **zero LLM calls** — it is pure arithmetic over scores that already exist. Only genuinely *new* criteria require re-reading transcripts. |
| **History never breaks** | Published framework versions are immutable, enforced by a database trigger. Every score pins to the exact rubric that produced it, plus a full JSONB snapshot. |
| **Every score cites its evidence** | Scores link to transcript turns by exact character offset, so the UI highlights the literal justifying text instead of fuzzy-matching a paraphrase. |
| **Five inspectable agents** | Preprocessing, scoring, sentiment, risk/compliance and summary each log their own prompt, model, output, tokens and latency to `agent_runs`. |
| **Hybrid RAG** | Semantic search alone cannot answer "which agents scored lowest on empathy this week?". Vector similarity is fused with full-text rank and structured SQL. |

---

## Stack

| Layer | Choice | Why |
|---|---|---|
| Database | Supabase (Postgres 17) | Relational tree for the rubric, `pgvector` for RAG, RLS for roles, Auth included |
| Backend | Python + FastAPI | One service, not two. The agents are Python anyway, and FastAPI's auto-generated OpenAPI docs are a free page in the report |
| Agents | LangGraph | A real, testable, version-controlled graph |
| Ingestion workflow | n8n | One visible workflow for batch upload → pipeline trigger → notify |
| LLM | Google Gemini | Provider-agnostic adapter; `MOCK_LLM=true` runs the whole pipeline with no API calls |
| Embeddings | `gemini-embedding-2` @ 768-d | Cloud API — **no local models, no multi-GB downloads** |
| Transcription | `gemini-3.5-transcribe` | Same — audio handled by API, no Whisper weights on disk |
| Frontend | React + Vite | Dashboard, drill-down, admin panel, chat |

---

## Quick start

**Prerequisites:** Docker Desktop, [Supabase CLI](https://supabase.com/docs/guides/cli), Python 3.12+

```bash
git clone https://github.com/deepkakadiya7/CALL-ANALYZER.git
cd CALL-ANALYZER
cp .env.example .env          # then fill in GEMINI_API_KEY

supabase start                # boots Postgres + Auth + Studio, runs all migrations + seed
```

`supabase start` prints your local keys. Paste the anon and service-role keys
into `.env`.

| Service | URL |
|---|---|
| Studio (browse the data) | http://127.0.0.1:54423 |
| API | http://127.0.0.1:54421 |
| Postgres | `postgresql://postgres:postgres@127.0.0.1:54422/postgres` |

> **Ports are remapped to the 544xx range** so this project can run alongside
> another local Supabase project without colliding.

### Verify the install

```bash
export PGURL="postgresql://postgres:postgres@127.0.0.1:54422/postgres"
psql "$PGURL" -f supabase/tests/scoring_engine_test.sql
```

Expected — all four assertions pass:

```
T1 PASS · uniform 80% rolls up to 80.000  (grade B)
T2 PASS · N/A criterion excluded from denominator, OPEN_SETUP = 1.00000
T3 PASS · critical failure -> score 0.000, auto_fail=t
T4a PASS · under v1 weights (RESOLUTION=30%) score = 65.000
T4b PASS · re-weighted to v2 (RESOLUTION=70%) score = 85.000 (grade B) — 0 LLM calls
ALL SCORING ENGINE TESTS PASSED
```

### Run the backend

```bash
cd backend
uv venv --python 3.12
uv pip install -e ".[dev]"
.venv/bin/uvicorn app.main:app --reload --port 8000
```

Interactive API docs: <http://localhost:8000/docs> — 29 endpoints.

```bash
.venv/bin/python -m pytest tests/ -q      # 93 tests
```

### Run the evaluation pipeline

```bash
# Evaluate every unevaluated call (queues jobs)
curl -X POST http://localhost:8000/api/evaluations/bulk -H 'Content-Type: application/json' -d '{}'

# Start the worker to drain the queue
cd backend && MOCK_LLM=true .venv/bin/python -m app.worker
```

`MOCK_LLM=true` runs the whole pipeline with **zero API calls** using
deterministic keyword rules — not a local model, nothing downloaded. Set it to
`false` to use Gemini.

Both paths are verified. A single call evaluated with real Gemini took 195s and
cost **$0.0043**; the same call under the rule baseline took 94ms and cost
nothing. They disagreed usefully — see the comparison in
[CODEMAP.md](CODEMAP.md#live-gemini-validation).

### Reset to a clean seeded state

```bash
supabase db reset            # re-runs every migration + seed from scratch
```

### Regenerate the seed calls

```bash
python3 scripts/generate_seed_calls.py   # rewrites supabase/seeds/02_calls.sql
supabase db reset
```

---

## What's in the seed data

| | |
|---|---|
| Teams | 3 — Billing & Payments, Technical Support, Retention & Loyalty |
| Support agents | 9, each with a fixed skill profile so the leaderboard has real shape |
| Framework v1 | 5 sections · 12 sub-sections · **31 criteria**, weights summing to 100 at every level |
| Auto-fail criteria | `RECORDING_DISCLOSURE`, `IDENTITY_VERIFICATION` |
| Calls | 84 across 8 scenarios and 6 weeks — 1,474 transcript turns |
| Ground truth | Every call records the quality tier each block was generated from, in `calls.metadata.ground_truth` |

That last row matters: it lets you measure the AI's scoring accuracy against a
known answer, which is a genuine evaluation section for the project report
rather than a vibe check.

---

## The quality framework

```
OPENING (15%)
├── Professional Introduction (55%)   → branded greeting · purpose capture · opening tone
└── Call Setup (45%)                  → expectation setting · hold etiquette [N/A-able]

COMMUNICATION (25%)
├── Clarity & Language (35%)          → plain language · jargon · pace
├── Active Listening (35%)            → no interruption · paraphrase · probing questions
└── Empathy & Tone (30%)              → acknowledge emotion · empathy statements · positive tone

RESOLUTION (30%)
├── Diagnosis (30%)                   → root cause · account review
├── Solution Delivery (45%)           → accuracy · step guidance · first-contact resolution
└── Follow-through (25%)              → confirm resolution · offer further help

COMPLIANCE (20%)
├── Mandatory Disclosures (55%)       → recording ⛔ · identity verification ⛔ · data privacy
└── Policy Adherence (45%)            → no unauthorised promises · escalation [N/A] · pricing [N/A]

CLOSING (10%)
├── Call Wrap-up (60%)                → summarise actions · clear next steps
└── Courteous Close (40%)             → thank customer · branded close
```

⛔ = auto-fail. A failed critical criterion forces the whole call to 0, with the
reason recorded — so the UI never shows an unexplained zero.

---

## Build phases

| Phase | Scope | Status |
|---|---|---|
| 1 | DB schema, scoring engine, seed data | ✅ **Complete & verified** |
| 2 | Backend APIs — framework CRUD, ingestion | ✅ **Complete & verified** |
| 3 | Agent pipeline — 5 agents, LangGraph orchestration, job worker | ✅ **Complete & verified** |
| 4 | Aggregation & score computation wiring | ✅ **Done in Phase 3** |
| 5 | React dashboard — overview + drill-down | ⬜ Next |
| 6 | Admin panel for the dynamic framework | ⬜ |
| 7 | RAG chatbot | ⬜ |
| 8 | Polish, architecture diagram, report write-up | ⬜ |

---

## Security

`.env` is gitignored and must stay that way. Never commit API keys, database
passwords, or service-role keys. `.env.example` is the tracked template and
contains placeholders only.
