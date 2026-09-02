-- ============================================================================
-- 0012 · Drop corpus-common lexemes from keyword queries (crude IDF)
-- ----------------------------------------------------------------------------
-- Migration 0011 fixed the keyword arm by ORing the question's lexemes instead
-- of ANDing them. That restored recall but introduced the opposite problem:
--
--   "Show me CALLS where the CUSTOMER mentioned billing issues"
--
-- In a corpus of support calls, 'call' and 'custom' appear in nearly every
-- chunk — every greeting contains "thank you for calling" and "customer". ORing
-- them in means almost every chunk matches, and ts_rank has no notion of
-- document frequency, so opening greetings outranked the chunks that actually
-- discussed billing.
--
-- FIX: a materialised view of per-lexeme document frequency. Lexemes appearing
-- in more than 25% of chunks are dropped from the query — they carry no
-- discriminating signal. This is IDF in its crudest useful form.
--
-- English stopwords are already removed by the 'english' text search config;
-- this removes the corpus's OWN stopwords, which are domain-specific and
-- therefore cannot be known in advance.
-- ============================================================================

create materialized view transcript_lexeme_df as
select l.lexeme,
       count(*)::bigint                                            as doc_count,
       count(*)::numeric / nullif((select count(*) from transcript_chunks), 0) as df_ratio
  from transcript_chunks tc,
       lateral unnest(to_tsvector('english', tc.content)) l
 group by l.lexeme;

create unique index uq_lexeme_df on transcript_lexeme_df (lexeme);

comment on materialized view transcript_lexeme_df is
  'Document frequency per lexeme across transcript chunks. Used to drop corpus-common words ("call", "customer") from keyword queries, which ts_rank alone cannot down-weight.';

-- Refreshed by the embedding service after indexing. CONCURRENTLY needs the
-- unique index above and avoids blocking readers.
create or replace function refresh_lexeme_df()
returns void
language plpgsql
as $$
begin
  refresh materialized view concurrently transcript_lexeme_df;
exception
  when others then
    -- CONCURRENTLY fails on a never-populated view; fall back on first build.
    refresh materialized view transcript_lexeme_df;
end;
$$;

-- ── Search function, now IDF-filtered ───────────────────────────────────────
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
  query_terms as (
    select nullif(string_agg(quote_literal(l.lexeme), ' | '), '')::tsquery as tsq
      from unnest(to_tsvector('english', coalesce(p_query_text, ''))) l
      left join transcript_lexeme_df df on df.lexeme = l.lexeme
     -- Keep a lexeme when it is rare enough to discriminate, or absent from the
     -- corpus entirely (an unseen proper noun is highly informative).
     where coalesce(df.df_ratio, 0) <= 0.25
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
  fused as (
    select coalesce(s.id, k.id) as id,
           coalesce(1.0 / (60 + s.rnk), 0) + coalesce(1.0 / (60 + k.rnk), 0) as rrf,
           s.sim
      from semantic s
      full outer join keyword k on k.id = s.id
  )
  select tc.id, tc.call_id, c.call_code, tc.content, tc.turn_start, tc.turn_end,
         coalesce(f.sim, 0)::double precision,
         f.rrf::double precision
    from fused f
    join transcript_chunks tc on tc.id = f.id
    join calls c on c.id = tc.call_id
   order by f.rrf desc
   limit p_match_count;
$$;
