-- ============================================================================
-- 0008 · RAG Index & Manager Chatbot
-- ----------------------------------------------------------------------------
-- The chatbot has to answer two fundamentally different question shapes:
--
--   SEMANTIC   "show me calls where the customer mentioned billing issues"
--              -> vector similarity over transcript chunks
--   ANALYTICAL "which agents scored lowest on empathy this week?"
--              -> a SQL aggregation over criterion_scores; no amount of vector
--                 search can answer it, because the answer is not IN any
--                 single transcript
--
-- A pure-RAG chatbot fails the second category outright, which is why this
-- schema supports HYBRID retrieval: pgvector + the tsvector from migration 0004
-- + a constrained SQL path over the read-only views in migration 0009.
--
-- EMBEDDING DIMENSION = 768. gemini-embedding-2 defaults to 3072, but supports
-- output_dimensionality truncation (Matryoshka). 768 is chosen because:
--   * pgvector HNSW indexes cap at 2000 dimensions — 3072 cannot be indexed
--   * 768-d retrieval quality is within ~1% of 3072-d on retrieval benchmarks
--   * index size and query latency drop ~4x
-- ============================================================================

-- ── Chunked transcripts for retrieval ───────────────────────────────────────
create table transcript_chunks (
  id            uuid primary key default gen_random_uuid(),
  transcript_id uuid not null references transcripts(id) on delete cascade,
  call_id       uuid not null references calls(id) on delete cascade,

  chunk_index   integer not null,
  content       text not null,

  -- Chunks are cut on TURN BOUNDARIES, never mid-sentence, so a retrieved chunk
  -- is always a coherent slice of conversation. These columns let a chatbot
  -- answer point back at the exact turns, giving the same citation quality the
  -- score explanations have.
  turn_start    integer not null,
  turn_end      integer not null,
  char_start    integer not null,
  char_end      integer not null,

  embedding     vector(768),
  embedding_model text,
  token_count   integer,

  -- Denormalised filter columns. Copied here so a vector search can be
  -- pre-filtered ("only this team, only last month") inside the same index scan
  -- instead of retrieving 200 rows and joining them away afterwards.
  team_id          uuid references teams(id) on delete set null,
  support_agent_id uuid references support_agents(id) on delete set null,
  call_started_at  timestamptz,

  created_at    timestamptz not null default now(),
  unique (transcript_id, chunk_index)
);

-- HNSW over cosine distance. Built AFTER seeding in migration 0009's notes;
-- creating it on an empty table is fine and cheap.
create index idx_chunks_embedding on transcript_chunks
  using hnsw (embedding vector_cosine_ops)
  with (m = 16, ef_construction = 64);

create index idx_chunks_call on transcript_chunks(call_id, chunk_index);
create index idx_chunks_filters on transcript_chunks(team_id, call_started_at desc);

comment on table transcript_chunks is 'Vector index for the chatbot. Chunked on turn boundaries so retrieved passages are coherent and citable back to exact transcript turns.';
comment on column transcript_chunks.embedding is '768-d truncation of gemini-embedding-2 (native 3072). Chosen because pgvector HNSW cannot index beyond 2000 dimensions.';

-- ── Chat sessions & messages ────────────────────────────────────────────────
create table chat_sessions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references profiles(id) on delete cascade,
  title      text not null default 'New conversation',
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_chat_sessions_user on chat_sessions(user_id, updated_at desc);

