-- ============================================================================
-- 0009 · Scoring Engine, Framework Lifecycle & Dashboard Views
-- ----------------------------------------------------------------------------
-- This migration contains the logic that makes the framework "dynamic".
--
-- THE CENTRAL INSIGHT — two kinds of framework change, two costs:
--
--   RE-WEIGHT / ENABLE / DISABLE   pure arithmetic over scores that already
--                                  exist. recompute_evaluation_scores() does it
--                                  in one SQL statement per level.
--                                  Cost: ~0. Latency: milliseconds. LLM calls: 0.
--
--   ADD / EDIT A CRITERION         no score exists for the new leaf, so the
--                                  scoring agent must actually read the
--                                  transcript again.
--                                  Cost: real. Handled as a queued job.
--
-- Collapsing these two into "the framework changed, re-run everything" would
-- make a weight tweak cost thousands of LLM calls. Separating them is the
-- difference between a demo and a product.
--
-- Criterion scores are matched across framework versions by CODE PATH
-- (section_code / subsection_code / criterion_code), never by uuid, because a
-- cloned version has entirely new uuids for semantically identical nodes.
-- ============================================================================

-- ── Grade banding ───────────────────────────────────────────────────────────
create or replace function score_to_grade(p_percentage numeric)
returns text
language sql
immutable
as $$
  select case
    when p_percentage is null then null
    when p_percentage >= 90 then 'A'
    when p_percentage >= 80 then 'B'
    when p_percentage >= 70 then 'C'
    when p_percentage >= 60 then 'D'
    else 'F'
  end;
$$;

-- ============================================================================
-- FRAMEWORK LIFECYCLE
-- ============================================================================

-- ── Weight validation ───────────────────────────────────────────────────────
-- Returns one row per problem. An empty result means the tree is publishable.
-- Deliberately a REPORT rather than a constraint: the admin UI shows these as
-- live warnings while the user edits, and only publish_framework_version()
-- treats them as fatal.
create or replace function validate_framework_weights(p_version_id uuid)
returns table (
  level      text,
  node_path  text,
  node_id    uuid,
  issue      text,
  actual_sum numeric
)
language sql
stable
as $$
  -- Level 1: enabled sections must sum to 100
  select 'section'::text,
         'ROOT'::text,
         p_version_id,
         'Enabled section weights sum to ' || round(coalesce(sum(s.weight), 0), 2) || ', expected 100',
         round(coalesce(sum(s.weight), 0), 2)
    from sections s
   where s.framework_version_id = p_version_id
     and s.is_enabled
  having abs(coalesce(sum(s.weight), 0) - 100) > 0.01

  union all

  -- Level 2: enabled subsections must sum to 100 within each enabled section
  select 'subsection',
         s.code,
         s.id,
         'Enabled subsection weights under "' || s.name || '" sum to '
           || round(coalesce(sum(ss.weight), 0), 2) || ', expected 100',
         round(coalesce(sum(ss.weight), 0), 2)
    from sections s
    join subsections ss on ss.section_id = s.id and ss.is_enabled
   where s.framework_version_id = p_version_id
     and s.is_enabled
   group by s.id, s.code, s.name
  having abs(coalesce(sum(ss.weight), 0) - 100) > 0.01

  union all

  -- Level 3: enabled criteria must sum to 100 within each enabled subsection
  select 'criterion',
         s.code || ' / ' || ss.code,
         ss.id,
         'Enabled criterion weights under "' || ss.name || '" sum to '
           || round(coalesce(sum(c.weight), 0), 2) || ', expected 100',
         round(coalesce(sum(c.weight), 0), 2)
    from sections s
    join subsections ss on ss.section_id = s.id and ss.is_enabled
    join criteria c on c.subsection_id = ss.id and c.is_enabled
   where s.framework_version_id = p_version_id
     and s.is_enabled
   group by s.id, ss.id, s.code, ss.code, ss.name
  having abs(coalesce(sum(c.weight), 0) - 100) > 0.01

  union all

  -- Structural: an enabled section with no enabled leaves scores nothing and
  -- would silently swallow its weight share.
  select 'structure',
         s.code,
         s.id,
         'Section "' || s.name || '" is enabled but has no enabled criteria beneath it',
         0::numeric
    from sections s
   where s.framework_version_id = p_version_id
     and s.is_enabled
     and not exists (
       select 1 from subsections ss
         join criteria c on c.subsection_id = ss.id and c.is_enabled
        where ss.section_id = s.id and ss.is_enabled
     );
