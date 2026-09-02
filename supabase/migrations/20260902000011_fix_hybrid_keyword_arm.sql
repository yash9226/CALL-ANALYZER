-- ============================================================================
-- 0011 · Fix the keyword arm of hybrid retrieval
-- ----------------------------------------------------------------------------
-- BUG: search_transcript_chunks() built its keyword query with
-- plainto_tsquery(), which ANDs every lexeme together. For a natural-language
-- question that is almost always zero matches:
--
--   plainto_tsquery('Show me calls where the customer mentioned billing issues')
--     -> 'show' & 'call' & 'custom' & 'mention' & 'bill' & 'issu'
--     -> 0 chunks
--   ...while 'billing' alone matches 77.
--
-- So the keyword half of the hybrid search silently contributed nothing, and
-- every result came from vector similarity alone. That defeats the entire
-- reason for hybrid retrieval: keyword recall is what catches exact tokens like
-- "FIBER-300" or "error 651" that embeddings blur away.
--
-- FIX: OR the lexemes instead. Ranking, not matching, decides relevance —
-- ts_rank already weights rare terms above common ones, and Reciprocal Rank
-- Fusion then combines that ranking with the vector ranking.
-- ============================================================================

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
  with
  -- Build an OR query from the question's lexemes. A question is a description
  -- of what to find, not a phrase that must appear verbatim.
  query_terms as (
    select nullif(
             (select string_agg(quote_literal(lexeme), ' | ')
                from unnest(to_tsvector('english', coalesce(p_query_text, '')))),
             ''
           )::tsquery as tsq
  ),
  filtered as (
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
             order by ts_rank(to_tsvector('english', f.content), q.tsq) desc
           ) as rnk
      from filtered f, query_terms q
     where q.tsq is not null
       and to_tsvector('english', f.content) @@ q.tsq
     limit greatest(p_match_count * 4, 40)
  ),
  -- k = 60 is the constant from the original RRF paper. It damps any single
  -- ranker's top hit so one list cannot dominate the fusion.
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

comment on function search_transcript_chunks is 'Hybrid retrieval: pgvector similarity fused with full-text rank via Reciprocal Rank Fusion (k=60). The keyword arm ORs the question''s lexemes — ANDing them matched nothing for natural-language questions and silently disabled half the search.';