create table chat_messages (
  id           uuid primary key default gen_random_uuid(),
  session_id   uuid not null references chat_sessions(id) on delete cascade,
  role         chat_role not null,
  content      text not null,

  -- ── Grounding trail ─────────────────────────────────────────────────────
  -- Every assistant answer records HOW it was produced. This is both an
  -- anti-hallucination measure (the UI renders "based on 4 calls" with links)
  -- and the evidence you need in a viva when asked "how do you know it isn't
  -- making this up?".
  -- [{"call_id": "...", "call_code": "CALL-0042", "excerpt": "...", "score": 0.82}]
  citations         jsonb not null default '[]'::jsonb,
  retrieved_chunks  uuid[] not null default '{}',
  -- The generated SQL for analytical questions, stored verbatim and shown in a
  -- collapsible "how I calculated this" panel.
  generated_sql     text,
  -- 'semantic' | 'analytical' | 'hybrid' — which retrieval path the router chose.
  retrieval_mode    text,

  model         text,
  input_tokens  integer not null default 0,
  output_tokens integer not null default 0,
  latency_ms    integer,
  error_message text,

  created_at    timestamptz not null default now()
);

create index idx_chat_messages_session on chat_messages(session_id, created_at);

comment on column chat_messages.generated_sql is 'The SQL the analytical path produced, surfaced in the UI. Auditable grounding, and a strong demo moment: the manager can see exactly how a number was derived.';

create trigger trg_chat_sessions_updated_at before update on chat_sessions
  for each row execute function set_updated_at();

-- ── Hybrid retrieval function ───────────────────────────────────────────────
-- Reciprocal Rank Fusion over the vector index and the tsvector index.
-- RRF is used instead of score-weighted blending because cosine distance and
-- ts_rank live on incomparable scales; fusing by RANK sidesteps the need to
-- normalise them against each other.
create or replace function search_transcript_chunks(
  p_query_embedding vector(768),
  p_query_text      text,
  p_match_count     integer default 10,
  p_team_id         uuid    default null,
  p_agent_id        uuid    default null,
  p_from            timestamptz default null,
  p_to              timestamptz default null
)
returns table (
  chunk_id    uuid,
  call_id     uuid,
  call_code   text,
  content     text,
  turn_start  integer,
  turn_end    integer,
  similarity  double precision,
  rrf_score   double precision
)
language sql
stable
as $$
  with filtered as (
    select tc.*
      from transcript_chunks tc
     where (p_team_id  is null or tc.team_id = p_team_id)
       and (p_agent_id is null or tc.support_agent_id = p_agent_id)
       and (p_from     is null or tc.call_started_at >= p_from)
       and (p_to       is null or tc.call_started_at <= p_to)
  ),
  semantic as (
    select f.id,
           1 - (f.embedding <=> p_query_embedding) as sim,
           row_number() over (order by f.embedding <=> p_query_embedding) as rnk
      from filtered f
     where f.embedding is not null
     limit greatest(p_match_count * 4, 40)
  ),
  keyword as (
    select f.id,
           row_number() over (
             order by ts_rank(to_tsvector('english', f.content),
                              plainto_tsquery('english', p_query_text)) desc
           ) as rnk
      from filtered f
     where p_query_text is not null
       and to_tsvector('english', f.content) @@ plainto_tsquery('english', p_query_text)
     limit greatest(p_match_count * 4, 40)
  ),
  -- k = 60 is the constant from the original RRF paper; it damps the influence
  -- of any single ranker's top hit so one list cannot dominate the fusion.
  fused as (
    select coalesce(s.id, k.id) as id,
           coalesce(1.0 / (60 + s.rnk), 0) + coalesce(1.0 / (60 + k.rnk), 0) as rrf,
           s.sim
      from semantic s
      full outer join keyword k on k.id = s.id
  )
  select tc.id,
         tc.call_id,
         c.call_code,
         tc.content,
         tc.turn_start,
         tc.turn_end,
         coalesce(f.sim, 0)::double precision,
         f.rrf::double precision
    from fused f
    join transcript_chunks tc on tc.id = f.id
    join calls c on c.id = tc.call_id
   order by f.rrf desc
   limit p_match_count;
$$;

comment on function search_transcript_chunks is 'Hybrid retrieval: pgvector similarity fused with full-text rank via Reciprocal Rank Fusion (k=60). Keyword recall catches plan names and error codes that embeddings blur away.';
