-- ============================================================================
-- 0003 · The Dynamic Quality Framework   ★ CORE OF THE PROJECT ★
-- ----------------------------------------------------------------------------
-- Requirement: business users must add / edit / enable / disable / re-weight
-- Sections -> Sub-sections -> Criteria WITHOUT a code change, and historical
-- scores must stay valid and explainable after they do.
--
-- DESIGN: versioned copy-on-write tree.
--
--   framework_versions ──1:N──> sections ──1:N──> subsections ──1:N──> criteria
--
--   * A version is either 'draft' (freely editable), 'published' (IMMUTABLE,
--     and at most one exists at a time), or 'archived' (a former published
--     version, retained forever so old scores remain interpretable).
--   * The admin UI never mutates a published version. The first edit calls
--     clone_framework_version() which deep-copies the tree into a new draft.
--   * publish_framework_version() validates weights, archives the incumbent,
--     and promotes the draft in one transaction.
--   * evaluations.framework_version_id pins each score to the exact tree that
--     produced it, so deleting a criterion next semester cannot corrupt or
--     orphan a score computed last semester.
--
-- WHY THREE TABLES INSTEAD OF ONE SELF-REFERENCING `nodes` TABLE:
--   The hierarchy depth is fixed at three by the business requirement, and
--   criteria carry attributes the other two levels do not (scoring_type,
--   max_score, LLM guidance, critical/auto-fail). Three explicit tables give
--   stronger constraints, simpler joins, and far more readable SQL than a
--   recursive CTE over a generic tree.
-- ============================================================================

-- ── Framework versions ──────────────────────────────────────────────────────
create table framework_versions (
  id           uuid primary key default gen_random_uuid(),
  version_no   integer not null unique,      -- monotonic: 1, 2, 3 ...
  name         text not null,                -- 'Q3 2026 Support Rubric'
  description  text,
  status       framework_status not null default 'draft',
  notes        text,                         -- changelog shown in the admin UI
  -- Set when this draft was cloned from an earlier version. Lets the UI render
  -- a "what changed since v3" diff.
  cloned_from  uuid references framework_versions(id) on delete set null,
  created_by   uuid references profiles(id) on delete set null,
  published_by uuid references profiles(id) on delete set null,
  published_at timestamptz,
  archived_at  timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- Enforce "at most one published version" at the database level rather than in
-- application code. A partial unique index is the cheapest correct way to do it.
create unique index uq_one_published_framework
  on framework_versions ((status))
  where status = 'published';

create index idx_framework_versions_status on framework_versions(status);

comment on table framework_versions is 'Immutability boundary for the quality rubric. Exactly one row may be status=published; evaluations pin to a version id so historical scores never break when the rubric evolves.';

-- ── Sections (level 1) ──────────────────────────────────────────────────────
create table sections (
  id                   uuid primary key default gen_random_uuid(),
  framework_version_id uuid not null references framework_versions(id) on delete cascade,
  code                 text not null,        -- stable across versions: 'OPENING'
  name                 text not null,
  description          text,
  -- Relative importance among sections in the SAME version. Conventionally sums
  -- to 100, but not hard-constrained: the admin UI must allow a temporarily
  -- unbalanced draft while the user is mid-edit. Balance is validated at
  -- publish time by validate_framework_weights() in migration 0009.
  weight               numeric(7,3) not null default 0 check (weight >= 0),
  display_order        integer not null default 0,
  is_enabled           boolean not null default true,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),

  unique (framework_version_id, code)
);

create index idx_sections_version on sections(framework_version_id, display_order);

comment on column sections.code is 'Stable identifier carried through clones. Lets the dashboard trend "Compliance" across framework versions even after its uuid changes.';
comment on column sections.is_enabled is 'Disabled nodes are excluded from scoring AND from weight normalisation, so disabling a section silently re-weights the rest instead of dropping the total below 100.';

-- ── Sub-sections (level 2) ──────────────────────────────────────────────────
create table subsections (
  id            uuid primary key default gen_random_uuid(),
  section_id    uuid not null references sections(id) on delete cascade,
  code          text not null,
  name          text not null,
  description   text,
  weight        numeric(7,3) not null default 0 check (weight >= 0),  -- sums to 100 within its section
  display_order integer not null default 0,
  is_enabled    boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  unique (section_id, code)
);

create index idx_subsections_section on subsections(section_id, display_order);

