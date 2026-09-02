-- ============================================================================
-- 0006 · Non-Scoring Agent Outputs
-- ----------------------------------------------------------------------------
-- The scoring agent is only one of five. These tables hold what the summary,
-- sentiment, and risk agents produce.
--
-- Everything here hangs off evaluation_id, not call_id. That is deliberate: an
-- agent's output is a PRODUCT OF A PIPELINE RUN, not an intrinsic property of
-- the call. Re-run the pipeline with a better model and you get a second, fully
-- comparable set of outputs instead of silently overwriting the first.
-- ============================================================================

-- ── Summary agent ───────────────────────────────────────────────────────────
create table call_summaries (
  id                uuid primary key default gen_random_uuid(),
  evaluation_id     uuid not null unique references evaluations(id) on delete cascade,
  call_id           uuid not null references calls(id) on delete cascade,

  headline          text,          -- one-line, for dense table rows
  summary           text not null, -- 3-5 sentence manager-readable narrative

  customer_intent   text,          -- 'billing_dispute', 'service_outage', ...
  resolution_status text check (resolution_status is null or resolution_status in
                      ('resolved', 'partially_resolved', 'unresolved', 'escalated', 'follow_up_scheduled')),
  outcome           text,

  -- ["overcharge on FIBER-300 plan", "second call about the same fault"]
  key_issues        jsonb not null default '[]'::jsonb,
  -- ["billing", "refund", "plan_change"] -- powers topic filters and the
  -- chatbot's structured "calls about X" queries without an LLM round-trip.
  topics            text[] not null default '{}',
  -- [{"action": "issue credit note", "owner": "billing", "due": "48h"}]
  next_actions      jsonb not null default '[]'::jsonb,

  created_at        timestamptz not null default now()
);

create index idx_summaries_call   on call_summaries(call_id);
create index idx_summaries_topics on call_summaries using gin(topics);
create index idx_summaries_status on call_summaries(resolution_status);

comment on column call_summaries.topics is 'GIN-indexed text[] so "show me billing calls" resolves as a fast structured filter rather than a semantic search.';

-- ── Sentiment agent: per-call rollup ────────────────────────────────────────
create table sentiment_analyses (
  id                 uuid primary key default gen_random_uuid(),
  evaluation_id      uuid not null unique references evaluations(id) on delete cascade,
  call_id            uuid not null references calls(id) on delete cascade,

  overall_label      sentiment_label not null,
  overall_score      numeric(4,3) not null check (overall_score between -1 and 1),

  -- The trajectory metrics are the interesting part for a support QA product.
  -- A call that opens at -0.8 and closes at +0.4 is a SUCCESS even though its
  -- average sentiment is negative — a plain average would hide that entirely.
  opening_score      numeric(4,3) check (opening_score between -1 and 1),
  closing_score      numeric(4,3) check (closing_score between -1 and 1),
  sentiment_delta    numeric(4,3),   -- closing - opening; the recovery metric
  lowest_score       numeric(4,3),
  lowest_turn_index  integer,
  volatility         numeric(5,4),   -- stddev across turns; spiky = rocky call
  trajectory         text check (trajectory is null or trajectory in
                       ('improving', 'declining', 'stable', 'volatile', 'recovered')),

  -- {"frustration": 0.7, "confusion": 0.3, "relief": 0.5}
  dominant_emotions  jsonb not null default '{}'::jsonb,
  analysis_notes     text,

  created_at         timestamptz not null default now()
);

create index idx_sentiment_call       on sentiment_analyses(call_id);
create index idx_sentiment_trajectory on sentiment_analyses(trajectory);
create index idx_sentiment_delta      on sentiment_analyses(sentiment_delta);

comment on column sentiment_analyses.sentiment_delta is 'closing minus opening. The single most useful support-quality signal: it measures whether the agent turned the call around, which an average sentiment score cannot.';

