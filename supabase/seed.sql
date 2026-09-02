-- ============================================================================
-- SEED · Teams, Support Agents & Framework v1
-- ----------------------------------------------------------------------------
-- Run automatically by `supabase db reset`. Idempotent: safe to re-run.
--
-- Domain: consumer ISP / telecom support (billing, technical, retention).
-- The rubric below is modelled on how real contact-centre QA scorecards are
-- built — weighted sections, a couple of auto-fail compliance items, and
-- N/A-able criteria that do not apply to every call.
--
-- IMPORTANT ORDERING: the tree is inserted while the version is still 'draft',
-- because the immutability trigger from migration 0003 refuses writes to a
-- published version. publish_framework_version() is called last, and it will
-- itself refuse to run unless every level's weights sum to 100.
-- ============================================================================

-- ── Teams ───────────────────────────────────────────────────────────────────
insert into teams (id, code, name, description) values
  ('11111111-1111-4111-8111-000000000001', 'BILLING',   'Billing & Payments',
   'Invoice disputes, refunds, plan pricing, payment failures'),
  ('11111111-1111-4111-8111-000000000002', 'TECH',      'Technical Support',
   'Connectivity faults, router configuration, speed complaints, outages'),
  ('11111111-1111-4111-8111-000000000003', 'RETENTION', 'Retention & Loyalty',
   'Cancellation requests, win-back offers, contract renewals')
on conflict (code) do nothing;

-- ── Support agents ──────────────────────────────────────────────────────────
-- Nine agents, three per team, with deliberately varied tenure so the dashboard
-- can show a believable spread rather than nine identical performers.
insert into support_agents (id, agent_code, full_name, email, team_id, hired_at, is_active) values
  ('22222222-2222-4222-8222-000000000001', 'AGT-1001', 'Priya Nair',      'priya.nair@example.com',   '11111111-1111-4111-8111-000000000001', '2023-02-14', true),
  ('22222222-2222-4222-8222-000000000002', 'AGT-1002', 'Rahul Menon',     'rahul.menon@example.com',  '11111111-1111-4111-8111-000000000001', '2024-07-01', true),
  ('22222222-2222-4222-8222-000000000003', 'AGT-1003', 'Sneha Kulkarni',  'sneha.k@example.com',      '11111111-1111-4111-8111-000000000001', '2022-09-19', true),
  ('22222222-2222-4222-8222-000000000004', 'AGT-1004', 'Arjun Deshmukh',  'arjun.d@example.com',      '11111111-1111-4111-8111-000000000002', '2021-11-08', true),
  ('22222222-2222-4222-8222-000000000005', 'AGT-1005', 'Fatima Sheikh',   'fatima.s@example.com',     '11111111-1111-4111-8111-000000000002', '2024-01-22', true),
  ('22222222-2222-4222-8222-000000000006', 'AGT-1006', 'Vikram Iyer',     'vikram.iyer@example.com',  '11111111-1111-4111-8111-000000000002', '2023-06-05', true),
  ('22222222-2222-4222-8222-000000000007', 'AGT-1007', 'Ananya Bose',     'ananya.bose@example.com',  '11111111-1111-4111-8111-000000000003', '2022-03-30', true),
  ('22222222-2222-4222-8222-000000000008', 'AGT-1008', 'Karan Malhotra',  'karan.m@example.com',      '11111111-1111-4111-8111-000000000003', '2025-01-13', true),
  ('22222222-2222-4222-8222-000000000009', 'AGT-1009', 'Meera Raghavan',  'meera.r@example.com',      '11111111-1111-4111-8111-000000000003', '2020-08-17', true)
on conflict (agent_code) do nothing;

-- ============================================================================
-- FRAMEWORK v1 — "Consumer Support Quality Rubric 2026"
-- 5 sections · 12 sub-sections · 28 criteria
-- ============================================================================
do $$
declare
  v_fw uuid;
  s_open uuid; s_comm uuid; s_res uuid; s_comp uuid; s_close uuid;
  ss uuid;