$$;

comment on function validate_framework_weights is 'Reports every weight-balance and structural problem in a framework version. Empty result = publishable. Surfaced live in the admin UI and enforced at publish time.';

-- ── Auto-balance helper ─────────────────────────────────────────────────────
-- "Normalize weights" button in the admin UI: scales the enabled siblings at a
-- level so they sum to exactly 100, preserving their relative proportions.
create or replace function normalize_framework_weights(p_version_id uuid)
returns void
language plpgsql
as $$
begin
  -- Sections
  update sections s
     set weight = round(s.weight * 100.0 / t.total, 3)
    from (select sum(weight) as total from sections
           where framework_version_id = p_version_id and is_enabled) t
   where s.framework_version_id = p_version_id
     and s.is_enabled
     and t.total > 0;

  -- Subsections, per section
  update subsections ss
     set weight = round(ss.weight * 100.0 / t.total, 3)
    from (select ss2.section_id, sum(ss2.weight) as total
            from subsections ss2
            join sections s2 on s2.id = ss2.section_id
           where s2.framework_version_id = p_version_id and ss2.is_enabled
           group by ss2.section_id) t
   where ss.section_id = t.section_id
     and ss.is_enabled
     and t.total > 0;

  -- Criteria, per subsection
  update criteria c
     set weight = round(c.weight * 100.0 / t.total, 3)
    from (select c2.subsection_id, sum(c2.weight) as total
            from criteria c2
            join subsections ss2 on ss2.id = c2.subsection_id
            join sections s2 on s2.id = ss2.section_id
           where s2.framework_version_id = p_version_id and c2.is_enabled
           group by c2.subsection_id) t
   where c.subsection_id = t.subsection_id
     and c.is_enabled
     and t.total > 0;
end;
$$;

comment on function normalize_framework_weights is 'Proportionally rescales enabled siblings to sum to 100 at every level. Backs the admin panel''s "auto-balance" action.';

-- ── Clone (copy-on-write) ───────────────────────────────────────────────────
-- The ONLY sanctioned way to change a published framework. Deep-copies the tree
-- into a fresh draft; new uuids everywhere, codes preserved so scores can be
-- re-projected across versions later.
create or replace function clone_framework_version(
  p_source_id  uuid,
  p_new_name   text default null,
  p_created_by uuid default null
)
returns uuid
language plpgsql
as $$
declare
  v_new_id      uuid;
  v_next_no     integer;
  v_source_name text;
begin
  select name into v_source_name from framework_versions where id = p_source_id;
  if v_source_name is null then
    raise exception 'Source framework version % does not exist', p_source_id;
  end if;

  select coalesce(max(version_no), 0) + 1 into v_next_no from framework_versions;

  insert into framework_versions (version_no, name, description, status, cloned_from, created_by)
  select v_next_no,
         coalesce(p_new_name, v_source_name || ' (v' || v_next_no || ')'),
         description,
         'draft',
         p_source_id,
         p_created_by
    from framework_versions
   where id = p_source_id
  returning id into v_new_id;

  -- Sections. The id_map CTEs carry old->new uuid pairs down the tree so the
  -- whole clone happens in three statements instead of a row-by-row loop.
  with ins as (
    insert into sections (framework_version_id, code, name, description, weight, display_order, is_enabled)
    select v_new_id, code, name, description, weight, display_order, is_enabled
      from sections where framework_version_id = p_source_id
    returning id, code
  )
  insert into subsections (section_id, code, name, description, weight, display_order, is_enabled)
  select ins.id, ss.code, ss.name, ss.description, ss.weight, ss.display_order, ss.is_enabled
    from subsections ss
    join sections s_old on s_old.id = ss.section_id
    join ins on ins.code = s_old.code
   where s_old.framework_version_id = p_source_id;

  insert into criteria (subsection_id, code, name, description, weight, scoring_type,
                        max_score, min_score, guidance, examples, is_critical, allow_na,
                        display_order, is_enabled)
  select ss_new.id, c.code, c.name, c.description, c.weight, c.scoring_type,
         c.max_score, c.min_score, c.guidance, c.examples, c.is_critical, c.allow_na,
         c.display_order, c.is_enabled
    from criteria c
    join subsections ss_old on ss_old.id = c.subsection_id
    join sections s_old on s_old.id = ss_old.section_id and s_old.framework_version_id = p_source_id
    join sections s_new on s_new.framework_version_id = v_new_id and s_new.code = s_old.code
    join subsections ss_new on ss_new.section_id = s_new.id and ss_new.code = ss_old.code;

  return v_new_id;
