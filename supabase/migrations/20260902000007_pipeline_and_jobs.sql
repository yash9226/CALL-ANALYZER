-- ============================================================================
-- 0007 · Pipeline Observability & Background Jobs
-- ----------------------------------------------------------------------------
-- Two concerns that make the multi-agent claim REAL rather than rhetorical:
--
--   agent_runs : one row per agent invocation per evaluation. Prompt, raw
--                output, tokens, latency, errors. If you cannot inspect each
--                agent's individual input and output, you do not have a
--                pipeline — you have one prompt wearing a trench coat. This
--                table is also the single best demo asset in the project: open
--                a call, show five discrete agent runs with their own I/O.
--
--   jobs       : a Postgres-backed work queue with SKIP LOCKED. Chosen over
--                Celery/Redis because it adds zero infrastructure to a project
--                that already has Postgres, survives restarts, and keeps the
--                whole system deployable as one Docker container plus Supabase.
-- ============================================================================

create table agent_runs (
  id             uuid primary key default gen_random_uuid(),
  evaluation_id  uuid not null references evaluations(id) on delete cascade,
  call_id        uuid not null references calls(id) on delete cascade,

  -- 'preprocessing' | 'scoring' | 'sentiment' | 'risk' | 'summary' | 'aggregator'
  agent_name     text not null,
  -- Execution order within the pipeline graph. Renders the pipeline timeline UI.
  step_order     integer not null default 0,
  status         agent_run_status not null default 'pending',

  -- Versioned prompts. When a prompt is edited, previously computed scores stay
  -- attributable to the exact prompt text that produced them.
  prompt_version text,
  prompt_hash    text,             -- sha256 of the rendered prompt
  model          text,

  -- Full I/O capture, gated by DEBUG_CAPTURE_IO in the backend config so
  -- production runs need not store every transcript twice.
  input_payload  jsonb,
  raw_output     jsonb,
  parsed_output  jsonb,

  input_tokens   integer not null default 0,
  output_tokens  integer not null default 0,
  cost_usd       numeric(10,6) not null default 0,
  latency_ms     integer,
  -- Free-tier LLM APIs return 503 constantly under load; the adapter retries
  -- with backoff and records how many attempts a step actually needed.
  attempt_count  integer not null default 1,

  error_type     text,
  error_message  text,

  started_at     timestamptz,
  completed_at   timestamptz,
  created_at     timestamptz not null default now()
);

create index idx_agent_runs_eval   on agent_runs(evaluation_id, step_order);
create index idx_agent_runs_name   on agent_runs(agent_name, status);
create index idx_agent_runs_failed on agent_runs(created_at desc) where status = 'failed';

comment on table agent_runs is 'Per-agent execution trace. Makes the pipeline inspectable step by step — the difference between a genuine multi-agent system and a single prompt with headings.';
comment on column agent_runs.prompt_hash is 'sha256 of the rendered prompt. Two evaluations with the same hash used identical instructions, which makes score changes attributable to model vs prompt vs rubric.';

-- ── Background job queue ────────────────────────────────────────────────────
create table jobs (
  id            uuid primary key default gen_random_uuid(),
  job_type      job_type not null,
  status        job_status not null default 'queued',
  -- Higher runs first. A manager clicking "Re-evaluate this call" should not
  -- queue behind a 500-call overnight batch.
  priority      integer not null default 100,

  payload       jsonb not null default '{}'::jsonb,   -- {call_id, evaluation_id, ...}
  result        jsonb,

  call_id       uuid references calls(id) on delete cascade,
  evaluation_id uuid references evaluations(id) on delete cascade,
  batch_id      uuid references ingestion_batches(id) on delete set null,

  attempts      integer not null default 0,
  max_attempts  integer not null default 3,
  -- Exponential backoff target. The worker only picks up jobs whose
  -- scheduled_at has passed, which gives free retries for free-tier 503s.
  scheduled_at  timestamptz not null default now(),
  -- Crash recovery: a locked job whose lock is older than the visibility
  -- timeout is reclaimed by reclaim_stale_jobs() rather than being lost.
  locked_at     timestamptz,
  locked_by     text,

  error_message text,
  created_at    timestamptz not null default now(),
  started_at    timestamptz,
  completed_at  timestamptz
);

-- The queue's hot path: "next runnable job, highest priority, oldest first".
create index idx_jobs_dequeue on jobs(priority desc, scheduled_at)
  where status = 'queued';
create index idx_jobs_stale   on jobs(locked_at) where status in ('locked', 'running');
create index idx_jobs_call    on jobs(call_id);
create index idx_jobs_status  on jobs(status, created_at desc);

comment on table jobs is 'Postgres-backed queue consumed with FOR UPDATE SKIP LOCKED. No Redis, no Celery — one less service to deploy and explain.';

-- ── Atomic dequeue ──────────────────────────────────────────────────────────
-- FOR UPDATE SKIP LOCKED is what makes this safe with N concurrent workers:
-- each worker locks a different row instead of contending on the same one.
create or replace function claim_next_job(
  p_worker_id text,
  p_job_types job_type[] default null
)
returns jobs
language plpgsql
as $$
declare
  v_job jobs;
begin
  update jobs
     set status    = 'running',
         locked_at = now(),
         locked_by = p_worker_id,
         attempts  = attempts + 1,
         started_at = coalesce(started_at, now())
   where id = (
     select j.id
       from jobs j
      where j.status = 'queued'
        and j.scheduled_at <= now()
        and (p_job_types is null or j.job_type = any(p_job_types))
      order by j.priority desc, j.scheduled_at
      limit 1
      for update skip locked
   )
  returning * into v_job;

  return v_job;
end;
$$;

comment on function claim_next_job is 'Atomically claims one runnable job. SKIP LOCKED lets multiple workers dequeue concurrently without blocking each other.';

-- ── Crash recovery ──────────────────────────────────────────────────────────
-- Called on worker startup and periodically. A job whose worker died mid-run
-- would otherwise sit in 'running' forever.
create or replace function reclaim_stale_jobs(p_timeout_minutes integer default 15)
returns integer
language plpgsql
as $$
declare
  v_count integer;
begin
  with reclaimed as (
    update jobs
       set status = case
                      when attempts >= max_attempts then 'dead'::job_status
                      else 'queued'::job_status
                    end,
           locked_at = null,
           locked_by = null,
           -- Exponential backoff: 1min, 2min, 4min, ...
           scheduled_at = now() + (interval '1 minute' * power(2, attempts)),
           error_message = coalesce(error_message, 'reclaimed after worker timeout')
     where status in ('locked', 'running')
       and locked_at < now() - make_interval(mins => p_timeout_minutes)
    returning 1
  )
  select count(*) into v_count from reclaimed;

  return v_count;
end;
$$;

comment on function reclaim_stale_jobs is 'Requeues jobs orphaned by a crashed worker, with exponential backoff, and marks permanently failing jobs dead.';
