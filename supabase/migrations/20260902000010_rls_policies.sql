-- ============================================================================
-- 0010 · Row Level Security
-- ----------------------------------------------------------------------------
-- ACCESS MODEL
--   admin    -> everything, every team, plus the framework admin panel
--   manager  -> read everything scoped to profiles.team_id; may trigger
--               re-evaluations and triage risk flags on their own team
--   agent    -> read ONLY calls they personally handled
--
-- IMPLEMENTATION NOTE — why the helper functions are SECURITY DEFINER:
--   A policy on `profiles` that reads `profiles` to find the caller's role
--   would re-enter RLS and recurse infinitely. SECURITY DEFINER functions run
--   as the owner and bypass RLS, breaking the cycle. They are marked STABLE so
--   Postgres evaluates them once per statement rather than once per row.
--
-- The FastAPI backend uses the service_role key, which bypasses RLS entirely.
-- These policies therefore protect the path where the React client talks to
-- Supabase directly (realtime subscriptions, storage) — defence in depth, so a
-- leaked anon key cannot read another team's calls.
-- ============================================================================

-- ── Helper functions ────────────────────────────────────────────────────────
create or replace function auth_role()
returns user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from profiles where id = auth.uid();
$$;

create or replace function auth_team_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select team_id from profiles where id = auth.uid();
$$;

create or replace function is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select role = 'admin' from profiles where id = auth.uid()), false);
$$;

-- True when the caller may see this call: admins always, managers for their own
-- team, agents only for calls they handled. Centralised here so 10+ policies
-- share one definition instead of drifting apart.
create or replace function can_access_call(p_call_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from calls c
      left join support_agents sa on sa.id = c.support_agent_id
     where c.id = p_call_id
       and (
         is_admin()
         or (auth_role() = 'manager' and c.team_id = auth_team_id())
         or (auth_role() = 'agent'   and sa.profile_id = auth.uid())
       )
  );
$$;

comment on function can_access_call is 'Single definition of call visibility, reused by every downstream policy so the three roles cannot drift apart across tables.';

-- ── Enable RLS everywhere ───────────────────────────────────────────────────
alter table teams               enable row level security;
alter table profiles            enable row level security;
alter table support_agents      enable row level security;
alter table framework_versions  enable row level security;
alter table sections            enable row level security;
alter table subsections         enable row level security;
alter table criteria            enable row level security;
alter table ingestion_batches   enable row level security;
alter table calls               enable row level security;
alter table transcripts         enable row level security;
alter table transcript_turns    enable row level security;
alter table evaluations         enable row level security;
alter table criterion_scores    enable row level security;
alter table score_citations     enable row level security;
alter table subsection_scores   enable row level security;
alter table section_scores      enable row level security;
alter table call_summaries      enable row level security;
alter table sentiment_analyses  enable row level security;
alter table sentiment_timeline  enable row level security;
alter table risk_flags          enable row level security;
alter table call_statistics     enable row level security;
alter table agent_runs          enable row level security;
alter table jobs                enable row level security;
alter table transcript_chunks   enable row level security;
alter table chat_sessions       enable row level security;
alter table chat_messages       enable row level security;

-- ── Profiles ────────────────────────────────────────────────────────────────
create policy profiles_select_self_or_privileged on profiles for select
  using (
    id = auth.uid()
    or is_admin()
    or (auth_role() = 'manager' and team_id = auth_team_id())
  );

create policy profiles_update_self on profiles for update
  using (id = auth.uid())
  -- A user may edit their own name and avatar but MUST NOT be able to
  -- self-promote to admin. The WITH CHECK clause re-reads the row after the
  -- update and rejects any change to role or team.
  with check (
    id = auth.uid()
    and role = (select p.role from profiles p where p.id = auth.uid())
    and team_id is not distinct from (select p.team_id from profiles p where p.id = auth.uid())
  );

create policy profiles_admin_all on profiles for all
  using (is_admin()) with check (is_admin());

-- ── Reference data: readable by any authenticated user ──────────────────────
create policy teams_read on teams for select using (auth.uid() is not null);
create policy teams_admin_write on teams for all
  using (is_admin()) with check (is_admin());

create policy support_agents_read on support_agents for select
  using (
    is_admin()
    or (auth_role() = 'manager' and team_id = auth_team_id())
    or profile_id = auth.uid()
  );