end;
$$;

comment on function clone_framework_version is 'Deep-copies a framework tree into a new draft. Codes are preserved across the clone, which is what lets existing scores be re-projected onto the new version without re-running the LLM.';

-- ── Publish ─────────────────────────────────────────────────────────────────
create or replace function publish_framework_version(
  p_version_id   uuid,
  p_published_by uuid default null
)
returns uuid
language plpgsql
as $$
declare
  v_status    framework_status;
  v_issues    integer;
  v_first     text;
  v_old_id    uuid;
begin
  select status into v_status from framework_versions where id = p_version_id;
  if v_status is null then
    raise exception 'Framework version % does not exist', p_version_id;
  end if;
  if v_status <> 'draft' then
    raise exception 'Only draft versions can be published (version % is %)', p_version_id, v_status;
  end if;

  -- Refuse to publish an unbalanced tree. This is the hard gate the soft
  -- validation warnings in the UI have been previewing all along.
  select count(*), min(issue) into v_issues, v_first
    from validate_framework_weights(p_version_id);

  if v_issues > 0 then
    raise exception 'Cannot publish: % weight/structure issue(s). First: %', v_issues, v_first
      using errcode = 'check_violation';
  end if;

  -- Archive the incumbent. Never deleted: archived versions keep historical
  -- evaluations interpretable, and evaluations.framework_version_id is
  -- ON DELETE RESTRICT to guarantee it.
  select id into v_old_id from framework_versions where status = 'published';
  if v_old_id is not null then
    update framework_versions
       set status = 'archived', archived_at = now()
     where id = v_old_id;
  end if;

  update framework_versions
     set status = 'published', published_at = now(), published_by = p_published_by
   where id = p_version_id;

  return v_old_id;   -- caller diffs old vs new to decide what needs re-scoring
end;
$$;

comment on function publish_framework_version is 'Validates, archives the incumbent, and promotes a draft — atomically. Returns the archived version id so the caller can diff and queue only the work that genuinely needs an LLM.';

-- ============================================================================
-- THE SCORING ENGINE
-- ============================================================================

-- ── Recompute rollups ───────────────────────────────────────────────────────
-- Rebuilds subsection_scores, section_scores and the evaluation total from the
-- criterion_scores that already exist. NO LLM CALLS.
--
-- Pass p_framework_version_id to RE-PROJECT the same criterion scores onto a
-- different version's weights — this is exactly what happens when a manager
-- re-weights the rubric: the transcript was already read, only the arithmetic
-- changes.
--
-- Renormalisation at each level (dividing by the sum of the weights that
-- actually contributed, rather than by 100) is what makes disabled and
-- not-applicable nodes behave correctly instead of silently deflating scores.
create or replace function recompute_evaluation_scores(
  p_evaluation_id        uuid,
  p_framework_version_id uuid default null
)
returns table (
  score_percentage  numeric,
  grade             text,
  missing_criteria  integer
)
language plpgsql
as $$
declare
  v_version_id uuid;
  v_weighted   numeric;
  v_pct        numeric;
  v_grade      text;
  v_autofail   boolean := false;
  v_autofail_reason text;
  v_missing    integer := 0;