begin
  -- Skip entirely if a framework already exists (keeps the seed idempotent).
  if exists (select 1 from framework_versions) then
    raise notice 'Framework already seeded, skipping.';
    return;
  end if;

  insert into framework_versions (version_no, name, description, status, notes)
  values (1, 'Consumer Support Quality Rubric 2026',
          'Baseline scorecard for consumer ISP support calls across billing, technical and retention queues.',
          'draft',
          'Initial published rubric. Auto-fail items: call-recording disclosure and identity verification.')
  returning id into v_fw;

  -- ══ SECTION 1 · OPENING (15%) ════════════════════════════════════════════
  insert into sections (framework_version_id, code, name, description, weight, display_order)
  values (v_fw, 'OPENING', 'Opening & Greeting',
          'How the agent establishes the call: brand identity, purpose capture, and expectation setting.',
          15, 1)
  returning id into s_open;

    insert into subsections (section_id, code, name, description, weight, display_order)
    values (s_open, 'OPEN_IDENT', 'Professional Introduction',
            'Branded greeting, capturing why the customer called, and opening tone.', 55, 1)
    returning id into ss;

      insert into criteria (subsection_id, code, name, description, weight, scoring_type, max_score, guidance, display_order) values
      (ss, 'GREETING_BRANDED', 'Branded greeting with agent name', 'Agent opens with the company name and their own name.', 40, 'scale_5', 5,
       'Score 5 when the agent states BOTH the company name and their own first name within the first two turns, in a warm tone. Score 3 for one of the two, or both delivered flatly/rushed. Score 0 when the agent launches straight into the issue with no introduction.', 1),
      (ss, 'PURPOSE_CAPTURE', 'Captures reason for the call', 'Agent invites and correctly registers the customer''s reason for calling.', 35, 'scale_5', 5,
       'Score 5 when the agent explicitly asks how they can help AND demonstrably registers the answer (references it later). Score 3 if asked but the stated reason is never acknowledged. Score 0 if the agent assumes the reason without asking.', 2),
      (ss, 'TONE_OPENING', 'Opening tone and energy', 'Warmth and attentiveness in the first exchanges.', 25, 'scale_5', 5,
       'Judge only the first three agent turns. Score 5 for warm, unhurried, attentive language. Score 3 for neutral/scripted delivery. Score 0 for curt, dismissive, or audibly disinterested phrasing.', 3);

    insert into subsections (section_id, code, name, description, weight, display_order)
    values (s_open, 'OPEN_SETUP', 'Call Setup', 'Setting expectations and managing holds professionally.', 45, 2)
    returning id into ss;

      insert into criteria (subsection_id, code, name, description, weight, scoring_type, max_score, guidance, allow_na, display_order) values
      (ss, 'EXPECTATION_SETTING', 'Sets expectations for the call', 'Agent explains what they are about to do and roughly how long it will take.', 55, 'scale_5', 5,
       'Score 5 when the agent states what they will do next AND gives a time indication ("this will take about two minutes"). Score 3 for one without the other. Score 0 when the customer is left in silence with no explanation.', false, 1),
      (ss, 'HOLD_ETIQUETTE', 'Hold etiquette', 'Asks permission before holding, thanks the customer on return, keeps holds short.', 45, 'scale_5', 5,
       'MARK NOT APPLICABLE if the agent never places the customer on hold. Otherwise: score 5 when permission is requested, a reason is given, and the customer is thanked on return. Score 0 for an abrupt hold with no warning.', true, 2);

  -- ══ SECTION 2 · COMMUNICATION (25%) ══════════════════════════════════════
  insert into sections (framework_version_id, code, name, description, weight, display_order)
  values (v_fw, 'COMMUNICATION', 'Communication Skills',
          'Clarity of language, quality of listening, and demonstrated empathy.', 25, 2)
  returning id into s_comm;

    insert into subsections (section_id, code, name, description, weight, display_order)
    values (s_comm, 'COMM_CLARITY', 'Clarity & Language', 'Plain, jargon-free, well-paced explanation.', 35, 1)
    returning id into ss;

      insert into criteria (subsection_id, code, name, description, weight, scoring_type, max_score, guidance, display_order) values
      (ss, 'PLAIN_LANGUAGE', 'Uses plain, understandable language', 'Explanations a non-technical customer can follow.', 40, 'scale_5', 5,
       'Score 5 when every explanation is immediately understandable to a layperson. Score 3 when mostly clear but occasionally dense. Score 0 when the customer expresses confusion and the agent repeats the same wording instead of rephrasing.', 1),
      (ss, 'JARGON_AVOIDANCE', 'Avoids or explains jargon', 'Technical or billing terms are defined when used.', 30, 'scale_5', 5,
       'Score 5 when no unexplained jargon appears, or every technical term is defined in passing. Score 3 for jargon that is technically explained but still heavy. Score 0 for repeated unexplained terms like "CPE", "PPPoE session", "proration", "OLT".', 2),
      (ss, 'PACE_AND_CLARITY', 'Appropriate pace and structure', 'Information delivered in digestible order, not a monologue.', 30, 'scale_5', 5,
       'Score 5 for well-structured, chunked explanations with natural checkpoints. Score 3 for acceptable but unstructured delivery. Score 0 for long uninterrupted monologues that give the customer no opening.', 3);

    insert into subsections (section_id, code, name, description, weight, display_order)
    values (s_comm, 'COMM_LISTENING', 'Active Listening', 'Letting the customer speak, confirming understanding, probing well.', 35, 2)
    returning id into ss;

      insert into criteria (subsection_id, code, name, description, weight, scoring_type, max_score, guidance, display_order) values
      (ss, 'NO_INTERRUPTION', 'Does not interrupt the customer', 'Customer is allowed to complete their thoughts.', 40, 'scale_5', 5,
       'Score 5 when no interruptions occur. Score 3 for one interruption that is recovered gracefully. Score 0 for repeated talking over the customer or cutting off an explanation mid-sentence.', 1),
      (ss, 'PARAPHRASE_CONFIRM', 'Paraphrases to confirm understanding', 'Agent plays back the problem in their own words.', 35, 'scale_5', 5,
       'Score 5 when the agent restates the issue in their own words and the customer confirms. Score 3 for a bare "okay, I understand" with no restatement. Score 0 when the agent proceeds on a demonstrably wrong understanding.', 2),
      (ss, 'PROBING_QUESTIONS', 'Asks effective probing questions', 'Questions that genuinely narrow the problem.', 25, 'scale_5', 5,
       'Score 5 for targeted diagnostic questions that measurably narrow the cause. Score 3 for generic questions that gather little. Score 0 when no questions are asked and the agent guesses.', 3);

    insert into subsections (section_id, code, name, description, weight, display_order)
    values (s_comm, 'COMM_EMPATHY', 'Empathy & Tone', 'Recognising and responding to how the customer feels.', 30, 3)
    returning id into ss;

      insert into criteria (subsection_id, code, name, description, weight, scoring_type, max_score, guidance, display_order) values
      (ss, 'ACKNOWLEDGE_EMOTION', 'Acknowledges customer emotion', 'Names or reflects the customer''s frustration or worry.', 45, 'scale_5', 5,
       'Score 5 when the agent explicitly names the emotion ("I can hear how frustrating this has been"). Score 3 for a generic apology with no emotional recognition. Score 0 when clear frustration is ignored and the agent ploughs on with process.', 1),
      (ss, 'EMPATHY_STATEMENT', 'Uses genuine empathy statements', 'Empathy that fits the moment rather than a recited script.', 30, 'scale_5', 5,
       'Score 5 for specific, situation-fitted empathy. Score 3 for correct but obviously scripted phrases repeated verbatim. Score 0 for none at all.', 2),
      (ss, 'POSITIVE_TONE', 'Maintains a positive, professional tone', 'Composure held even under pressure.', 25, 'scale_5', 5,
       'Score 5 for consistently professional and constructive language throughout. Score 3 for a brief lapse into defensiveness. Score 0 for sarcasm, blame-shifting to the customer, or audible irritation.', 3);

  -- ══ SECTION 3 · RESOLUTION (30%) ═════════════════════════════════════════
  insert into sections (framework_version_id, code, name, description, weight, display_order)
  values (v_fw, 'RESOLUTION', 'Problem Resolution',
          'Diagnosis quality, accuracy of the solution, and follow-through. The heaviest section: this is what the customer actually called for.',
          30, 3)
  returning id into s_res;

    insert into subsections (section_id, code, name, description, weight, display_order)
    values (s_res, 'RES_DIAGNOSIS', 'Diagnosis', 'Establishing the real cause before acting.', 30, 1)
    returning id into ss;

      insert into criteria (subsection_id, code, name, description, weight, scoring_type, max_score, guidance, display_order) values
      (ss, 'ROOT_CAUSE_ID', 'Identifies the root cause', 'Gets to the underlying cause rather than the symptom.', 55, 'scale_5', 5,
       'Score 5 when the agent identifies and states the underlying cause. Score 3 for treating the symptom only. Score 0 for a wrong diagnosis, or none at all.', 1),
      (ss, 'ACCOUNT_REVIEW', 'Reviews account context', 'Checks history, plan, and prior tickets before advising.', 45, 'scale_5', 5,
       'Score 5 when the agent references specific account details (plan name, recent invoice, prior ticket). Score 3 for a cursory look. Score 0 when advice is given with no account context at all.', 2);

    insert into subsections (section_id, code, name, description, weight, display_order)
    values (s_res, 'RES_SOLUTION', 'Solution Delivery', 'Correctness and usability of the fix offered.', 45, 2)
    returning id into ss;

      insert into criteria (subsection_id, code, name, description, weight, scoring_type, max_score, guidance, display_order) values
      (ss, 'SOLUTION_ACCURACY', 'Provides an accurate solution', 'The fix is correct and matches company policy.', 45, 'scale_5', 5,
       'Score 5 for a correct, policy-compliant solution. Score 3 for a partially correct or incomplete one. Score 0 for factually wrong information or a fix that cannot work.', 1),
      (ss, 'STEP_GUIDANCE', 'Gives clear step-by-step guidance', 'Customer-executable instructions.', 30, 'scale_5', 5,
       'Score 5 for numbered, sequential, checkable steps with confirmation between them. Score 3 for steps given all at once. Score 0 for vague direction like "just reset it".', 2),
      (ss, 'FIRST_CONTACT_RESOLUTION', 'Resolved on first contact', 'No callback, transfer, or follow-up needed.', 25, 'binary', 1,
       'Score 1 when the issue is fully resolved within this call. Score 0 when a callback, transfer, field visit, or follow-up is required. A legitimate escalation still scores 0 here — that is measured, not punished, and CORRECT_ESCALATION covers whether it was handled well.', 3);

    insert into subsections (section_id, code, name, description, weight, display_order)
    values (s_res, 'RES_FOLLOWTHROUGH', 'Follow-through', 'Closing the loop before the call ends.', 25, 3)
    returning id into ss;

      insert into criteria (subsection_id, code, name, description, weight, scoring_type, max_score, guidance, display_order) values
      (ss, 'CONFIRM_RESOLUTION', 'Confirms the issue is resolved', 'Explicitly checks the customer is satisfied.', 55, 'scale_5', 5,
       'Score 5 when the agent explicitly asks whether the issue is resolved AND the customer confirms. Score 3 for an assumed resolution. Score 0 when the call ends with the problem visibly open.', 1),
      (ss, 'OFFER_ADDITIONAL_HELP', 'Offers additional assistance', 'Asks whether anything else is needed.', 45, 'binary', 1,
       'Score 1 when the agent asks some form of "is there anything else I can help with". Score 0 otherwise.', 2);

  -- ══ SECTION 4 · COMPLIANCE (20%) ═════════════════════════════════════════
  insert into sections (framework_version_id, code, name, description, weight, display_order)
  values (v_fw, 'COMPLIANCE', 'Compliance & Policy',
          'Regulatory disclosures and adherence to company policy. Contains the two auto-fail criteria.',
          20, 4)
  returning id into s_comp;

    insert into subsections (section_id, code, name, description, weight, display_order)
    values (s_comp, 'COMP_DISCLOSURE', 'Mandatory Disclosures', 'Legally required statements. Two of these are auto-fail.', 55, 1)
    returning id into ss;

      insert into criteria (subsection_id, code, name, description, weight, scoring_type, max_score, guidance, is_critical, allow_na, display_order) values
      (ss, 'RECORDING_DISCLOSURE', 'Discloses call recording', 'States that the call is recorded, before collecting any personal data.', 40, 'binary', 1,
       'AUTO-FAIL CRITERION. Score 1 only if the agent states the call is recorded or monitored, before any personal data is collected. Score 0 for any other case, including a disclosure that arrives after data collection has begun.', true, false, 1),
      (ss, 'IDENTITY_VERIFICATION', 'Verifies customer identity', 'Confirms identity before discussing or changing account details.', 40, 'binary', 1,
       'AUTO-FAIL CRITERION. Score 1 when the agent verifies at least two identifiers (registered name, address, account number, last payment, OTP) BEFORE disclosing or modifying account information. Score 0 if verification is skipped, incomplete, or performed after account details were already revealed.', true, false, 2),
      (ss, 'DATA_PRIVACY_ADHERENCE', 'Handles personal data appropriately', 'No unnecessary collection or careless repetition of sensitive data.', 20, 'binary', 1,
       'Score 1 when personal data handling is appropriate throughout. Score 0 if the agent reads back full card numbers, asks for a password, or requests data irrelevant to the issue.', false, false, 3);

    insert into subsections (section_id, code, name, description, weight, display_order)
    values (s_comp, 'COMP_POLICY', 'Policy Adherence', 'Staying inside what the agent is actually authorised to do.', 45, 2)
    returning id into ss;

      insert into criteria (subsection_id, code, name, description, weight, scoring_type, max_score, guidance, allow_na, display_order) values
      (ss, 'NO_UNAUTHORIZED_PROMISE', 'Makes no unauthorised promises', 'No commitments outside the agent''s authority.', 40, 'binary', 1,
       'Score 1 when every commitment made is within normal agent authority. Score 0 for guaranteed refunds, waivers, credits, compensation, or fix timelines the agent cannot actually control ("I guarantee it will be fixed by tomorrow").', false, 1),
      (ss, 'CORRECT_ESCALATION', 'Follows the correct escalation path', 'Escalates to the right place at the right time.', 30, 'scale_5', 5,
       'MARK NOT APPLICABLE when no escalation was needed or requested. Otherwise: score 5 when escalated to the correct team with a full context handover. Score 3 for a correct escalation with a thin handover. Score 0 for a blind transfer, or refusing a warranted escalation.', true, 2),
      (ss, 'ACCURATE_PRICING_INFO', 'States pricing and terms accurately', 'Charges, proration and contract terms stated correctly.', 30, 'scale_5', 5,
       'MARK NOT APPLICABLE if no pricing is discussed. Otherwise: score 5 for complete and accurate figures including taxes and proration. Score 3 for correct but incomplete. Score 0 for stating a figure that is wrong or omitting a material charge.', true, 3);

  -- ══ SECTION 5 · CLOSING (10%) ════════════════════════════════════════════
  insert into sections (framework_version_id, code, name, description, weight, display_order)
  values (v_fw, 'CLOSING', 'Call Closing',
          'Summary, next steps, and a courteous branded close.', 10, 5)
  returning id into s_close;

    insert into subsections (section_id, code, name, description, weight, display_order)
    values (s_close, 'CLOSE_WRAPUP', 'Call Wrap-up', 'Leaving the customer certain about what happens next.', 60, 1)
    returning id into ss;

      insert into criteria (subsection_id, code, name, description, weight, scoring_type, max_score, guidance, display_order) values
      (ss, 'SUMMARIZE_ACTIONS', 'Summarises what was done', 'Recaps the actions taken during the call.', 50, 'scale_5', 5,
       'Score 5 for a complete recap of every action taken. Score 3 for a partial recap. Score 0 when the call ends with no summary.', 1),
      (ss, 'NEXT_STEPS_CLEAR', 'States clear next steps', 'Customer knows exactly what happens next and when.', 50, 'scale_5', 5,
       'Score 5 when next steps include WHO does WHAT by WHEN. Score 3 for vague next steps ("someone will get back to you"). Score 0 when follow-up is required but never mentioned.', 2);

    insert into subsections (section_id, code, name, description, weight, display_order)
    values (s_close, 'CLOSE_COURTESY', 'Courteous Close', 'Ending the call well.', 40, 2)
    returning id into ss;

      insert into criteria (subsection_id, code, name, description, weight, scoring_type, max_score, guidance, display_order) values
      (ss, 'THANK_CUSTOMER', 'Thanks the customer', 'Genuine thanks for their time or patience.', 55, 'scale_5', 5,
       'Score 5 for specific, genuine thanks ("thank you for your patience while I checked that"). Score 3 for a perfunctory "thanks". Score 0 for none.', 1),
      (ss, 'BRANDED_CLOSE', 'Uses a branded close', 'Closes with the company name and a professional sign-off.', 45, 'scale_5', 5,
       'Score 5 for a full branded sign-off naming the company. Score 3 for a polite but unbranded close. Score 0 for an abrupt ending or hanging up first.', 2);

  -- Publish. This validates every level sums to 100 and then freezes the tree.
  perform publish_framework_version(v_fw, null);

  raise notice 'Seeded framework v1: % sections, % subsections, % criteria',
    (select count(*) from sections where framework_version_id = v_fw),
    (select count(*) from subsections ss2 join sections s2 on s2.id = ss2.section_id where s2.framework_version_id = v_fw),
    (select count(*) from criteria c2 join subsections ss2 on ss2.id = c2.subsection_id
       join sections s2 on s2.id = ss2.section_id where s2.framework_version_id = v_fw);
end $$;