create policy support_agents_admin_write on support_agents for all
  using (is_admin()) with check (is_admin());

-- ── Framework: everyone reads, ONLY admins write ────────────────────────────
-- Managers must see the rubric to interpret scores, but the requirement puts
-- rubric authorship in the admin panel, so writes are admin-only.
create policy framework_versions_read on framework_versions for select
  using (auth.uid() is not null);
create policy framework_versions_admin on framework_versions for all
  using (is_admin()) with check (is_admin());

create policy sections_read on sections for select using (auth.uid() is not null);
create policy sections_admin on sections for all using (is_admin()) with check (is_admin());

create policy subsections_read on subsections for select using (auth.uid() is not null);
create policy subsections_admin on subsections for all using (is_admin()) with check (is_admin());

create policy criteria_read on criteria for select using (auth.uid() is not null);
create policy criteria_admin on criteria for all using (is_admin()) with check (is_admin());

-- ── Calls and everything derived from them ──────────────────────────────────
create policy calls_read on calls for select
  using (
    is_admin()
    or (auth_role() = 'manager' and team_id = auth_team_id())
    or (auth_role() = 'agent' and exists (
          select 1 from support_agents sa
           where sa.id = calls.support_agent_id and sa.profile_id = auth.uid()))
  );
create policy calls_admin_write on calls for all
  using (is_admin()) with check (is_admin());

create policy transcripts_read on transcripts for select using (can_access_call(call_id));
create policy transcript_turns_read on transcript_turns for select using (can_access_call(call_id));
create policy evaluations_read on evaluations for select using (can_access_call(call_id));
create policy call_summaries_read on call_summaries for select using (can_access_call(call_id));
create policy sentiment_analyses_read on sentiment_analyses for select using (can_access_call(call_id));
create policy sentiment_timeline_read on sentiment_timeline for select using (can_access_call(call_id));
create policy call_statistics_read on call_statistics for select using (can_access_call(call_id));
create policy agent_runs_read on agent_runs for select using (can_access_call(call_id));
create policy transcript_chunks_read on transcript_chunks for select using (can_access_call(call_id));

-- Score tables reach the call through their evaluation.
create policy criterion_scores_read on criterion_scores for select
  using (exists (select 1 from evaluations e
                  where e.id = criterion_scores.evaluation_id and can_access_call(e.call_id)));

create policy subsection_scores_read on subsection_scores for select
  using (exists (select 1 from evaluations e
                  where e.id = subsection_scores.evaluation_id and can_access_call(e.call_id)));

create policy section_scores_read on section_scores for select
  using (exists (select 1 from evaluations e
                  where e.id = section_scores.evaluation_id and can_access_call(e.call_id)));

create policy score_citations_read on score_citations for select
  using (exists (select 1 from criterion_scores cs
                   join evaluations e on e.id = cs.evaluation_id
                  where cs.id = score_citations.criterion_score_id and can_access_call(e.call_id)));

-- ── Risk flags: readable like a call, but managers may TRIAGE their team's ──
create policy risk_flags_read on risk_flags for select using (can_access_call(call_id));

create policy risk_flags_manager_triage on risk_flags for update
  using (
    is_admin()
    or (auth_role() = 'manager' and exists (
          select 1 from calls c where c.id = risk_flags.call_id and c.team_id = auth_team_id()))
  )
  with check (
    is_admin()
    or (auth_role() = 'manager' and exists (
          select 1 from calls c where c.id = risk_flags.call_id and c.team_id = auth_team_id()))
  );

-- ── Operational tables: admin-only from the client ──────────────────────────
-- The worker reaches these through the service_role key, which bypasses RLS.
create policy jobs_admin on jobs for all using (is_admin()) with check (is_admin());
create policy ingestion_batches_admin on ingestion_batches for all
  using (is_admin()) with check (is_admin());

-- ── Chat: strictly private to its owner ─────────────────────────────────────
-- No admin override. A manager's questions to the assistant are their own;
-- letting an admin read them would make people stop using it honestly.
create policy chat_sessions_own on chat_sessions for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy chat_messages_own on chat_messages for all
  using (exists (select 1 from chat_sessions s
                  where s.id = chat_messages.session_id and s.user_id = auth.uid()))
  with check (exists (select 1 from chat_sessions s
                       where s.id = chat_messages.session_id and s.user_id = auth.uid()));
