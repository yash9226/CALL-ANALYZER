-- ============================================================================
-- 0004 · Calls, Transcripts & Turns
-- ----------------------------------------------------------------------------
-- KEY DESIGN DECISION — transcripts are stored TWICE, deliberately:
--
--   transcripts.full_text   : the flattened conversation, one string. This is
--                             what gets sent to the LLM and what full-text
--                             search runs against.
--   transcript_turns        : the same conversation exploded into speaker turns,
--                             each carrying char_start/char_end offsets INTO
--                             full_text.
--
-- WHY: the explainability requirement says every score must cite the exact
-- excerpt that justified it. If we only stored a blob, we would have to string-
-- match the LLM's quoted text back into the transcript to highlight it — and
-- LLMs paraphrase, normalise whitespace, and fix typos, so that match fails
-- constantly. Instead the scoring agent cites a TURN INDEX; we look up the
-- turn's stored offsets and highlight an exact character range. Cheap, exact,
-- and impossible to get wrong.
--
-- Turn-level storage also gives us the per-turn sentiment timeline and clean
-- semantic chunk boundaries for the RAG index, for free.
-- ============================================================================

-- ── Ingestion batches ───────────────────────────────────────────────────────
-- One row per CSV/JSON upload, so a partially-failed import is diagnosable
-- instead of mysterious.
create table ingestion_batches (
  id             uuid primary key default gen_random_uuid(),
  filename       text,
  source         call_source not null default 'upload_text',
  total_rows     integer not null default 0,
  succeeded      integer not null default 0,
  failed         integer not null default 0,
  status         text not null default 'processing',   -- processing | completed | failed
  error_log      jsonb not null default '[]'::jsonb,   -- [{row: 12, error: "..."}]
  uploaded_by    uuid references profiles(id) on delete set null,
  created_at     timestamptz not null default now(),
  completed_at   timestamptz
);

comment on table ingestion_batches is 'Audit trail for bulk uploads. error_log keeps per-row failures so a 500-row CSV with 3 bad rows imports 497 calls instead of failing wholesale.';

-- ── Calls ───────────────────────────────────────────────────────────────────
create table calls (
  id               uuid primary key default gen_random_uuid(),
  -- The externally-meaningful call id from the telephony system. Unique so a
  -- re-uploaded CSV updates rather than duplicates.
  call_code        text not null unique,
  support_agent_id uuid references support_agents(id) on delete set null,
  -- Denormalised from support_agents at ingest time. Intentional: an agent may
  -- change teams, and a call must stay attributed to the team that handled it.
  team_id          uuid references teams(id) on delete set null,

  customer_ref     text,                                  -- pseudonymous customer id
  direction        call_direction not null default 'inbound',
  channel          call_channel   not null default 'phone',
  source           call_source    not null default 'seed',
  language         text not null default 'en',

  started_at       timestamptz not null,
  ended_at         timestamptz,
  duration_seconds integer check (duration_seconds is null or duration_seconds >= 0),

  -- Populated only when source = 'upload_audio'. Points at Supabase Storage.
  audio_path       text,
  audio_mime       text,
  audio_bytes      bigint,

  status           call_status not null default 'pending',
  error_message    text,

  batch_id         uuid references ingestion_batches(id) on delete set null,
  -- Free-form passthrough for anything the telephony export carries that we did
  -- not model (queue name, IVR path, disposition code, ...). Keeps ingestion
  -- lossless without schema churn.
  metadata         jsonb not null default '{}'::jsonb,

  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index idx_calls_agent       on calls(support_agent_id);
create index idx_calls_team        on calls(team_id);
create index idx_calls_started     on calls(started_at desc);
create index idx_calls_status      on calls(status);
create index idx_calls_batch       on calls(batch_id);
-- Composite index for the dashboard's most common query shape:
-- "calls for team X between date A and B, newest first".
create index idx_calls_team_started on calls(team_id, started_at desc);

comment on column calls.team_id is 'Snapshot of the handling team at ingest time — deliberately NOT derived from support_agents.team_id at read time, so historical attribution survives agent transfers.';

-- ── Transcripts (one per call) ──────────────────────────────────────────────
create table transcripts (
  id                     uuid primary key default gen_random_uuid(),
  call_id                uuid not null unique references calls(id) on delete cascade,

  -- The canonical text. transcript_turns offsets index into THIS string, so it
  -- must never be mutated after turns are written.
  full_text              text not null,
  word_count             integer not null default 0,
  turn_count             integer not null default 0,
  language               text not null default 'en',

  -- Provenance: was this typed in, uploaded as text, or machine-transcribed?
  transcription_provider text,          -- 'gemini' | 'whisper' | 'manual' | 'import'
  transcription_model    text,          -- e.g. 'gemini-3.5-transcribe'
  transcription_confidence numeric(4,3) check (transcription_confidence is null
                                          or transcription_confidence between 0 and 1),

  -- Generated tsvector for keyword search. The RAG chatbot uses this alongside
  -- vector similarity — hybrid retrieval beats pure semantic search on proper
  -- nouns, error codes, and plan names, which is exactly what managers ask about.
  search_vector          tsvector generated always as (to_tsvector('english', full_text)) stored,

  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);

create index idx_transcripts_search on transcripts using gin(search_vector);
create index idx_transcripts_trgm   on transcripts using gin(full_text gin_trgm_ops);

comment on column transcripts.full_text is 'IMMUTABLE once transcript_turns exist — turn char offsets point into this exact string. Re-transcription must replace the transcript row and its turns together.';
comment on column transcripts.search_vector is 'Keyword half of the chatbot''s hybrid retrieval. Semantic search alone misses exact tokens like "plan FIBER-300" or "error 651".';

-- ── Transcript turns ────────────────────────────────────────────────────────
create table transcript_turns (
  id            uuid primary key default gen_random_uuid(),
  transcript_id uuid not null references transcripts(id) on delete cascade,
  -- Denormalised for query convenience: nearly every read filters by call.
  call_id       uuid not null references calls(id) on delete cascade,

  turn_index    integer not null,           -- 0-based, conversation order
  speaker       speaker_role not null default 'unknown',
  speaker_label text,                       -- raw label from the source, e.g. 'AGENT_01'
  text          text not null,

  -- Audio timing, present only for machine-transcribed calls. Powers the
  -- sentiment timeline's x-axis when available; falls back to turn_index.
  start_ms      integer,
  end_ms        integer,

  -- ★ The explainability anchor. Byte-exact range into transcripts.full_text.
  --   UI highlighting is a substring slice, never a fuzzy search.
  char_start    integer not null,
  char_end      integer not null,

  created_at    timestamptz not null default now(),

  unique (transcript_id, turn_index),
  constraint turn_char_range_valid check (char_end > char_start),
  constraint turn_ms_range_valid   check (end_ms is null or start_ms is null or end_ms >= start_ms)
);

create index idx_turns_call  on transcript_turns(call_id, turn_index);
create index idx_turns_speaker on transcript_turns(call_id, speaker);

comment on table transcript_turns is 'Speaker-diarised turns. char_start/char_end make score citations exact: the scoring agent returns a turn_index, the API resolves offsets, the UI highlights that literal range in full_text.';

create trigger trg_calls_updated_at       before update on calls       for each row execute function set_updated_at();
create trigger trg_transcripts_updated_at before update on transcripts for each row execute function set_updated_at();
