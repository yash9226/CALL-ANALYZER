-- ============================================================================
-- TEST · Scoring Engine
-- ----------------------------------------------------------------------------
-- Verifies the four behaviours the dynamic framework promises:
--   T1  weighted rollup produces the arithmetically correct percentage
--   T2  a not-applicable criterion is REMOVED from the denominator, not zeroed
--   T3  a failed critical criterion forces the whole call to 0 with a reason
--   T4  re-weighting the rubric re-scores history with ZERO LLM calls
--
-- Run: psql "$PGURL" -f supabase/tests/scoring_engine_test.sql
-- Every check raises an exception on failure, so a clean run means all pass.
-- ============================================================================

\set ON_ERROR_STOP on

begin;

do $$
declare
  v_call  uuid;
  v_tr    uuid;
  v_eval  uuid;
  v_fw    uuid;
  v_fw2   uuid;
  v_pct   numeric;
  v_grade text;
  v_af    boolean;
  v_res   record;
  v_text  text := 'Agent: Thank you for calling Northwind Broadband, my name is Priya, and this call is recorded for quality purposes.
Customer: Hi, I have been charged twice for my FIBER-300 plan this month and I am really frustrated.
Agent: I completely understand how frustrating a duplicate charge is. Let me pull up your account and check that right away.
Customer: Thank you, that would help a lot.';
begin
  select id into v_fw from framework_versions where status = 'published';

  -- ── Fixture: one call, one transcript, four turns ────────────────────────
  insert into calls (call_code, support_agent_id, team_id, started_at, duration_seconds, status, source)
  values ('CALL-TEST-001',
          '22222222-2222-4222-8222-000000000001',
          '11111111-1111-4111-8111-000000000001',
          now() - interval '2 days', 260, 'evaluated', 'seed')
  returning id into v_call;

  insert into transcripts (call_id, full_text, word_count, turn_count, transcription_provider)
  values (v_call, v_text, array_length(string_to_array(v_text, ' '), 1), 4, 'manual')
  returning id into v_tr;

  insert into transcript_turns (transcript_id, call_id, turn_index, speaker, text, char_start, char_end)
  select v_tr, v_call, i - 1,
         (case when i % 2 = 1 then 'agent' else 'customer' end)::speaker_role,
         line,
         1, 2   -- placeholder offsets; the real ingester computes exact ranges
    from (select row_number() over () as i, line
            from unnest(string_to_array(v_text, E'\n')) as line) t;

  insert into evaluations (call_id, framework_version_id, status, model_used, trigger_reason)
  values (v_call, v_fw, 'completed', 'test-fixture', 'initial')
  returning id into v_eval;

  -- ── T1 · Uniform 80% across every criterion should roll up to exactly 80 ──
  -- If the weighting maths is right, weights become irrelevant when every leaf
  -- scores the same fraction. This isolates rollup correctness from weighting.
  insert into criterion_scores (evaluation_id, criterion_id, criterion_code, criterion_name,
                                subsection_code, section_code, scoring_type, weight_snapshot,
                                is_critical_snapshot, raw_score, max_score, normalized,
                                confidence, is_applicable, reasoning)
  select v_eval, c.id, c.code, c.name, ss.code, s.code, c.scoring_type, c.weight,
         c.is_critical, c.max_score * 0.8, c.max_score, 0.8, 0.9, true, 'test fixture'
    from criteria c
    join subsections ss on ss.id = c.subsection_id
    join sections s on s.id = ss.section_id
   where s.framework_version_id = v_fw;

  select r.score_percentage, r.grade into v_pct, v_grade
    from recompute_evaluation_scores(v_eval) r;

  if abs(v_pct - 80) > 0.001 then
    raise exception 'T1 FAILED: expected 80.000, got %', v_pct;
  end if;
  if v_grade <> 'B' then
    raise exception 'T1 FAILED: expected grade B, got %', v_grade;
  end if;
  raise notice 'T1 PASS · uniform 80%% rolls up to %  (grade %)', v_pct, v_grade;

  -- ── T2 · N/A must renormalise, not zero ─────────────────────────────────
  -- OPEN_SETUP holds two criteria: EXPECTATION_SETTING (55) and HOLD_ETIQUETTE
  -- (45). Score expectation-setting 1.0 and mark hold etiquette N/A. The
  -- subsection must become 1.0 (the surviving criterion takes the full weight),
  -- NOT 0.55 (which is what treating N/A as zero would produce).
  update criterion_scores
     set is_applicable = false, raw_score = null, normalized = null, na_reason = 'no hold occurred'
   where evaluation_id = v_eval and criterion_code = 'HOLD_ETIQUETTE';

  update criterion_scores
     set raw_score = max_score, normalized = 1.0
   where evaluation_id = v_eval and criterion_code = 'EXPECTATION_SETTING';

  perform recompute_evaluation_scores(v_eval);

  select normalized into v_pct from subsection_scores
   where evaluation_id = v_eval and subsection_code = 'OPEN_SETUP';

  if abs(v_pct - 1.0) > 0.0001 then
    raise exception 'T2 FAILED: N/A was not excluded from the denominator. OPEN_SETUP = % (expected 1.0; 0.55 means N/A was scored as zero)', v_pct;
  end if;
  raise notice 'T2 PASS · N/A criterion excluded from denominator, OPEN_SETUP = %', v_pct;

  -- ── T3 · Critical failure forces the whole call to zero ─────────────────
  update criterion_scores
     set raw_score = 0, normalized = 0
   where evaluation_id = v_eval and criterion_code = 'RECORDING_DISCLOSURE';

  select r.score_percentage into v_pct from recompute_evaluation_scores(v_eval) r;
  select auto_fail_triggered into v_af from evaluations where id = v_eval;

  if v_pct <> 0 or not v_af then
    raise exception 'T3 FAILED: critical failure did not auto-fail. pct=%, flag=%', v_pct, v_af;
  end if;
  raise notice 'T3 PASS · critical failure -> score %, auto_fail=%', v_pct, v_af;

  -- Restore for T4.
  update criterion_scores
     set raw_score = max_score * 0.8, normalized = 0.8
   where evaluation_id = v_eval and criterion_code in ('RECORDING_DISCLOSURE', 'EXPECTATION_SETTING');
  update criterion_scores
     set is_applicable = true, raw_score = max_score * 0.8, normalized = 0.8, na_reason = null
   where evaluation_id = v_eval and criterion_code = 'HOLD_ETIQUETTE';
  perform recompute_evaluation_scores(v_eval);

  -- ── T4 · Re-weighting re-scores history with no LLM involvement ─────────
  -- Clone v1, make RESOLUTION dominant (70) and shrink the rest, publish, and
  -- re-project. Then push every RESOLUTION criterion to 1.0 and everything else
  -- to 0.5: under v1 weights that is 0.5*0.7 + 1.0*0.3 = 0.65; under v2 weights
  -- it must become 0.5*0.3 + 1.0*0.7 = 0.85. Same criterion scores, different
  -- rubric, zero transcript re-reads.
  v_fw2 := clone_framework_version(v_fw, 'Resolution-Weighted Rubric v2', null);

  update sections set weight = 70 where framework_version_id = v_fw2 and code = 'RESOLUTION';
  update sections set weight = 10 where framework_version_id = v_fw2 and code in ('OPENING', 'COMMUNICATION', 'COMPLIANCE');
  update sections set weight = 0  where framework_version_id = v_fw2 and code = 'CLOSING';

  perform publish_framework_version(v_fw2, null);

  update criterion_scores
     set raw_score = case when section_code = 'RESOLUTION' then max_score else max_score * 0.5 end,
         normalized = case when section_code = 'RESOLUTION' then 1.0 else 0.5 end
   where evaluation_id = v_eval;

  -- Recompute under the OLD rubric first, to establish the baseline.
  select r.score_percentage into v_pct from recompute_evaluation_scores(v_eval, v_fw) r;
  if abs(v_pct - 65) > 0.01 then
    raise exception 'T4a FAILED: expected 65.000 under v1 weights, got %', v_pct;
  end if;
  raise notice 'T4a PASS · under v1 weights (RESOLUTION=30%%) score = %', v_pct;

  -- Now re-project the SAME criterion scores onto v2. No LLM, no re-reading.
  select r.score_percentage, r.missing_criteria into v_res
    from recompute_evaluation_scores(v_eval, v_fw2) r;

  select r.score_percentage, r.grade into v_pct, v_grade
    from recompute_evaluation_scores(v_eval, v_fw2) r;

  if abs(v_pct - 85) > 0.01 then
    raise exception 'T4b FAILED: expected 85.000 under v2 weights, got %', v_pct;
  end if;
  raise notice 'T4b PASS · re-weighted to v2 (RESOLUTION=70%%) score = % (grade %) — 0 LLM calls', v_pct, v_grade;

  raise notice '───────────────────────────────────────────────';
  raise notice 'ALL SCORING ENGINE TESTS PASSED';
end $$;

rollback;   -- leave the database exactly as it was
