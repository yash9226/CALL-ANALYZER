-- ============================================================================
-- 0002 · Identity, Teams & Support Agents
-- ----------------------------------------------------------------------------
-- Two distinct concepts that are easy to conflate:
--
--   profiles        -> a PERSON WHO LOGS IN (admin / manager / agent). 1:1 with
--                      Supabase's auth.users. Drives RLS.
--   support_agents  -> the SUBJECT OF EVALUATION, i.e. the person who handled
--                      the call. Deliberately NOT tied to auth.users, because
--                      historical call data routinely references agents who have
--                      no login, have left the company, or came from a CSV
--                      export. `profile_id` optionally links the two when an
--                      agent does have an account.
--
-- Keeping them separate is what lets us ingest a year of historical calls
-- without minting fake auth accounts.
-- ============================================================================

-- ── Teams ───────────────────────────────────────────────────────────────────
create table teams (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,              -- 'BILLING', 'TECH', 'RETENTION'
  name        text not null,
  description text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table teams is 'Support teams. Managers are scoped to exactly one team via profiles.team_id; RLS uses this to fence off cross-team data.';

-- ── Profiles (login identities) ─────────────────────────────────────────────
create table profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text not null,
  full_name  text not null,
  role       user_role not null default 'agent',
  -- NULL team_id for an admin means "all teams". For a manager it is required
  -- and is enforced by the check constraint below.
  team_id    uuid references teams(id) on delete set null,
  avatar_url text,
  is_active  boolean not null default true,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint manager_must_have_team
    check (role <> 'manager' or team_id is not null)
);

create index idx_profiles_role    on profiles(role);
create index idx_profiles_team    on profiles(team_id);

comment on table profiles is 'One row per authenticated user, mirroring auth.users. `role` is the single source of truth for every RLS policy in migration 0010.';
comment on column profiles.team_id is 'Scope for managers. NULL + role=admin means unrestricted access.';

-- ── Support agents (evaluation subjects) ────────────────────────────────────
create table support_agents (
  id          uuid primary key default gen_random_uuid(),
  agent_code  text not null unique,             -- stable external id, e.g. 'AGT-1042'
  full_name   text not null,
  email       text,
  team_id     uuid references teams(id) on delete set null,
  -- Optional bridge to a login account. When present, an 'agent' role user can
  -- see their own calls (see RLS policies).
  profile_id  uuid unique references profiles(id) on delete set null,
  hired_at    date,
  is_active   boolean not null default true,
  metadata    jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index idx_support_agents_team    on support_agents(team_id);
create index idx_support_agents_active  on support_agents(is_active) where is_active;

comment on table support_agents is 'The agent whose performance a call is scored against. Decoupled from auth so historical/CSV data can be ingested without login accounts.';

-- ── Shared updated_at trigger ───────────────────────────────────────────────
-- Attached to every table that carries an updated_at column. Declared here
-- because it is the first migration that needs it.
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_teams_updated_at
  before update on teams
  for each row execute function set_updated_at();

create trigger trg_profiles_updated_at
  before update on profiles
  for each row execute function set_updated_at();

create trigger trg_support_agents_updated_at
  before update on support_agents
  for each row execute function set_updated_at();

-- ── Auto-provision a profile on signup ──────────────────────────────────────
-- Without this, a user who signs up through Supabase Auth would have no profile
-- row and every RLS policy would deny them. New users default to 'agent'; an
-- admin promotes them from the admin panel.
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    coalesce((new.raw_user_meta_data ->> 'role')::user_role, 'agent')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();