begin
  v_version_id := coalesce(
    p_framework_version_id,
    (select framework_version_id from evaluations where id = p_evaluation_id)
  );
  if v_version_id is null then
    raise exception 'Evaluation % not found', p_evaluation_id;
  end if;

  -- STEP 0 — realign each criterion score to the target version's weights and
  -- enabled flags, matching by code path. A score whose criterion no longer
  -- exists in the target version keeps its row but is excluded below by the
  -- join, so history is preserved without polluting the new total.
  update criterion_scores cs
     set weight_snapshot      = c.weight,
         is_critical_snapshot = c.is_critical,
         max_score            = c.max_score,
         normalized           = case
                                  when cs.raw_score is null then null
                                  else least(1, greatest(0,
                                       (cs.raw_score - c.min_score) / nullif(c.max_score - c.min_score, 0)))
                                end
    from criteria c
    join subsections ss on ss.id = c.subsection_id
    join sections s     on s.id  = ss.section_id
   where cs.evaluation_id = p_evaluation_id
     and s.framework_version_id = v_version_id
     and s.code  = cs.section_code
     and ss.code = cs.subsection_code
     and c.code  = cs.criterion_code;

  -- STEP 1 — how many enabled criteria in the target version have no score at
  -- all? These are the ones that genuinely require an LLM re-run; the caller
  -- queues an 'evaluate' job when this is > 0.
  select count(*) into v_missing
    from criteria c
    join subsections ss on ss.id = c.subsection_id and ss.is_enabled
    join sections s     on s.id  = ss.section_id and s.is_enabled
   where s.framework_version_id = v_version_id
     and c.is_enabled
     and not exists (
       select 1 from criterion_scores cs
        where cs.evaluation_id = p_evaluation_id
          and cs.criterion_code = c.code
          and cs.subsection_code = ss.code
          and cs.section_code = s.code
     );

  -- STEP 2 — critical (auto-fail) check, before any weighting. A failed
  -- critical criterion zeroes the call outright; weighting it would be
  -- meaningless.
  select true,
         'Critical criterion failed: ' || string_agg(cs.criterion_name, ', ')
    into v_autofail, v_autofail_reason
    from criterion_scores cs
    join criteria c      on c.code = cs.criterion_code
    join subsections ss  on ss.id = c.subsection_id and ss.code = cs.subsection_code and ss.is_enabled
    join sections s      on s.id = ss.section_id and s.code = cs.section_code and s.is_enabled
   where cs.evaluation_id = p_evaluation_id
     and c.is_critical
     and c.is_enabled
     and cs.is_applicable
     and coalesce(cs.normalized, 0) < 0.5
  having count(*) > 0;

  v_autofail := coalesce(v_autofail, false);

  -- STEP 3 — criteria -> subsections.
  -- Denominator is the sum of contributing weights, NOT 100. Three of five
  -- criteria applicable means the three share 100% of the subsection.
  delete from subsection_scores where evaluation_id = p_evaluation_id;

  insert into subsection_scores (evaluation_id, subsection_id, subsection_code, subsection_name,
                                 section_code, weight_snapshot, normalized,
                                 criteria_total, criteria_scored)
  select p_evaluation_id,
         ss.id,
         ss.code,
         ss.name,
         s.code,
         ss.weight,
         case when sum(cs.weight_snapshot) filter (where cs.is_applicable and cs.normalized is not null) > 0
              then sum(cs.normalized * cs.weight_snapshot)
                     filter (where cs.is_applicable and cs.normalized is not null)
                   / sum(cs.weight_snapshot)
                     filter (where cs.is_applicable and cs.normalized is not null)
              else null
         end,
         count(cs.id),
         count(cs.id) filter (where cs.is_applicable and cs.normalized is not null)
    from subsections ss
    join sections s on s.id = ss.section_id
    left join criteria c on c.subsection_id = ss.id and c.is_enabled
    left join criterion_scores cs
           on cs.evaluation_id = p_evaluation_id
          and cs.criterion_code = c.code
          and cs.subsection_code = ss.code
          and cs.section_code = s.code
   where s.framework_version_id = v_version_id
     and s.is_enabled
     and ss.is_enabled
   group by ss.id, ss.code, ss.name, s.code, ss.weight;

  -- STEP 4 — subsections -> sections. Same renormalisation rule.
  delete from section_scores where evaluation_id = p_evaluation_id;

  insert into section_scores (evaluation_id, section_id, section_code, section_name,
                              weight_snapshot, normalized, subsections_total, subsections_scored)
  select p_evaluation_id,
         s.id,
         s.code,
         s.name,
         s.weight,
         case when sum(sss.weight_snapshot) filter (where sss.normalized is not null) > 0
              then sum(sss.normalized * sss.weight_snapshot) filter (where sss.normalized is not null)
                   / sum(sss.weight_snapshot) filter (where sss.normalized is not null)
              else null
         end,
         count(sss.id),
         count(sss.id) filter (where sss.normalized is not null)
    from sections s
    left join subsection_scores sss
           on sss.evaluation_id = p_evaluation_id
          and sss.section_code = s.code
   where s.framework_version_id = v_version_id
     and s.is_enabled
   group by s.id, s.code, s.name, s.weight;

  -- STEP 5 — sections -> overall.
  select case when sum(ssc.weight_snapshot) filter (where ssc.normalized is not null) > 0
              then sum(ssc.normalized * ssc.weight_snapshot) filter (where ssc.normalized is not null)
                   / sum(ssc.weight_snapshot) filter (where ssc.normalized is not null)
              else null
         end
    into v_weighted
    from section_scores ssc
   where ssc.evaluation_id = p_evaluation_id;

  if v_autofail then
    v_weighted := 0;
  end if;

  v_pct   := round(coalesce(v_weighted, 0) * 100, 3);
  v_grade := score_to_grade(case when v_weighted is null then null else v_pct end);

  update evaluations
     set weighted_score       = v_weighted,
         score_percentage     = case when v_weighted is null then null else v_pct end,
         grade                = v_grade,
         auto_fail_triggered  = v_autofail,
         auto_fail_reason     = v_autofail_reason,
         framework_version_id = v_version_id
   where id = p_evaluation_id;

  return query select v_pct, v_grade, v_missing;