-- ── Criteria (level 3 — the leaves the LLM actually scores) ─────────────────
create table criteria (
  id            uuid primary key default gen_random_uuid(),
  subsection_id uuid not null references subsections(id) on delete cascade,
  code          text not null,
  name          text not null,
  description   text,
  weight        numeric(7,3) not null default 0 check (weight >= 0),  -- sums to 100 within its subsection

  -- ── How this criterion is measured ──────────────────────────────────────
  scoring_type  scoring_type not null default 'scale_5',
  max_score     numeric(7,3) not null default 5 check (max_score > 0),
  min_score     numeric(7,3) not null default 0,

  -- ── What the LLM is told ────────────────────────────────────────────────
  -- `guidance` is injected verbatim into the scoring agent's prompt. This is
  -- the mechanism that makes the framework configurable WITHOUT code changes:
  -- a business user rewrites the rubric text in the admin UI and the next
  -- evaluation immediately scores against the new definition.
  guidance      text,
  -- Optional few-shot anchors: [{"score": 5, "example": "...", "why": "..."}]
  examples      jsonb not null default '[]'::jsonb,

  -- ── Behaviour flags ─────────────────────────────────────────────────────
  -- A failed critical criterion (e.g. a missing call-recording disclosure)
  -- forces the whole call's score to zero regardless of everything else.
  -- Standard practice in real QA rubrics; handled by the aggregator.
  is_critical   boolean not null default false,
  -- Allows the scoring agent to return "not applicable" (e.g. a refund script
  -- on a call with no refund). N/A criteria are dropped from the denominator
  -- rather than scored zero — scoring them zero would unfairly punish agents.
  allow_na      boolean not null default true,

  display_order integer not null default 0,
  is_enabled    boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  unique (subsection_id, code),
  constraint criteria_score_range check (max_score > min_score)
);

create index idx_criteria_subsection on criteria(subsection_id, display_order);
create index idx_criteria_enabled    on criteria(is_enabled) where is_enabled;
create index idx_criteria_critical   on criteria(is_critical) where is_critical;

comment on table criteria is 'The leaf nodes the scoring agent evaluates. `guidance` and `examples` are injected into the prompt, which is how business users change scoring behaviour with zero code deploys.';
comment on column criteria.is_critical is 'Auto-fail. If scored as not-met, the aggregator zeroes the entire call score and records the reason.';
comment on column criteria.allow_na is 'When true the agent may return is_applicable=false; the criterion is then removed from the weighted denominator instead of scored 0.';

-- ── updated_at triggers ─────────────────────────────────────────────────────
create trigger trg_framework_versions_updated_at before update on framework_versions
  for each row execute function set_updated_at();
create trigger trg_sections_updated_at before update on sections
  for each row execute function set_updated_at();
create trigger trg_subsections_updated_at before update on subsections
  for each row execute function set_updated_at();
create trigger trg_criteria_updated_at before update on criteria
  for each row execute function set_updated_at();

-- ── Immutability guard for published versions ───────────────────────────────
-- Belt and braces: even if the API has a bug, the database refuses to mutate a
-- published or archived tree. This is what makes "historical scores stay valid"
-- a guarantee rather than a hope.
create or replace function guard_published_framework()
returns trigger
language plpgsql
as $$
declare
  v_status     framework_status;
  v_version_id uuid;
  v_row        record;
begin
  -- On DELETE only OLD is populated; on INSERT only NEW. Pick whichever exists.
  if tg_op = 'DELETE' then
    v_row := old;
  else
    v_row := new;
  end if;

  -- Resolve the owning framework version. This MUST be an IF/ELSIF ladder, not
  -- a CASE expression: plpgsql resolves every branch of a CASE against the
  -- record's actual type, so `new.section_id` would fail to compile when the
  -- trigger fires on `sections`, which has no such column.
  if tg_table_name = 'sections' then
    v_version_id := v_row.framework_version_id;

  elsif tg_table_name = 'subsections' then
    select s.framework_version_id into v_version_id
      from sections s where s.id = v_row.section_id;

  elsif tg_table_name = 'criteria' then
    select s.framework_version_id into v_version_id
      from subsections ss
      join sections s on s.id = ss.section_id
     where ss.id = v_row.subsection_id;
  end if;

  select status into v_status from framework_versions where id = v_version_id;

  -- A NULL status means the parent version row is itself being deleted and the
  -- cascade is tidying up beneath it. Nothing to protect, so allow it.
  if v_status is null then
    return v_row;
  end if;

  if v_status in ('published', 'archived') then
    raise exception
      'Framework version % is % and therefore immutable. Clone it to a draft before editing (see clone_framework_version).',
      v_version_id, v_status
      using errcode = 'check_violation';
  end if;

  return v_row;
end;
$$;

create trigger trg_guard_sections
  before insert or update or delete on sections
  for each row execute function guard_published_framework();
create trigger trg_guard_subsections
  before insert or update or delete on subsections
  for each row execute function guard_published_framework();
create trigger trg_guard_criteria
  before insert or update or delete on criteria
  for each row execute function guard_published_framework();