-- ── Sentiment agent: per-turn timeline ──────────────────────────────────────
-- Drives the sparkline in the call drill-down. Only customer turns are scored
-- by default (agent sentiment is largely scripted and adds noise).
create table sentiment_timeline (
  id             uuid primary key default gen_random_uuid(),
  evaluation_id  uuid not null references evaluations(id) on delete cascade,
  call_id        uuid not null references calls(id) on delete cascade,
  turn_id        uuid references transcript_turns(id) on delete set null,

  turn_index     integer not null,
  speaker        speaker_role not null,
  score          numeric(4,3) not null check (score between -1 and 1),
  label          sentiment_label not null,
  emotions       jsonb not null default '{}'::jsonb,

  created_at     timestamptz not null default now(),
  unique (evaluation_id, turn_index)
);

create index idx_sentiment_timeline_eval on sentiment_timeline(evaluation_id, turn_index);

-- ── Risk / compliance agent ─────────────────────────────────────────────────
create table risk_flags (
  id             uuid primary key default gen_random_uuid(),
  evaluation_id  uuid not null references evaluations(id) on delete cascade,
  call_id        uuid not null references calls(id) on delete cascade,

  -- 'escalation_risk' | 'churn_risk' | 'missed_disclosure' | 'policy_violation'
  -- | 'unauthorized_promise' | 'pii_exposure' | 'abusive_language' | 'legal_threat'
  flag_type      text not null,
  severity       risk_severity not null,
  title          text not null,
  description    text not null,
  confidence     numeric(4,3) check (confidence is null or confidence between 0 and 1),

  -- Evidence, same pattern as score_citations.
  turn_id        uuid references transcript_turns(id) on delete set null,
  turn_index     integer,
  quoted_text    text,
  char_start     integer,
  char_end       integer,

  -- Human workflow on top of the AI output: a manager triages flags.
  is_acknowledged boolean not null default false,
  acknowledged_by uuid references profiles(id) on delete set null,
  acknowledged_at timestamptz,
  is_false_positive boolean not null default false,
  reviewer_notes  text,

  created_at     timestamptz not null default now()
);

create index idx_risk_flags_call     on risk_flags(call_id);
create index idx_risk_flags_eval     on risk_flags(evaluation_id);
create index idx_risk_flags_severity on risk_flags(severity, created_at desc);
create index idx_risk_flags_open     on risk_flags(severity) where not is_acknowledged;
create index idx_risk_flags_type     on risk_flags(flag_type);

comment on table risk_flags is 'Risk/compliance agent output plus a human triage layer. is_false_positive feedback is what would train prompt improvements over time.';

-- ── Preprocessing agent: derived conversation statistics ────────────────────
-- Cheap deterministic metrics computed without an LLM. They feed the dashboard
-- directly AND are injected into the scoring prompt as context (an agent who
-- spoke 85% of the time was probably not listening).
create table call_statistics (
  id                    uuid primary key default gen_random_uuid(),
  evaluation_id         uuid not null unique references evaluations(id) on delete cascade,
  call_id               uuid not null references calls(id) on delete cascade,

  agent_turn_count      integer not null default 0,
  customer_turn_count   integer not null default 0,
  agent_word_count      integer not null default 0,
  customer_word_count   integer not null default 0,
  -- agent_words / total_words. >0.75 is a listening red flag.
  agent_talk_ratio      numeric(5,4),
  longest_agent_turn_words integer,
  -- Turns where the same speaker fires twice in a row after a short turn:
  -- a heuristic proxy for interruption when audio timings are unavailable.
  interruption_count    integer not null default 0,
  question_count_agent  integer not null default 0,
  filler_word_count     integer not null default 0,
  detected_language     text,

  created_at            timestamptz not null default now()
);

create index idx_call_stats_call on call_statistics(call_id);

comment on table call_statistics is 'Deterministic, zero-LLM-cost metrics from the preprocessing agent. Doubles as prompt context for the scoring agent and as dashboard data in its own right.';
