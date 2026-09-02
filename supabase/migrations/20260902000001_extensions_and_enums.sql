-- ============================================================================
-- 0001 · Extensions & Enumerated Types
-- ----------------------------------------------------------------------------
-- Every enum used across the platform is declared here so later migrations can
-- reference them freely. Enums (rather than free-text CHECK constraints) give us
-- type-safety at the DB level and auto-generate as TypeScript union types in the
-- Supabase client, which keeps the frontend honest.
-- ============================================================================

create extension if not exists "uuid-ossp";      -- uuid_generate_v4()
create extension if not exists "pgcrypto";       -- gen_random_uuid(), digest()
create extension if not exists "vector";         -- pgvector: RAG embeddings
create extension if not exists "pg_trgm";        -- fuzzy text search on transcripts

-- ── Identity ────────────────────────────────────────────────────────────────
-- admin   : full access to every team, every call, and the framework admin panel
-- manager : read access scoped to their own team; can trigger re-evaluations
-- agent   : read access to their own calls only
create type user_role as enum ('admin', 'manager', 'agent');

-- ── Quality framework ───────────────────────────────────────────────────────
-- A framework version is the unit of immutability. Exactly one may be
-- 'published' at a time; edits always happen on a 'draft' copy.
create type framework_status as enum ('draft', 'published', 'archived');

-- How a single criterion is measured. The scoring agent is told which of these
-- applies, and the aggregator normalises all of them to 0..1 before weighting.
--   binary   : met / not met            -> raw_score 0 or 1,  max 1
--   scale_5  : 0-5 quality judgement    -> raw_score 0..5,    max 5
--   scale_10 : 0-10 fine-grained        -> raw_score 0..10,   max 10
--   numeric  : arbitrary bounded range defined per-criterion
create type scoring_type as enum ('binary', 'scale_5', 'scale_10', 'numeric');

-- ── Calls & ingestion ───────────────────────────────────────────────────────
create type call_source   as enum ('upload_text', 'upload_audio', 'api', 'seed');
create type call_channel  as enum ('phone', 'voip', 'chat', 'email');
create type call_direction as enum ('inbound', 'outbound');

-- Lifecycle of a call through the pipeline. Drives the ingestion UI progress bar.
create type call_status as enum (
  'pending',        -- row exists, nothing processed yet
  'transcribing',   -- audio -> text in flight
  'transcribed',    -- transcript + turns are ready
  'evaluating',     -- multi-agent pipeline running
  'evaluated',      -- scores available
  'failed'
);

create type speaker_role as enum ('agent', 'customer', 'system', 'unknown');

-- ── Evaluation pipeline ─────────────────────────────────────────────────────
create type evaluation_status as enum ('queued', 'running', 'completed', 'failed', 'cancelled');
create type agent_run_status  as enum ('pending', 'running', 'completed', 'failed', 'skipped');

-- ── Derived insight ─────────────────────────────────────────────────────────
create type sentiment_label as enum ('very_negative', 'negative', 'neutral', 'positive', 'very_positive');
create type risk_severity   as enum ('low', 'medium', 'high', 'critical');

-- ── Background jobs ─────────────────────────────────────────────────────────
create type job_type   as enum ('transcribe', 'evaluate', 'reevaluate', 'embed', 'recompute_aggregates');
create type job_status as enum ('queued', 'locked', 'running', 'completed', 'failed', 'dead');

-- ── Chatbot ─────────────────────────────────────────────────────────────────
create type chat_role as enum ('user', 'assistant', 'system');
