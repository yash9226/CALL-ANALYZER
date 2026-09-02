-- ============================================================================
-- 0005 · Evaluations, Score Rollups & Citations
-- ----------------------------------------------------------------------------
-- One CALL can have MANY evaluations over its lifetime: the first run, a re-run
-- after the rubric was revised, a re-run after a model upgrade. `is_current`
-- marks the one the dashboard shows; the rest are history and stay queryable so
-- a manager can answer "did this agent's score change because they got better,
-- or because we changed the rubric?".
--
-- SCORE ROLLUP (implemented in migration 0009's recompute_evaluation_scores):
--
--   criterion_scores   raw_score / max_score  ->  normalized (0..1)
--          |  x weight_snapshot, renormalised over APPLICABLE + ENABLED siblings
--          v
--   subsection_scores  (0..1)
--          |  x subsection weight
--          v
--   section_scores     (0..1)
--          |  x section weight
--          v
--   evaluations.score_percentage  (0..100)
--
-- Renormalising at every level is what makes disable/N-A behave correctly: turn
-- off three criteria and the remaining ones' weights scale up to fill the gap,
-- rather than the section quietly capping at 40%.
--
-- WEIGHT SNAPSHOTS: every score row copies the weight it was computed with.
-- This is intentional denormalisation. It means a completed evaluation can be
-- fully re-explained ("empathy was 20% of Communication back then") without
-- joining to a framework version that may since have been archived.
-- ============================================================================

create table evaluations (
  id                   uuid primary key default gen_random_uuid(),
  call_id              uuid not null references calls(id) on delete cascade,
  -- Pins this evaluation to the exact rubric tree used. Never cascades: an
  -- archived framework version must survive as long as scores reference it.
  framework_version_id uuid not null references framework_versions(id) on delete restrict,

  status               evaluation_status not null default 'queued',

  -- ── Results ─────────────────────────────────────────────────────────────
  score_percentage     numeric(6,3) check (score_percentage is null or score_percentage between 0 and 100),
  weighted_score       numeric(10,4),      -- 0..1 before the x100
  grade                text,               -- 'A' | 'B' | 'C' | 'D' | 'F', from score_bands()
  -- Set when a criterion marked is_critical failed. The score is forced to 0
  -- and this explains why, so the UI never shows an unexplained zero.
  auto_fail_triggered  boolean not null default false,
  auto_fail_reason     text,

  -- ── Which evaluation the dashboard reads ────────────────────────────────
  -- Exactly one current evaluation per call, enforced by a partial unique index.
  is_current           boolean not null default true,
  supersedes           uuid references evaluations(id) on delete set null,
  -- Why this run happened: 'initial' | 'framework_change' | 'manual_rerun' | 'model_upgrade'
  trigger_reason       text not null default 'initial',

  -- ── Full rubric snapshot ────────────────────────────────────────────────
  -- The entire section/subsection/criteria tree, with weights and guidance text,
  -- as it stood at evaluation time. Belt-and-braces on top of the version
  -- reference: even if every framework row were deleted, this evaluation could
  -- still be rendered and audited in full.
  framework_snapshot   jsonb,

  -- ── Cost & performance telemetry ────────────────────────────────────────
  model_used           text,
  input_tokens         integer not null default 0,
  output_tokens        integer not null default 0,
  cost_usd             numeric(10,6) not null default 0,
  duration_ms          integer,

  error_message        text,
  started_at           timestamptz,
  completed_at         timestamptz,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

create unique index uq_current_evaluation_per_call
  on evaluations(call_id) where is_current;

create index idx_evaluations_call      on evaluations(call_id, created_at desc);
create index idx_evaluations_version   on evaluations(framework_version_id);
create index idx_evaluations_status    on evaluations(status);
create index idx_evaluations_current   on evaluations(is_current, score_percentage) where is_current;

comment on column evaluations.framework_snapshot is 'Self-contained copy of the rubric tree used. Guarantees an evaluation remains explainable in isolation, independent of the framework tables.';
comment on column evaluations.is_current is 'Dashboard reads WHERE is_current. Re-running an evaluation flips the old row false and links it via supersedes, preserving score history.';

-- ── Criterion scores (the leaves) ───────────────────────────────────────────
create table criterion_scores (
  id             uuid primary key default gen_random_uuid(),
  evaluation_id  uuid not null references evaluations(id) on delete cascade,
  -- ON DELETE SET NULL, not CASCADE: if a criterion is somehow removed, the
  -- score must survive — the snapshot columns below keep it readable.
  criterion_id   uuid references criteria(id) on delete set null,

  -- Snapshot columns: everything needed to render this score without any join.
  criterion_code text not null,
  criterion_name text not null,
  subsection_code text not null,
  section_code    text not null,
  scoring_type   scoring_type not null,
  weight_snapshot numeric(7,3) not null,
  is_critical_snapshot boolean not null default false,

  -- ── The score itself ────────────────────────────────────────────────────
  raw_score      numeric(7,3),                 -- in the criterion's own scale
  max_score      numeric(7,3) not null,
  normalized     numeric(6,5)                  -- raw_score / max_score, 0..1
                 check (normalized is null or normalized between 0 and 1),

  -- The agent's own uncertainty. Surfaced in the UI so a manager knows which
  -- scores to spot-check, and usable as a filter for human review queues.
  confidence     numeric(4,3) check (confidence is null or confidence between 0 and 1),

  -- Free-text justification from the scoring agent. The CITATIONS in the next
  -- table are the hard evidence; this is the narrative around them.
  reasoning      text,

  -- N/A handling: excluded from the weighted denominator rather than scored 0.
  is_applicable  boolean not null default true,
  na_reason      text,

  created_at     timestamptz not null default now(),

  unique (evaluation_id, criterion_code),
  constraint score_within_range check (raw_score is null or raw_score <= max_score)
);

create index idx_criterion_scores_eval    on criterion_scores(evaluation_id);
create index idx_criterion_scores_criterion on criterion_scores(criterion_id);
create index idx_criterion_scores_section  on criterion_scores(section_code);

comment on table criterion_scores is 'Leaf-level scores. Snapshot columns (criterion_code/name, weight, section path) make each row self-describing so historical scores render even after the rubric changes.';

-- ── ★ Explainability: citations ─────────────────────────────────────────────
create table score_citations (
  id                 uuid primary key default gen_random_uuid(),
  criterion_score_id uuid not null references criterion_scores(id) on delete cascade,
  -- The turn the agent pointed at. SET NULL rather than CASCADE so a citation
  -- survives even if turns are rebuilt; quoted_text below is the fallback.
  transcript_turn_id uuid references transcript_turns(id) on delete set null,
  turn_index         integer,

  -- Verbatim text the agent quoted. Kept even when turn_id resolves, because
  -- the agent may cite a fragment of a long turn rather than the whole thing.
  quoted_text        text not null,
  -- Offsets into transcripts.full_text. Resolved server-side from the cited
  -- turn, so the UI highlights an exact range and never string-matches.
  char_start         integer,
  char_end           integer,

  -- Does this excerpt support a HIGH score or explain a LOW one? Lets the UI
  -- render green "what went well" vs red "what was missed" evidence.
  polarity           text not null default 'supporting'
                     check (polarity in ('supporting', 'detracting', 'neutral')),
  relevance          numeric(4,3) check (relevance is null or relevance between 0 and 1),

  created_at         timestamptz not null default now()
);

create index idx_citations_score on score_citations(criterion_score_id);
create index idx_citations_turn  on score_citations(transcript_turn_id);

comment on table score_citations is 'The explainability requirement, made concrete. Every criterion score links to the transcript turns that justified it, with exact character offsets for UI highlighting.';

-- ── Rollup tables ───────────────────────────────────────────────────────────
-- Materialised rather than computed as views. Reasons: (1) the dashboard's
-- section-trend charts aggregate across thousands of calls and must be fast;
-- (2) a rollup must reflect the weights used AT THE TIME, which a live view
-- over the current framework could not reproduce.
create table subsection_scores (
  id                 uuid primary key default gen_random_uuid(),
  evaluation_id      uuid not null references evaluations(id) on delete cascade,
  subsection_id      uuid references subsections(id) on delete set null,
  subsection_code    text not null,
  subsection_name    text not null,
  section_code       text not null,
  weight_snapshot    numeric(7,3) not null,
  normalized         numeric(6,5) check (normalized is null or normalized between 0 and 1),
  -- How many leaves actually contributed, for the "3 of 5 criteria applicable"
  -- caption in the drill-down UI.
  criteria_total     integer not null default 0,
  criteria_scored    integer not null default 0,
  created_at         timestamptz not null default now(),
  unique (evaluation_id, subsection_code)
);

create index idx_subsection_scores_eval on subsection_scores(evaluation_id);

create table section_scores (
  id                 uuid primary key default gen_random_uuid(),
  evaluation_id      uuid not null references evaluations(id) on delete cascade,
  section_id         uuid references sections(id) on delete set null,
  section_code       text not null,
  section_name       text not null,
  weight_snapshot    numeric(7,3) not null,
  normalized         numeric(6,5) check (normalized is null or normalized between 0 and 1),
  subsections_total  integer not null default 0,
  subsections_scored integer not null default 0,
  created_at         timestamptz not null default now(),
  unique (evaluation_id, section_code)
);

create index idx_section_scores_eval on section_scores(evaluation_id);
create index idx_section_scores_code on section_scores(section_code, normalized);

create trigger trg_evaluations_updated_at before update on evaluations
  for each row execute function set_updated_at();