end;
$$;

comment on function recompute_evaluation_scores is
  'Rolls criterion scores up to a final percentage using pure SQL — zero LLM calls. Pass a different framework_version_id to re-project existing scores onto new weights, which is how a re-weight applies instantly across the whole call history. Returns missing_criteria > 0 when new leaves genuinely need the scoring agent.';

-- ── Bulk re-projection ──────────────────────────────────────────────────────
-- The "apply new weights to every historical call" operation. Returns how many
-- evaluations were fully recomputed vs how many still need an LLM pass, which
-- the API turns into "1,204 calls updated instantly · 87 queued for re-scoring".
create or replace function reproject_evaluations_to_version(
  p_framework_version_id uuid,
  p_only_current         boolean default true
)
returns table (
  evaluations_recomputed integer,
  evaluations_incomplete integer
)
language plpgsql
as $$
declare
  v_eval  record;
  v_res   record;
  v_done  integer := 0;
  v_partial integer := 0;
begin
  for v_eval in
    select id from evaluations
     where status = 'completed'
       and (not p_only_current or is_current)
  loop
    select * into v_res
      from recompute_evaluation_scores(v_eval.id, p_framework_version_id);

    if v_res.missing_criteria > 0 then
      v_partial := v_partial + 1;
      -- Queue the LLM work for only the evaluations that actually need it.
      insert into jobs (job_type, evaluation_id, call_id, priority, payload)
      select 'reevaluate', v_eval.id, e.call_id, 50,
             jsonb_build_object('framework_version_id', p_framework_version_id,
                                'reason', 'framework_change')
        from evaluations e where e.id = v_eval.id
      on conflict do nothing;
    else
      v_done := v_done + 1;
    end if;
  end loop;

  return query select v_done, v_partial;
end;
$$;

comment on function reproject_evaluations_to_version is 'Applies a new framework version across historical evaluations: instant arithmetic where possible, queued LLM jobs only where new criteria were introduced.';

-- ============================================================================
-- DASHBOARD VIEWS
-- ============================================================================
-- Plain views, not materialised. At this project's data volume Postgres answers
-- them in milliseconds off the indexes above, and plain views can never serve
-- stale numbers — which matters when a re-weight is supposed to be visible on
-- the dashboard immediately.

create or replace view v_call_overview as
select c.id                 as call_id,
       c.call_code,
       c.started_at,
       c.duration_seconds,
       c.status,
       c.channel,
       c.direction,
       sa.id                as support_agent_id,
       sa.agent_code,
       sa.full_name         as agent_name,
       t.id                 as team_id,
       t.name               as team_name,
       e.id                 as evaluation_id,
       e.score_percentage,
       e.grade,
       e.auto_fail_triggered,
       e.framework_version_id,
       cs.headline,
       cs.resolution_status,
       cs.topics,
       sen.overall_label    as sentiment_label,
       sen.overall_score    as sentiment_score,
       sen.sentiment_delta,
       sen.trajectory       as sentiment_trajectory,
       (select count(*) from risk_flags rf
         where rf.evaluation_id = e.id and not rf.is_false_positive)               as flag_count,
       (select count(*) from risk_flags rf
         where rf.evaluation_id = e.id and rf.severity in ('high','critical')
           and not rf.is_false_positive)                                          as critical_flag_count
  from calls c
  left join support_agents sa on sa.id = c.support_agent_id
  left join teams t           on t.id  = c.team_id
  left join evaluations e     on e.call_id = c.id and e.is_current
  left join call_summaries cs on cs.evaluation_id = e.id
  left join sentiment_analyses sen on sen.evaluation_id = e.id;

comment on view v_call_overview is 'One row per call with its current evaluation flattened. Backs the main call list and is the single source the chatbot''s analytical path queries for call-level questions.';

create or replace view v_agent_scorecard as
select sa.id                       as support_agent_id,
       sa.agent_code,
       sa.full_name                as agent_name,
       sa.is_active,
       t.id                        as team_id,
       t.name                      as team_name,
       count(e.id)                                          as evaluated_calls,
       round(avg(e.score_percentage), 2)                    as avg_score,
       round(min(e.score_percentage), 2)                    as min_score,
       round(max(e.score_percentage), 2)                    as max_score,
       round(stddev_pop(e.score_percentage), 2)             as score_stddev,
       count(*) filter (where e.auto_fail_triggered)        as auto_fails,
       round(avg(sen.sentiment_delta), 3)                   as avg_sentiment_delta,
       round(avg(cst.agent_talk_ratio), 3)                  as avg_talk_ratio,
       count(rf.id) filter (where rf.severity in ('high','critical')) as high_risk_flags,
       max(c.started_at)                                    as last_call_at
  from support_agents sa
  left join teams t on t.id = sa.team_id
  left join calls c on c.support_agent_id = sa.id
  left join evaluations e on e.call_id = c.id and e.is_current and e.status = 'completed'
  left join sentiment_analyses sen on sen.evaluation_id = e.id
  left join call_statistics cst on cst.evaluation_id = e.id
  left join risk_flags rf on rf.evaluation_id = e.id and not rf.is_false_positive
 group by sa.id, sa.agent_code, sa.full_name, sa.is_active, t.id, t.name;

comment on view v_agent_scorecard is 'Per-agent aggregates for the leaderboard. score_stddev is deliberately included: a consistent 78 is a different coaching problem from an erratic 60-95.';

create or replace view v_section_performance as
select ssc.section_code,
       ssc.section_name,
       c.team_id,
       t.name                                as team_name,
       c.support_agent_id,
       date_trunc('week', c.started_at)      as week,
       count(*)                              as sample_size,
       round(avg(ssc.normalized) * 100, 2)   as avg_section_score,
       round(avg(ssc.weight_snapshot), 2)    as section_weight
  from section_scores ssc
  join evaluations e on e.id = ssc.evaluation_id and e.is_current
  join calls c       on c.id = e.call_id
  left join teams t  on t.id = c.team_id
 group by ssc.section_code, ssc.section_name, c.team_id, t.name,
          c.support_agent_id, date_trunc('week', c.started_at);

comment on view v_section_performance is 'Section scores sliced by team, agent and week. Directly backs the dashboard trend chart and drill-down.';

create or replace view v_criterion_performance as
select cs.section_code,
       cs.subsection_code,
       cs.criterion_code,
       cs.criterion_name,
       c.team_id,
       c.support_agent_id,
       count(*) filter (where cs.is_applicable)                       as scored_count,
       count(*) filter (where not cs.is_applicable)                   as na_count,
       round(avg(cs.normalized) filter (where cs.is_applicable) * 100, 2) as avg_score,
       round(avg(cs.confidence), 3)                                   as avg_confidence,
       -- The coaching signal: how often this criterion is outright failed.
       round(100.0 * count(*) filter (where cs.is_applicable and cs.normalized < 0.5)
             / nullif(count(*) filter (where cs.is_applicable), 0), 2) as fail_rate_pct
  from criterion_scores cs
  join evaluations e on e.id = cs.evaluation_id and e.is_current
  join calls c       on c.id = e.call_id
 group by cs.section_code, cs.subsection_code, cs.criterion_code, cs.criterion_name,
          c.team_id, c.support_agent_id;

comment on view v_criterion_performance is 'Leaf-level performance with a fail-rate column — the view a manager actually acts on when choosing what to coach.';

create or replace view v_daily_score_trend as
select date_trunc('day', c.started_at)::date as day,
       c.team_id,
       t.name                                as team_name,
       count(*)                              as calls,
       round(avg(e.score_percentage), 2)     as avg_score,
       round(avg(sen.overall_score), 3)      as avg_sentiment,
       count(*) filter (where e.auto_fail_triggered) as auto_fails,
       count(rf.id) filter (where rf.severity in ('high','critical')) as high_risk_flags
  from calls c
  join evaluations e on e.call_id = c.id and e.is_current and e.status = 'completed'
  left join teams t on t.id = c.team_id
  left join sentiment_analyses sen on sen.evaluation_id = e.id
  left join risk_flags rf on rf.evaluation_id = e.id and not rf.is_false_positive
 group by date_trunc('day', c.started_at)::date, c.team_id, t.name;

comment on view v_daily_score_trend is 'Daily rollup for the overview page''s headline time series.';
