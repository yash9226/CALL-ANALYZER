-- ============================================================
-- SEED · Calls, transcripts and turns
-- GENERATED FILE — edit scripts/generate_seed_calls.py instead.
-- 84 calls · 9 agents · 6 weeks of history
--
-- calls.metadata.ground_truth records the quality tier each block was
-- generated from, so Phase 3 can measure AI scoring accuracy against it.
-- ============================================================

do $$
declare v_call uuid; v_tr uuid;
begin
if exists (select 1 from calls where source = 'seed') then
  raise notice 'Calls already seeded, skipping.'; return;
end if;

-- NW-20260828-0001 · Rahul Menon · billing_double_charge
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260828-0001', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-36062', 'inbound',
  'phone', 'seed', 'en', '2026-08-28T12:14:32+00:00',
  '2026-08-28T12:21:19+00:00', 407, 'transcribed',
  '{"scenario": "billing_double_charge", "intent": "billing_dispute", "topics": ["billing", "duplicate_charge", "refund"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "not_applicable", "resolution": "mid", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?
Customer: I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: I can see both transactions here, both on the 3rd. Looking at the payment log, your auto-debit mandate fired and then a manual payment was also processed from the app about four minutes later. So this is a duplicate, not a pricing change on your plan.
Customer: I did tap pay in the app because it showed as pending.
Agent: That explains it exactly, and that pending display is a known lag on our side. The charge is genuinely duplicated and you''re owed it back.
Agent: I''ll raise a refund request. It should come back in a few days.
Customer: Okay.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 291, 16, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.', 97, 246),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 247, 381),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 382, 508),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 509, 570),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 571, 685),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 686, 708),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 709, 769),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I can see both transactions here, both on the 3rd. Looking at the payment log, your auto-debit mandate fired and then a manual payment was also processed from the app about four minutes later. So this is a duplicate, not a pricing change on your plan.', 770, 1028),
  (v_tr, v_call, 9, 'customer', 'Customer', 'I did tap pay in the app because it showed as pending.', 1029, 1093),
  (v_tr, v_call, 10, 'agent', 'Agent', 'That explains it exactly, and that pending display is a known lag on our side. The charge is genuinely duplicated and you''re owed it back.', 1094, 1239),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I''ll raise a refund request. It should come back in a few days.', 1240, 1310),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Okay.', 1311, 1326),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Anything else?', 1327, 1348),
  (v_tr, v_call, 14, 'customer', 'Customer', 'No, that''s it.', 1349, 1373),
  (v_tr, v_call, 15, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1374, 1634);

-- NW-20260812-0002 · Meera Raghavan · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260812-0002', '22222222-2222-4222-8222-000000000009', '11111111-1111-4111-8111-000000000003', 'CUST-89131', 'inbound',
  'phone', 'seed', 'en', '2026-08-12T10:05:24+00:00',
  '2026-08-12T10:10:54+00:00', 330, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.92, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "mid", "diagnosis": "good", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.
Customer: So I''m over-subscribed?
Agent: Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.
Agent: Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.
Customer: Let''s go with the 150. I''d rather save the money.
Agent: Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 342, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 173, 276),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 277, 411),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 412, 462),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 463, 486),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 487, 508),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.', 509, 796),
  (v_tr, v_call, 7, 'customer', 'Customer', 'So I''m over-subscribed?', 797, 830),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.', 831, 918),
  (v_tr, v_call, 9, 'agent', 'Agent', 'Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.', 919, 1230),
  (v_tr, v_call, 10, 'customer', 'Customer', 'Let''s go with the 150. I''d rather save the money.', 1231, 1290),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.', 1291, 1469),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1470, 1551),
  (v_tr, v_call, 13, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1552, 1595),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1596, 1670),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s everything.', 1671, 1703),
  (v_tr, v_call, 16, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1704, 1964);

-- NW-20260728-0003 · Fatima Sheikh · tech_no_internet
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260728-0003', '22222222-2222-4222-8222-000000000005', '11111111-1111-4111-8111-000000000002', 'CUST-47930', 'inbound',
  'phone', 'seed', 'en', '2026-07-28T12:45:04+00:00',
  '2026-07-28T12:48:39+00:00', 215, 'transcribed',
  '{"scenario": "tech_no_internet", "intent": "service_outage", "topics": ["technical", "outage", "connectivity"], "agent_skill_profile": 0.48, "ground_truth": {"greeting": "mid", "empathy": "mid", "verification": "poor", "diagnosis": "mid", "hold": "not_applicable", "resolution": "poor", "confirm": "mid", "closing": "poor"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Fatima speaking, the call is recorded. What can I do for you?
Customer: My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.
Agent: Sorry about that. Let me check.
Agent: Okay, I''ve pulled up the account, I can see your plan and your last three invoices here.
Agent: Let me check. Yes, there seems to be an issue in your area.
Customer: How long will it take?
Agent: There''s an outage, it''ll be fixed when it''s fixed. Nothing I can do from here.
Customer: That''s not an answer.
Agent: Anything else?
Customer: No, that''s it.
Agent: Alright. Bye.', 121, 11, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Fatima speaking, the call is recorded. What can I do for you?', 0, 97),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.', 98, 252),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 253, 291),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Okay, I''ve pulled up the account, I can see your plan and your last three invoices here.', 292, 387),
  (v_tr, v_call, 4, 'agent', 'Agent', 'Let me check. Yes, there seems to be an issue in your area.', 388, 454),
  (v_tr, v_call, 5, 'customer', 'Customer', 'How long will it take?', 455, 487),
  (v_tr, v_call, 6, 'agent', 'Agent', 'There''s an outage, it''ll be fixed when it''s fixed. Nothing I can do from here.', 488, 573),
  (v_tr, v_call, 7, 'customer', 'Customer', 'That''s not an answer.', 574, 605),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Anything else?', 606, 627),
  (v_tr, v_call, 9, 'customer', 'Customer', 'No, that''s it.', 628, 652),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Alright. Bye.', 653, 673);

-- NW-20260829-0004 · Rahul Menon · billing_double_charge
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260829-0004', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-31417', 'inbound',
  'phone', 'seed', 'en', '2026-08-29T18:40:10+00:00',
  '2026-08-29T18:46:26+00:00', 376, 'transcribed',
  '{"scenario": "billing_double_charge", "intent": "billing_dispute", "topics": ["billing", "duplicate_charge", "refund"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "poor", "empathy": "good", "verification": "mid", "diagnosis": "mid", "hold": "good", "resolution": "mid", "confirm": "mid", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Hello, support desk.
Customer: I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Yes, I can see two payments. It looks like a duplicate.
Customer: So what happens now?
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I''ll raise a refund request. It should come back in a few days.
Customer: Okay.
Agent: Anything else?
Customer: No, that''s it.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 171, 16, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Hello, support desk.', 0, 27),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.', 28, 177),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 178, 312),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 313, 363),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 364, 387),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 388, 409),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Yes, I can see two payments. It looks like a duplicate.', 410, 472),
  (v_tr, v_call, 7, 'customer', 'Customer', 'So what happens now?', 473, 503),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 504, 621),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Yes, that''s fine.', 622, 649),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 650, 733),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I''ll raise a refund request. It should come back in a few days.', 734, 804),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Okay.', 805, 820),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Anything else?', 821, 842),
  (v_tr, v_call, 14, 'customer', 'Customer', 'No, that''s it.', 843, 867),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 868, 945);

-- NW-20260808-0005 · Karan Malhotra · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260808-0005', '22222222-2222-4222-8222-000000000008', '11111111-1111-4111-8111-000000000003', 'CUST-51245', 'inbound',
  'phone', 'seed', 'en', '2026-08-08T13:04:13+00:00',
  '2026-08-08T13:10:35+00:00', 382, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.42, "ground_truth": {"greeting": "good", "empathy": "poor", "verification": "mid", "diagnosis": "good", "hold": "poor", "resolution": "good", "confirm": "poor", "closing": "poor"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Karan. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: Okay. What''s the account number.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.
Customer: So I''m over-subscribed?
Agent: Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.
Agent: Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.
Customer: Let''s go with the 150. I''d rather save the money.
Agent: Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.
Agent: Alright. Bye.', 241, 13, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Karan. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 173, 276),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Okay. What''s the account number.', 277, 316),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 317, 367),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 368, 391),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 392, 413),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.', 414, 701),
  (v_tr, v_call, 7, 'customer', 'Customer', 'So I''m over-subscribed?', 702, 735),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.', 736, 823),
  (v_tr, v_call, 9, 'agent', 'Agent', 'Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.', 824, 1135),
  (v_tr, v_call, 10, 'customer', 'Customer', 'Let''s go with the 150. I''d rather save the money.', 1136, 1195),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.', 1196, 1374),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Alright. Bye.', 1375, 1395);

-- NW-20260727-0006 · Arjun Deshmukh · tech_router_setup
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260727-0006', '22222222-2222-4222-8222-000000000004', '11111111-1111-4111-8111-000000000002', 'CUST-76784', 'inbound',
  'phone', 'seed', 'en', '2026-07-27T15:23:14+00:00',
  '2026-07-27T15:32:21+00:00', 547, 'transcribed',
  '{"scenario": "tech_router_setup", "intent": "setup_assistance", "topics": ["technical", "installation", "router"], "agent_skill_profile": 0.78, "ground_truth": {"greeting": "good", "empathy": "mid", "verification": "mid", "diagnosis": "good", "hold": "mid", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Arjun. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.
Agent: Sorry about that. Let me check.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Not a problem at all, we''ll go one step at a time and I won''t rush you. Can you tell me what colour the lights on the front are right now?
Customer: There''s a green one and one that''s flashing orange.
Agent: That''s actually good news. Green means power is fine, and flashing orange means it''s looking for the connection but hasn''t found it yet. Nine times out of ten that''s the fibre cable in the wrong port.
Agent: One moment.
Agent: Okay, I''m back.
Agent: On the back of the router there''s a row of yellow ports and one separate blue port. Can you tell me which one the thin cable from the wall is plugged into?
Customer: It''s in a yellow one.
Agent: That''s it, that''s the whole problem. Move it to the blue port for me, and take your time.
Customer: Okay, moved. Oh, the orange light just went solid green.
Agent: That''s exactly right. Your wifi name and password are printed on the sticker underneath the router. Try connecting your phone and tell me if it works.
Customer: It''s connected. Thank you so much, I was dreading this call.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 320, 20, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Arjun. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.', 173, 285),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 286, 324),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 325, 375),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 376, 399),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 400, 421),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Not a problem at all, we''ll go one step at a time and I won''t rush you. Can you tell me what colour the lights on the front are right now?', 422, 567),
  (v_tr, v_call, 7, 'customer', 'Customer', 'There''s a green one and one that''s flashing orange.', 568, 629),
  (v_tr, v_call, 8, 'agent', 'Agent', 'That''s actually good news. Green means power is fine, and flashing orange means it''s looking for the connection but hasn''t found it yet. Nine times out of ten that''s the fibre cable in the wrong port.', 630, 837),
  (v_tr, v_call, 9, 'agent', 'Agent', 'One moment.', 838, 856),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Okay, I''m back.', 857, 879),
  (v_tr, v_call, 11, 'agent', 'Agent', 'On the back of the router there''s a row of yellow ports and one separate blue port. Can you tell me which one the thin cable from the wall is plugged into?', 880, 1042),
  (v_tr, v_call, 12, 'customer', 'Customer', 'It''s in a yellow one.', 1043, 1074),
  (v_tr, v_call, 13, 'agent', 'Agent', 'That''s it, that''s the whole problem. Move it to the blue port for me, and take your time.', 1075, 1171),
  (v_tr, v_call, 14, 'customer', 'Customer', 'Okay, moved. Oh, the orange light just went solid green.', 1172, 1238),
  (v_tr, v_call, 15, 'agent', 'Agent', 'That''s exactly right. Your wifi name and password are printed on the sticker underneath the router. Try connecting your phone and tell me if it works.', 1239, 1396),
  (v_tr, v_call, 16, 'customer', 'Customer', 'It''s connected. Thank you so much, I was dreading this call.', 1397, 1467),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Anything else?', 1468, 1489),
  (v_tr, v_call, 18, 'customer', 'Customer', 'No, that''s it.', 1490, 1514),
  (v_tr, v_call, 19, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1515, 1775);

-- NW-20260804-0007 · Karan Malhotra · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260804-0007', '22222222-2222-4222-8222-000000000008', '11111111-1111-4111-8111-000000000003', 'CUST-99166', 'inbound',
  'phone', 'seed', 'en', '2026-08-04T17:16:35+00:00',
  '2026-08-04T17:23:53+00:00', 438, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.42, "ground_truth": {"greeting": "poor", "empathy": "poor", "verification": "good", "diagnosis": "good", "hold": "not_applicable", "resolution": "mid", "confirm": "mid", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Hello, support desk.
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: Okay. What''s the account number.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.
Customer: Honestly it''s the three outages in two months. I can''t work like that.
Agent: That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.
Agent: I can give you a discount if you stay.
Customer: How much?
Agent: Twenty percent for six months.
Agent: Anything else?
Customer: No, that''s it.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 216, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Hello, support desk.', 0, 27),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 28, 121),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Okay. What''s the account number.', 122, 161),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 162, 288),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 289, 350),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 351, 465),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 466, 488),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 489, 549),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.', 550, 770),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Honestly it''s the three outages in two months. I can''t work like that.', 771, 851),
  (v_tr, v_call, 10, 'agent', 'Agent', 'That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.', 852, 988),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I can give you a discount if you stay.', 989, 1034),
  (v_tr, v_call, 12, 'customer', 'Customer', 'How much?', 1035, 1054),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Twenty percent for six months.', 1055, 1092),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Anything else?', 1093, 1114),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s it.', 1115, 1139),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1140, 1217);

-- NW-20260801-0008 · Rahul Menon · billing_refund_status
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260801-0008', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-49117', 'inbound',
  'phone', 'seed', 'en', '2026-08-01T11:32:58+00:00',
  '2026-08-01T11:39:05+00:00', 367, 'transcribed',
  '{"scenario": "billing_refund_status", "intent": "refund_status", "topics": ["billing", "refund", "follow_up"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "poor", "empathy": "mid", "verification": "mid", "diagnosis": "good", "hold": "good", "resolution": "good", "confirm": "mid", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Hello, support desk.
Customer: I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.
Agent: Sorry about that. Let me check.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Three calls for the same thing is genuinely not acceptable and I''m sorry you''ve had to chase this. Let me find out exactly what happened rather than just re-raising it. I can see the refund was approved on the 8th, but it was queued against a closed payment method, which is why it never actually moved.
Customer: So it was just stuck the whole time?
Agent: Yes, and it would have stayed stuck. I''m glad you called back.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I''m re-issuing it to your current card now and marking it priority, which brings it to twenty-four hours rather than three days. I''m also adding a 300 rupee credit for the inconvenience of three calls, applied immediately. Reference NW-90118.
Customer: I appreciate that, thank you.
Agent: And I''ve set a reminder on my side to verify it landed tomorrow. If it hasn''t, you''ll get a call from us rather than you having to chase again.
Agent: Anything else?
Customer: No, that''s it.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 267, 18, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Hello, support desk.', 0, 27),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.', 28, 151),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 152, 190),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 191, 241),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 242, 265),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 266, 287),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Three calls for the same thing is genuinely not acceptable and I''m sorry you''ve had to chase this. Let me find out exactly what happened rather than just re-raising it. I can see the refund was approved on the 8th, but it was queued against a closed payment method, which is why it never actually moved.', 288, 598),
  (v_tr, v_call, 7, 'customer', 'Customer', 'So it was just stuck the whole time?', 599, 645),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Yes, and it would have stayed stuck. I''m glad you called back.', 646, 715),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 716, 833),
  (v_tr, v_call, 10, 'customer', 'Customer', 'Yes, that''s fine.', 834, 861),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 862, 945),
  (v_tr, v_call, 12, 'agent', 'Agent', 'I''m re-issuing it to your current card now and marking it priority, which brings it to twenty-four hours rather than three days. I''m also adding a 300 rupee credit for the inconvenience of three calls, applied immediately. Reference NW-90118.', 946, 1195),
  (v_tr, v_call, 13, 'customer', 'Customer', 'I appreciate that, thank you.', 1196, 1235),
  (v_tr, v_call, 14, 'agent', 'Agent', 'And I''ve set a reminder on my side to verify it landed tomorrow. If it hasn''t, you''ll get a call from us rather than you having to chase again.', 1236, 1386),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Anything else?', 1387, 1408),
  (v_tr, v_call, 16, 'customer', 'Customer', 'No, that''s it.', 1409, 1433),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1434, 1511);

-- NW-20260810-0009 · Meera Raghavan · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260810-0009', '22222222-2222-4222-8222-000000000009', '11111111-1111-4111-8111-000000000003', 'CUST-20322', 'inbound',
  'phone', 'seed', 'en', '2026-08-10T13:15:03+00:00',
  '2026-08-10T13:21:30+00:00', 387, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.92, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "mid", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Can I ask why you''re leaving?
Customer: Too many outages.
Agent: I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.
Customer: That''s more reasonable than I expected. Let me take the two months.
Agent: Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 352, 18, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 173, 266),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 267, 401),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 402, 528),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 529, 590),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 591, 705),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 706, 728),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 729, 789),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Can I ask why you''re leaving?', 790, 826),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Too many outages.', 827, 854),
  (v_tr, v_call, 10, 'agent', 'Agent', 'I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.', 855, 1285),
  (v_tr, v_call, 11, 'customer', 'Customer', 'That''s more reasonable than I expected. Let me take the two months.', 1286, 1363),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.', 1364, 1498),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1499, 1580),
  (v_tr, v_call, 14, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1581, 1624),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1625, 1699),
  (v_tr, v_call, 16, 'customer', 'Customer', 'No, that''s everything.', 1700, 1732),
  (v_tr, v_call, 17, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1733, 1993);

-- NW-20260806-0010 · Rahul Menon · billing_refund_status
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260806-0010', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-36365', 'inbound',
  'phone', 'seed', 'en', '2026-08-06T12:59:34+00:00',
  '2026-08-06T13:07:41+00:00', 487, 'transcribed',
  '{"scenario": "billing_refund_status", "intent": "refund_status", "topics": ["billing", "refund", "follow_up"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "mid", "diagnosis": "mid", "hold": "mid", "resolution": "mid", "confirm": "good", "closing": "poor"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?
Customer: I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Let me check. It seems it hasn''t been processed yet.
Customer: Why not?
Agent: I''m not sure.
Agent: One moment.
Agent: Okay, I''m back.
Agent: I''ll escalate it to the billing team.
Customer: That''s what the last person said.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Alright. Bye.', 168, 18, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.', 97, 220),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 221, 355),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 356, 406),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 407, 430),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 431, 452),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Let me check. It seems it hasn''t been processed yet.', 453, 512),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Why not?', 513, 531),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I''m not sure.', 532, 552),
  (v_tr, v_call, 9, 'agent', 'Agent', 'One moment.', 553, 571),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Okay, I''m back.', 572, 594),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I''ll escalate it to the billing team.', 595, 639),
  (v_tr, v_call, 12, 'customer', 'Customer', 'That''s what the last person said.', 640, 683),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 684, 765),
  (v_tr, v_call, 14, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 766, 809),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 810, 884),
  (v_tr, v_call, 16, 'customer', 'Customer', 'No, that''s everything.', 885, 917),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Alright. Bye.', 918, 938);

-- NW-20260819-0011 · Fatima Sheikh · tech_slow_speed
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260819-0011', '22222222-2222-4222-8222-000000000005', '11111111-1111-4111-8111-000000000002', 'CUST-18834', 'inbound',
  'phone', 'seed', 'en', '2026-08-19T09:04:45+00:00',
  '2026-08-19T09:11:15+00:00', 390, 'transcribed',
  '{"scenario": "tech_slow_speed", "intent": "performance_complaint", "topics": ["technical", "speed", "wifi"], "agent_skill_profile": 0.48, "ground_truth": {"greeting": "poor", "empathy": "mid", "verification": "mid", "diagnosis": "mid", "hold": "good", "resolution": "mid", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Hello, support desk.
Customer: I''m paying for 300 megabits but I''m getting about 40 on my laptop. This has been going on for two weeks.
Agent: Sorry about that. Let me check.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Your line looks fine on our end. It''s probably your wifi.
Customer: So what do I do?
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: Try connecting to the 5G network name instead.
Customer: Alright, I''ll try that later.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 174, 16, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Hello, support desk.', 0, 27),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''m paying for 300 megabits but I''m getting about 40 on my laptop. This has been going on for two weeks.', 28, 142),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 143, 181),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 182, 232),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 233, 256),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 257, 278),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Your line looks fine on our end. It''s probably your wifi.', 279, 343),
  (v_tr, v_call, 7, 'customer', 'Customer', 'So what do I do?', 344, 370),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 371, 488),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Yes, that''s fine.', 489, 516),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 517, 600),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Try connecting to the 5G network name instead.', 601, 654),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Alright, I''ll try that later.', 655, 694),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Anything else?', 695, 716),
  (v_tr, v_call, 14, 'customer', 'Customer', 'No, that''s it.', 717, 741),
  (v_tr, v_call, 15, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 742, 1002);

-- NW-20260807-0012 · Priya Nair · billing_plan_change
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260807-0012', '22222222-2222-4222-8222-000000000001', '11111111-1111-4111-8111-000000000001', 'CUST-65519', 'inbound',
  'phone', 'seed', 'en', '2026-08-07T12:06:06+00:00',
  '2026-08-07T12:14:42+00:00', 516, 'transcribed',
  '{"scenario": "billing_plan_change", "intent": "plan_enquiry", "topics": ["billing", "plan_change", "pricing"], "agent_skill_profile": 0.85, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "mid", "resolution": "good", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My bill went up by 400 rupees this month and nobody told me it was going to change.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Let me walk you through the invoice line by line. Your promotional rate of 899 ran for twelve months and ended on the 15th of last month, so this invoice has fifteen days at the promo rate and fifteen at the standard 1,299. That''s why it looks like an odd number rather than a clean increase.
Customer: I don''t remember being told the promo was ending.
Agent: I can see a notification was sent to your registered email on the 1st, but I completely understand those are easy to miss, and I''m not going to argue that point with you.
Agent: One moment.
Agent: Okay, I''m back.
Agent: Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.
Customer: The loyalty rate sounds fair. Let''s do that.
Agent: Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 406, 21, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My bill went up by 400 rupees this month and nobody told me it was going to change.', 173, 266),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 267, 401),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 402, 528),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 529, 590),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 591, 705),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 706, 728),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 729, 789),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Let me walk you through the invoice line by line. Your promotional rate of 899 ran for twelve months and ended on the 15th of last month, so this invoice has fifteen days at the promo rate and fifteen at the standard 1,299. That''s why it looks like an odd number rather than a clean increase.', 790, 1089),
  (v_tr, v_call, 9, 'customer', 'Customer', 'I don''t remember being told the promo was ending.', 1090, 1149),
  (v_tr, v_call, 10, 'agent', 'Agent', 'I can see a notification was sent to your registered email on the 1st, but I completely understand those are easy to miss, and I''m not going to argue that point with you.', 1150, 1327),
  (v_tr, v_call, 11, 'agent', 'Agent', 'One moment.', 1328, 1346),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Okay, I''m back.', 1347, 1369),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.', 1370, 1732),
  (v_tr, v_call, 14, 'customer', 'Customer', 'The loyalty rate sounds fair. Let''s do that.', 1733, 1787),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.', 1788, 1917),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1918, 1999),
  (v_tr, v_call, 17, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 2000, 2043),
  (v_tr, v_call, 18, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 2044, 2118),
  (v_tr, v_call, 19, 'customer', 'Customer', 'No, that''s everything.', 2119, 2151),
  (v_tr, v_call, 20, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 2152, 2229);

-- NW-20260730-0013 · Ananya Bose · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260730-0013', '22222222-2222-4222-8222-000000000007', '11111111-1111-4111-8111-000000000003', 'CUST-42742', 'inbound',
  'phone', 'seed', 'en', '2026-07-30T16:08:27+00:00',
  '2026-07-30T16:15:30+00:00', 423, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.88, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "good", "resolution": "mid", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Ananya speaking, the call is recorded. What can I do for you?
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.
Customer: So I''m over-subscribed?
Agent: Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: The 150 plan is 949 if you want to save money.
Customer: Okay, put me on that.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 341, 21, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Ananya speaking, the call is recorded. What can I do for you?', 0, 97),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 98, 201),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 202, 336),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 337, 463),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 464, 525),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 526, 640),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 641, 663),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 664, 724),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.', 725, 1012),
  (v_tr, v_call, 9, 'customer', 'Customer', 'So I''m over-subscribed?', 1013, 1046),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.', 1047, 1134),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 1135, 1252),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s fine.', 1253, 1280),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 1281, 1364),
  (v_tr, v_call, 14, 'agent', 'Agent', 'The 150 plan is 949 if you want to save money.', 1365, 1418),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Okay, put me on that.', 1419, 1450),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1451, 1532),
  (v_tr, v_call, 17, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1533, 1576),
  (v_tr, v_call, 18, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1577, 1651),
  (v_tr, v_call, 19, 'customer', 'Customer', 'No, that''s everything.', 1652, 1684),
  (v_tr, v_call, 20, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1685, 1945);

-- NW-20260818-0014 · Rahul Menon · billing_plan_change
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260818-0014', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-17685', 'inbound',
  'phone', 'seed', 'en', '2026-08-18T11:26:31+00:00',
  '2026-08-18T11:33:30+00:00', 419, 'transcribed',
  '{"scenario": "billing_plan_change", "intent": "plan_enquiry", "topics": ["billing", "plan_change", "pricing"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "mid", "empathy": "poor", "verification": "good", "diagnosis": "mid", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?
Customer: My bill went up by 400 rupees this month and nobody told me it was going to change.
Agent: Okay. What''s the account number.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Your promotional pricing expired. That''s the standard rate now.
Customer: Nobody told me.
Agent: Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.
Customer: The loyalty rate sounds fair. Let''s do that.
Agent: Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 276, 18, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My bill went up by 400 rupees this month and nobody told me it was going to change.', 97, 190),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Okay. What''s the account number.', 191, 230),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 231, 357),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 358, 419),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 420, 534),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 535, 557),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 558, 618),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Your promotional pricing expired. That''s the standard rate now.', 619, 689),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Nobody told me.', 690, 715),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.', 716, 1078),
  (v_tr, v_call, 11, 'customer', 'Customer', 'The loyalty rate sounds fair. Let''s do that.', 1079, 1133),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.', 1134, 1263),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1264, 1345),
  (v_tr, v_call, 14, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1346, 1389),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1390, 1464),
  (v_tr, v_call, 16, 'customer', 'Customer', 'No, that''s everything.', 1465, 1497),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1498, 1575);

-- NW-20260802-0015 · Sneha Kulkarni · billing_plan_change
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260802-0015', '22222222-2222-4222-8222-000000000003', '11111111-1111-4111-8111-000000000001', 'CUST-85914', 'inbound',
  'phone', 'seed', 'en', '2026-08-02T11:12:18+00:00',
  '2026-08-02T11:17:50+00:00', 332, 'transcribed',
  '{"scenario": "billing_plan_change", "intent": "plan_enquiry", "topics": ["billing", "plan_change", "pricing"], "agent_skill_profile": 0.9, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "mid", "diagnosis": "mid", "hold": "good", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Sneha. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My bill went up by 400 rupees this month and nobody told me it was going to change.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Your promotional pricing expired. That''s the standard rate now.
Customer: Nobody told me.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.
Customer: The loyalty rate sounds fair. Let''s do that.
Agent: Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 301, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Sneha. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My bill went up by 400 rupees this month and nobody told me it was going to change.', 173, 266),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 267, 401),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 402, 452),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 453, 476),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 477, 498),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Your promotional pricing expired. That''s the standard rate now.', 499, 569),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Nobody told me.', 570, 595),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 596, 713),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Yes, that''s fine.', 714, 741),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 742, 825),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.', 826, 1188),
  (v_tr, v_call, 12, 'customer', 'Customer', 'The loyalty rate sounds fair. Let''s do that.', 1189, 1243),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.', 1244, 1373),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Anything else?', 1374, 1395),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s it.', 1396, 1420),
  (v_tr, v_call, 16, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1421, 1681);

-- NW-20260822-0016 · Meera Raghavan · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260822-0016', '22222222-2222-4222-8222-000000000009', '11111111-1111-4111-8111-000000000003', 'CUST-62923', 'inbound',
  'phone', 'seed', 'en', '2026-08-22T10:38:04+00:00',
  '2026-08-22T10:45:05+00:00', 421, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.92, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "not_applicable", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.
Customer: Honestly it''s the three outages in two months. I can''t work like that.
Agent: That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.
Agent: I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.
Customer: That''s more reasonable than I expected. Let me take the two months.
Agent: Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 391, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 173, 266),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 267, 401),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 402, 528),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 529, 590),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 591, 705),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 706, 728),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 729, 789),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.', 790, 1010),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Honestly it''s the three outages in two months. I can''t work like that.', 1011, 1091),
  (v_tr, v_call, 10, 'agent', 'Agent', 'That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.', 1092, 1228),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.', 1229, 1659),
  (v_tr, v_call, 12, 'customer', 'Customer', 'That''s more reasonable than I expected. Let me take the two months.', 1660, 1737),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.', 1738, 1872),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Anything else?', 1873, 1894),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s it.', 1895, 1919),
  (v_tr, v_call, 16, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1920, 2180);

-- NW-20260813-0017 · Rahul Menon · billing_refund_status
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260813-0017', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-49321', 'inbound',
  'phone', 'seed', 'en', '2026-08-13T12:16:25+00:00',
  '2026-08-13T12:20:53+00:00', 268, 'transcribed',
  '{"scenario": "billing_refund_status", "intent": "refund_status", "topics": ["billing", "refund", "follow_up"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "good", "empathy": "mid", "verification": "mid", "diagnosis": "mid", "hold": "not_applicable", "resolution": "mid", "confirm": "poor", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Rahul. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.
Agent: Sorry about that. Let me check.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Let me check. It seems it hasn''t been processed yet.
Customer: Why not?
Agent: I''m not sure.
Agent: I''ll escalate it to the billing team.
Customer: That''s what the last person said.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 153, 12, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Rahul. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.', 173, 296),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 297, 335),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 336, 386),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 387, 410),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 411, 432),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Let me check. It seems it hasn''t been processed yet.', 433, 492),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Why not?', 493, 511),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I''m not sure.', 512, 532),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I''ll escalate it to the billing team.', 533, 577),
  (v_tr, v_call, 10, 'customer', 'Customer', 'That''s what the last person said.', 578, 621),
  (v_tr, v_call, 11, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 622, 882);

-- NW-20260825-0018 · Karan Malhotra · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260825-0018', '22222222-2222-4222-8222-000000000008', '11111111-1111-4111-8111-000000000003', 'CUST-47353', 'inbound',
  'phone', 'seed', 'en', '2026-08-25T14:56:04+00:00',
  '2026-08-25T15:03:23+00:00', 439, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.42, "ground_truth": {"greeting": "poor", "empathy": "poor", "verification": "good", "diagnosis": "mid", "hold": "not_applicable", "resolution": "good", "confirm": "mid", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Hello, support desk.
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: Okay. What''s the account number.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: I can show you our current plans.
Customer: Go ahead.
Agent: Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.
Customer: Let''s go with the 150. I''d rather save the money.
Agent: Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.
Agent: Anything else?
Customer: No, that''s it.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 224, 16, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Hello, support desk.', 0, 27),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 28, 131),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Okay. What''s the account number.', 132, 171),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 172, 298),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 299, 360),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 361, 475),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 476, 498),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 499, 559),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I can show you our current plans.', 560, 600),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Go ahead.', 601, 620),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.', 621, 932),
  (v_tr, v_call, 11, 'customer', 'Customer', 'Let''s go with the 150. I''d rather save the money.', 933, 992),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.', 993, 1171),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Anything else?', 1172, 1193),
  (v_tr, v_call, 14, 'customer', 'Customer', 'No, that''s it.', 1194, 1218),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1219, 1296);

-- NW-20260827-0019 · Sneha Kulkarni · billing_plan_change
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260827-0019', '22222222-2222-4222-8222-000000000003', '11111111-1111-4111-8111-000000000001', 'CUST-82512', 'inbound',
  'phone', 'seed', 'en', '2026-08-27T11:16:07+00:00',
  '2026-08-27T11:23:52+00:00', 465, 'transcribed',
  '{"scenario": "billing_plan_change", "intent": "plan_enquiry", "topics": ["billing", "plan_change", "pricing"], "agent_skill_profile": 0.9, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "good", "diagnosis": "mid", "hold": "not_applicable", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Sneha speaking, the call is recorded. What can I do for you?
Customer: My bill went up by 400 rupees this month and nobody told me it was going to change.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Your promotional pricing expired. That''s the standard rate now.
Customer: Nobody told me.
Agent: Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.
Customer: The loyalty rate sounds fair. Let''s do that.
Agent: Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 295, 16, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Sneha speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My bill went up by 400 rupees this month and nobody told me it was going to change.', 97, 190),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 191, 325),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 326, 452),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 453, 514),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 515, 629),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 630, 652),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 653, 713),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Your promotional pricing expired. That''s the standard rate now.', 714, 784),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Nobody told me.', 785, 810),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.', 811, 1173),
  (v_tr, v_call, 11, 'customer', 'Customer', 'The loyalty rate sounds fair. Let''s do that.', 1174, 1228),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.', 1229, 1358),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Anything else?', 1359, 1380),
  (v_tr, v_call, 14, 'customer', 'Customer', 'No, that''s it.', 1381, 1405),
  (v_tr, v_call, 15, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1406, 1666);

-- NW-20260830-0020 · Sneha Kulkarni · billing_plan_change
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260830-0020', '22222222-2222-4222-8222-000000000003', '11111111-1111-4111-8111-000000000001', 'CUST-10464', 'inbound',
  'phone', 'seed', 'en', '2026-08-30T10:40:27+00:00',
  '2026-08-30T10:48:30+00:00', 483, 'transcribed',
  '{"scenario": "billing_plan_change", "intent": "plan_enquiry", "topics": ["billing", "plan_change", "pricing"], "agent_skill_profile": 0.9, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Sneha. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My bill went up by 400 rupees this month and nobody told me it was going to change.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Let me walk you through the invoice line by line. Your promotional rate of 899 ran for twelve months and ended on the 15th of last month, so this invoice has fifteen days at the promo rate and fifteen at the standard 1,299. That''s why it looks like an odd number rather than a clean increase.
Customer: I don''t remember being told the promo was ending.
Agent: I can see a notification was sent to your registered email on the 1st, but I completely understand those are easy to miss, and I''m not going to argue that point with you.
Agent: Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.
Customer: The loyalty rate sounds fair. Let''s do that.
Agent: Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 399, 19, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Sneha. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My bill went up by 400 rupees this month and nobody told me it was going to change.', 173, 266),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 267, 401),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 402, 528),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 529, 590),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 591, 705),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 706, 728),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 729, 789),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Let me walk you through the invoice line by line. Your promotional rate of 899 ran for twelve months and ended on the 15th of last month, so this invoice has fifteen days at the promo rate and fifteen at the standard 1,299. That''s why it looks like an odd number rather than a clean increase.', 790, 1089),
  (v_tr, v_call, 9, 'customer', 'Customer', 'I don''t remember being told the promo was ending.', 1090, 1149),
  (v_tr, v_call, 10, 'agent', 'Agent', 'I can see a notification was sent to your registered email on the 1st, but I completely understand those are easy to miss, and I''m not going to argue that point with you.', 1150, 1327),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.', 1328, 1690),
  (v_tr, v_call, 12, 'customer', 'Customer', 'The loyalty rate sounds fair. Let''s do that.', 1691, 1745),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.', 1746, 1875),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1876, 1957),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1958, 2001),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 2002, 2076),
  (v_tr, v_call, 17, 'customer', 'Customer', 'No, that''s everything.', 2077, 2109),
  (v_tr, v_call, 18, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 2110, 2187);

-- NW-20260730-0021 · Vikram Iyer · tech_no_internet
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260730-0021', '22222222-2222-4222-8222-000000000006', '11111111-1111-4111-8111-000000000002', 'CUST-66333', 'inbound',
  'phone', 'seed', 'en', '2026-07-30T09:53:23+00:00',
  '2026-07-30T10:00:03+00:00', 400, 'transcribed',
  '{"scenario": "tech_no_internet", "intent": "service_outage", "topics": ["technical", "outage", "connectivity"], "agent_skill_profile": 0.7, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "mid", "diagnosis": "mid", "hold": "good", "resolution": "good", "confirm": "mid", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Vikram speaking, the call is recorded. What can I do for you?
Customer: My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Let me check. Yes, there seems to be an issue in your area.
Customer: How long will it take?
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: The repair crew is already assigned, with an estimated restoration by 6pm today. I''m adding your number to the SMS notification list so you get a text the moment the link is back. I''m also applying a two-day service credit to your account automatically, you don''t need to claim it.
Customer: That''s really helpful, thank you.
Agent: If it isn''t back by 6pm, call us and quote reference NW-88214 and it goes straight to the field team without you repeating any of this.
Agent: Anything else?
Customer: No, that''s it.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 255, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Vikram speaking, the call is recorded. What can I do for you?', 0, 97),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.', 98, 252),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 253, 387),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 388, 438),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 439, 462),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 463, 484),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Let me check. Yes, there seems to be an issue in your area.', 485, 551),
  (v_tr, v_call, 7, 'customer', 'Customer', 'How long will it take?', 552, 584),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 585, 702),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Yes, that''s fine.', 703, 730),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 731, 814),
  (v_tr, v_call, 11, 'agent', 'Agent', 'The repair crew is already assigned, with an estimated restoration by 6pm today. I''m adding your number to the SMS notification list so you get a text the moment the link is back. I''m also applying a two-day service credit to your account automatically, you don''t need to claim it.', 815, 1103),
  (v_tr, v_call, 12, 'customer', 'Customer', 'That''s really helpful, thank you.', 1104, 1147),
  (v_tr, v_call, 13, 'agent', 'Agent', 'If it isn''t back by 6pm, call us and quote reference NW-88214 and it goes straight to the field team without you repeating any of this.', 1148, 1290),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Anything else?', 1291, 1312),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s it.', 1313, 1337),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1338, 1415);

-- NW-20260729-0022 · Sneha Kulkarni · billing_double_charge
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260729-0022', '22222222-2222-4222-8222-000000000003', '11111111-1111-4111-8111-000000000001', 'CUST-31299', 'inbound',
  'phone', 'seed', 'en', '2026-07-29T15:39:47+00:00',
  '2026-07-29T15:45:02+00:00', 315, 'transcribed',
  '{"scenario": "billing_double_charge", "intent": "billing_dispute", "topics": ["billing", "duplicate_charge", "refund"], "agent_skill_profile": 0.9, "ground_truth": {"greeting": "good", "empathy": "mid", "verification": "mid", "diagnosis": "mid", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Sneha. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.
Agent: Sorry about that. Let me check.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Yes, I can see two payments. It looks like a duplicate.
Customer: So what happens now?
Agent: I''m raising a duplicate payment reversal for 1,299 now. That goes back to the original card and takes three working days. Your next invoice on the 3rd of October will be the normal 1,299, with no adjustment needed.
Customer: And I don''t need to do anything?
Agent: Nothing at all. I''ll also send you the reference number by email so you have it in writing.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 248, 16, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Sneha. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.', 173, 322),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 323, 361),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 362, 412),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 413, 436),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 437, 458),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Yes, I can see two payments. It looks like a duplicate.', 459, 521),
  (v_tr, v_call, 7, 'customer', 'Customer', 'So what happens now?', 522, 552),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I''m raising a duplicate payment reversal for 1,299 now. That goes back to the original card and takes three working days. Your next invoice on the 3rd of October will be the normal 1,299, with no adjustment needed.', 553, 774),
  (v_tr, v_call, 9, 'customer', 'Customer', 'And I don''t need to do anything?', 775, 817),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Nothing at all. I''ll also send you the reference number by email so you have it in writing.', 818, 916),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 917, 998),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 999, 1042),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1043, 1117),
  (v_tr, v_call, 14, 'customer', 'Customer', 'No, that''s everything.', 1118, 1150),
  (v_tr, v_call, 15, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1151, 1411);

-- NW-20260827-0023 · Sneha Kulkarni · billing_plan_change
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260827-0023', '22222222-2222-4222-8222-000000000003', '11111111-1111-4111-8111-000000000001', 'CUST-36158', 'inbound',
  'phone', 'seed', 'en', '2026-08-27T15:55:02+00:00',
  '2026-08-27T16:01:44+00:00', 402, 'transcribed',
  '{"scenario": "billing_plan_change", "intent": "plan_enquiry", "topics": ["billing", "plan_change", "pricing"], "agent_skill_profile": 0.9, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "mid", "hold": "not_applicable", "resolution": "mid", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Sneha. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My bill went up by 400 rupees this month and nobody told me it was going to change.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Your promotional pricing expired. That''s the standard rate now.
Customer: Nobody told me.
Agent: I can offer you a discounted rate of 1,099 if you want.
Customer: Fine, do that.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 225, 15, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Sneha. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My bill went up by 400 rupees this month and nobody told me it was going to change.', 173, 266),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 267, 401),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 402, 528),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 529, 590),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 591, 705),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 706, 728),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 729, 789),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Your promotional pricing expired. That''s the standard rate now.', 790, 860),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Nobody told me.', 861, 886),
  (v_tr, v_call, 10, 'agent', 'Agent', 'I can offer you a discounted rate of 1,099 if you want.', 887, 949),
  (v_tr, v_call, 11, 'customer', 'Customer', 'Fine, do that.', 950, 974),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Anything else?', 975, 996),
  (v_tr, v_call, 13, 'customer', 'Customer', 'No, that''s it.', 997, 1021),
  (v_tr, v_call, 14, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1022, 1282);

-- NW-20260723-0024 · Karan Malhotra · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260723-0024', '22222222-2222-4222-8222-000000000008', '11111111-1111-4111-8111-000000000003', 'CUST-53404', 'inbound',
  'phone', 'seed', 'en', '2026-07-23T17:25:43+00:00',
  '2026-07-23T17:33:29+00:00', 466, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.42, "ground_truth": {"greeting": "mid", "empathy": "poor", "verification": "good", "diagnosis": "good", "hold": "mid", "resolution": "poor", "confirm": "poor", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Karan speaking, the call is recorded. What can I do for you?
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: Okay. What''s the account number.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.
Customer: So I''m over-subscribed?
Agent: Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.
Agent: One moment.
Agent: Okay, I''m back.
Agent: I''d stay on 300 personally. I''ll just renew you on the same thing.
Customer: I suppose that''s easiest.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 215, 16, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Karan speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 97, 200),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Okay. What''s the account number.', 201, 240),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 241, 367),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 368, 429),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 430, 544),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 545, 567),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 568, 628),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.', 629, 916),
  (v_tr, v_call, 9, 'customer', 'Customer', 'So I''m over-subscribed?', 917, 950),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.', 951, 1038),
  (v_tr, v_call, 11, 'agent', 'Agent', 'One moment.', 1039, 1057),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Okay, I''m back.', 1058, 1080),
  (v_tr, v_call, 13, 'agent', 'Agent', 'I''d stay on 300 personally. I''ll just renew you on the same thing.', 1081, 1154),
  (v_tr, v_call, 14, 'customer', 'Customer', 'I suppose that''s easiest.', 1155, 1190),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1191, 1268);

-- NW-20260801-0025 · Priya Nair · billing_double_charge
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260801-0025', '22222222-2222-4222-8222-000000000001', '11111111-1111-4111-8111-000000000001', 'CUST-15817', 'inbound',
  'phone', 'seed', 'en', '2026-08-01T10:24:57+00:00',
  '2026-08-01T10:32:26+00:00', 449, 'transcribed',
  '{"scenario": "billing_double_charge", "intent": "billing_dispute", "topics": ["billing", "duplicate_charge", "refund"], "agent_skill_profile": 0.85, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "good", "diagnosis": "mid", "hold": "good", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Priya speaking, the call is recorded. What can I do for you?
Customer: I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Yes, I can see two payments. It looks like a duplicate.
Customer: So what happens now?
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I''m raising a duplicate payment reversal for 1,299 now. That goes back to the original card and takes three working days. Your next invoice on the 3rd of October will be the normal 1,299, with no adjustment needed.
Customer: And I don''t need to do anything?
Agent: Nothing at all. I''ll also send you the reference number by email so you have it in writing.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 314, 19, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Priya speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.', 97, 246),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 247, 381),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 382, 508),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 509, 570),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 571, 685),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 686, 708),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 709, 769),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Yes, I can see two payments. It looks like a duplicate.', 770, 832),
  (v_tr, v_call, 9, 'customer', 'Customer', 'So what happens now?', 833, 863),
  (v_tr, v_call, 10, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 864, 981),
  (v_tr, v_call, 11, 'customer', 'Customer', 'Yes, that''s fine.', 982, 1009),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 1010, 1093),
  (v_tr, v_call, 13, 'agent', 'Agent', 'I''m raising a duplicate payment reversal for 1,299 now. That goes back to the original card and takes three working days. Your next invoice on the 3rd of October will be the normal 1,299, with no adjustment needed.', 1094, 1315),
  (v_tr, v_call, 14, 'customer', 'Customer', 'And I don''t need to do anything?', 1316, 1358),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Nothing at all. I''ll also send you the reference number by email so you have it in writing.', 1359, 1457),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Anything else?', 1458, 1479),
  (v_tr, v_call, 17, 'customer', 'Customer', 'No, that''s it.', 1480, 1504),
  (v_tr, v_call, 18, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1505, 1765);

-- NW-20260812-0026 · Ananya Bose · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260812-0026', '22222222-2222-4222-8222-000000000007', '11111111-1111-4111-8111-000000000003', 'CUST-49363', 'inbound',
  'phone', 'seed', 'en', '2026-08-12T18:20:42+00:00',
  '2026-08-12T18:29:08+00:00', 506, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.88, "ground_truth": {"greeting": "good", "empathy": "mid", "verification": "good", "diagnosis": "mid", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: Sorry about that. Let me check.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Can I ask why you''re leaving?
Customer: Too many outages.
Agent: I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.
Customer: That''s more reasonable than I expected. Let me take the two months.
Agent: Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 301, 18, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 173),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 174, 267),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 268, 306),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 307, 433),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 434, 495),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 496, 610),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 611, 633),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 634, 694),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Can I ask why you''re leaving?', 695, 731),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Too many outages.', 732, 759),
  (v_tr, v_call, 10, 'agent', 'Agent', 'I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.', 760, 1190),
  (v_tr, v_call, 11, 'customer', 'Customer', 'That''s more reasonable than I expected. Let me take the two months.', 1191, 1268),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.', 1269, 1403),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1404, 1485),
  (v_tr, v_call, 14, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1486, 1529),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1530, 1604),
  (v_tr, v_call, 16, 'customer', 'Customer', 'No, that''s everything.', 1605, 1637),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1638, 1715);

-- NW-20260728-0027 · Meera Raghavan · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260728-0027', '22222222-2222-4222-8222-000000000009', '11111111-1111-4111-8111-000000000003', 'CUST-47606', 'inbound',
  'phone', 'seed', 'en', '2026-07-28T13:25:35+00:00',
  '2026-07-28T13:35:09+00:00', 574, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.92, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "good", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.
Customer: So I''m over-subscribed?
Agent: Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.
Customer: Let''s go with the 150. I''d rather save the money.
Agent: Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 434, 22, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 173, 276),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 277, 411),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 412, 538),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 539, 600),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 601, 715),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 716, 738),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 739, 799),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.', 800, 1087),
  (v_tr, v_call, 9, 'customer', 'Customer', 'So I''m over-subscribed?', 1088, 1121),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.', 1122, 1209),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 1210, 1327),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s fine.', 1328, 1355),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 1356, 1439),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.', 1440, 1751),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Let''s go with the 150. I''d rather save the money.', 1752, 1811),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.', 1812, 1990),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1991, 2072),
  (v_tr, v_call, 18, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 2073, 2116),
  (v_tr, v_call, 19, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 2117, 2191),
  (v_tr, v_call, 20, 'customer', 'Customer', 'No, that''s everything.', 2192, 2224),
  (v_tr, v_call, 21, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 2225, 2485);

-- NW-20260823-0028 · Arjun Deshmukh · tech_slow_speed
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260823-0028', '22222222-2222-4222-8222-000000000004', '11111111-1111-4111-8111-000000000002', 'CUST-53933', 'inbound',
  'phone', 'seed', 'en', '2026-08-23T10:18:32+00:00',
  '2026-08-23T10:26:41+00:00', 489, 'transcribed',
  '{"scenario": "tech_slow_speed", "intent": "performance_complaint", "topics": ["technical", "speed", "wifi"], "agent_skill_profile": 0.78, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "not_applicable", "resolution": "good", "confirm": "mid", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Arjun speaking, the call is recorded. What can I do for you?
Customer: I''m paying for 300 megabits but I''m getting about 40 on my laptop. This has been going on for two weeks.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Let me separate two things: the speed into your home, and the speed across your wifi. From our side your line is currently syncing at 297 megabits, so the fibre is delivering what you pay for. The drop is happening between the router and your laptop.
Customer: How can you tell?
Agent: Your router reports your laptop connected on the 2.4 gigahertz band, which tops out well below 300. On the 5 gigahertz band you''d see close to the full speed.
Agent: Two steps. First, on your laptop, connect to the network ending -5G instead of the plain one. Can you see that option now?
Customer: Yes, I''m connecting to it.
Agent: Run a speed test for me when it settles.
Customer: It''s showing 268 now. That''s a huge difference.
Agent: That''s what I''d expect. Second, I''ve pushed a channel optimisation to your router remotely, which should hold that speed during busy evenings.
Agent: Anything else?
Customer: No, that''s it.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 307, 19, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Arjun speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''m paying for 300 megabits but I''m getting about 40 on my laptop. This has been going on for two weeks.', 97, 211),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 212, 346),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 347, 473),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 474, 535),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 536, 650),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 651, 673),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 674, 734),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Let me separate two things: the speed into your home, and the speed across your wifi. From our side your line is currently syncing at 297 megabits, so the fibre is delivering what you pay for. The drop is happening between the router and your laptop.', 735, 992),
  (v_tr, v_call, 9, 'customer', 'Customer', 'How can you tell?', 993, 1020),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Your router reports your laptop connected on the 2.4 gigahertz band, which tops out well below 300. On the 5 gigahertz band you''d see close to the full speed.', 1021, 1186),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Two steps. First, on your laptop, connect to the network ending -5G instead of the plain one. Can you see that option now?', 1187, 1316),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, I''m connecting to it.', 1317, 1353),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Run a speed test for me when it settles.', 1354, 1401),
  (v_tr, v_call, 14, 'customer', 'Customer', 'It''s showing 268 now. That''s a huge difference.', 1402, 1459),
  (v_tr, v_call, 15, 'agent', 'Agent', 'That''s what I''d expect. Second, I''ve pushed a channel optimisation to your router remotely, which should hold that speed during busy evenings.', 1460, 1609),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Anything else?', 1610, 1631),
  (v_tr, v_call, 17, 'customer', 'Customer', 'No, that''s it.', 1632, 1656),
  (v_tr, v_call, 18, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1657, 1734);

-- NW-20260724-0029 · Rahul Menon · billing_double_charge
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260724-0029', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-62383', 'inbound',
  'phone', 'seed', 'en', '2026-07-24T18:12:45+00:00',
  '2026-07-24T18:21:15+00:00', 510, 'transcribed',
  '{"scenario": "billing_double_charge", "intent": "billing_dispute", "topics": ["billing", "duplicate_charge", "refund"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "mid", "resolution": "mid", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?
Customer: I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: I can see both transactions here, both on the 3rd. Looking at the payment log, your auto-debit mandate fired and then a manual payment was also processed from the app about four minutes later. So this is a duplicate, not a pricing change on your plan.
Customer: I did tap pay in the app because it showed as pending.
Agent: That explains it exactly, and that pending display is a known lag on our side. The charge is genuinely duplicated and you''re owed it back.
Agent: One moment.
Agent: Okay, I''m back.
Agent: I''ll raise a refund request. It should come back in a few days.
Customer: Okay.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 301, 20, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.', 97, 246),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 247, 381),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 382, 508),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 509, 570),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 571, 685),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 686, 708),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 709, 769),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I can see both transactions here, both on the 3rd. Looking at the payment log, your auto-debit mandate fired and then a manual payment was also processed from the app about four minutes later. So this is a duplicate, not a pricing change on your plan.', 770, 1028),
  (v_tr, v_call, 9, 'customer', 'Customer', 'I did tap pay in the app because it showed as pending.', 1029, 1093),
  (v_tr, v_call, 10, 'agent', 'Agent', 'That explains it exactly, and that pending display is a known lag on our side. The charge is genuinely duplicated and you''re owed it back.', 1094, 1239),
  (v_tr, v_call, 11, 'agent', 'Agent', 'One moment.', 1240, 1258),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Okay, I''m back.', 1259, 1281),
  (v_tr, v_call, 13, 'agent', 'Agent', 'I''ll raise a refund request. It should come back in a few days.', 1282, 1352),
  (v_tr, v_call, 14, 'customer', 'Customer', 'Okay.', 1353, 1368),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1369, 1450),
  (v_tr, v_call, 16, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1451, 1494),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1495, 1569),
  (v_tr, v_call, 18, 'customer', 'Customer', 'No, that''s everything.', 1570, 1602),
  (v_tr, v_call, 19, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1603, 1680);

-- NW-20260830-0030 · Arjun Deshmukh · tech_no_internet
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260830-0030', '22222222-2222-4222-8222-000000000004', '11111111-1111-4111-8111-000000000002', 'CUST-27477', 'inbound',
  'phone', 'seed', 'en', '2026-08-30T17:15:58+00:00',
  '2026-08-30T17:23:43+00:00', 465, 'transcribed',
  '{"scenario": "tech_no_internet", "intent": "service_outage", "topics": ["technical", "outage", "connectivity"], "agent_skill_profile": 0.78, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "mid", "diagnosis": "mid", "hold": "good", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Arjun speaking, the call is recorded. What can I do for you?
Customer: My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Let me check. Yes, there seems to be an issue in your area.
Customer: How long will it take?
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: The repair crew is already assigned, with an estimated restoration by 6pm today. I''m adding your number to the SMS notification list so you get a text the moment the link is back. I''m also applying a two-day service credit to your account automatically, you don''t need to claim it.
Customer: That''s really helpful, thank you.
Agent: If it isn''t back by 6pm, call us and quote reference NW-88214 and it goes straight to the field team without you repeating any of this.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 285, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Arjun speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.', 97, 251),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 252, 386),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 387, 437),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 438, 461),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 462, 483),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Let me check. Yes, there seems to be an issue in your area.', 484, 550),
  (v_tr, v_call, 7, 'customer', 'Customer', 'How long will it take?', 551, 583),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 584, 701),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Yes, that''s fine.', 702, 729),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 730, 813),
  (v_tr, v_call, 11, 'agent', 'Agent', 'The repair crew is already assigned, with an estimated restoration by 6pm today. I''m adding your number to the SMS notification list so you get a text the moment the link is back. I''m also applying a two-day service credit to your account automatically, you don''t need to claim it.', 814, 1102),
  (v_tr, v_call, 12, 'customer', 'Customer', 'That''s really helpful, thank you.', 1103, 1146),
  (v_tr, v_call, 13, 'agent', 'Agent', 'If it isn''t back by 6pm, call us and quote reference NW-88214 and it goes straight to the field team without you repeating any of this.', 1147, 1289),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Anything else?', 1290, 1311),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s it.', 1312, 1336),
  (v_tr, v_call, 16, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1337, 1597);

-- NW-20260803-0031 · Karan Malhotra · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260803-0031', '22222222-2222-4222-8222-000000000008', '11111111-1111-4111-8111-000000000003', 'CUST-46347', 'inbound',
  'phone', 'seed', 'en', '2026-08-03T16:16:48+00:00',
  '2026-08-03T16:21:48+00:00', 300, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.42, "ground_truth": {"greeting": "poor", "empathy": "poor", "verification": "mid", "diagnosis": "mid", "hold": "not_applicable", "resolution": "poor", "confirm": "mid", "closing": "poor"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Hello, support desk.
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: Okay. What''s the account number.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: I can show you our current plans.
Customer: Go ahead.
Agent: I''d stay on 300 personally. I''ll just renew you on the same thing.
Customer: I suppose that''s easiest.
Agent: Anything else?
Customer: No, that''s it.
Agent: Alright. Bye.', 87, 13, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Hello, support desk.', 0, 27),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 28, 131),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Okay. What''s the account number.', 132, 171),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 172, 222),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 223, 246),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 247, 268),
  (v_tr, v_call, 6, 'agent', 'Agent', 'I can show you our current plans.', 269, 309),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Go ahead.', 310, 329),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I''d stay on 300 personally. I''ll just renew you on the same thing.', 330, 403),
  (v_tr, v_call, 9, 'customer', 'Customer', 'I suppose that''s easiest.', 404, 439),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Anything else?', 440, 461),
  (v_tr, v_call, 11, 'customer', 'Customer', 'No, that''s it.', 462, 486),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Alright. Bye.', 487, 507);

-- NW-20260824-0032 · Meera Raghavan · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260824-0032', '22222222-2222-4222-8222-000000000009', '11111111-1111-4111-8111-000000000003', 'CUST-71069', 'inbound',
  'phone', 'seed', 'en', '2026-08-24T12:04:26+00:00',
  '2026-08-24T12:12:41+00:00', 495, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.92, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "good", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.
Customer: So I''m over-subscribed?
Agent: Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.
Customer: Let''s go with the 150. I''d rather save the money.
Agent: Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 434, 22, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 173, 276),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 277, 411),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 412, 538),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 539, 600),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 601, 715),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 716, 738),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 739, 799),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.', 800, 1087),
  (v_tr, v_call, 9, 'customer', 'Customer', 'So I''m over-subscribed?', 1088, 1121),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.', 1122, 1209),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 1210, 1327),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s fine.', 1328, 1355),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 1356, 1439),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.', 1440, 1751),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Let''s go with the 150. I''d rather save the money.', 1752, 1811),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.', 1812, 1990),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1991, 2072),
  (v_tr, v_call, 18, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 2073, 2116),
  (v_tr, v_call, 19, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 2117, 2191),
  (v_tr, v_call, 20, 'customer', 'Customer', 'No, that''s everything.', 2192, 2224),
  (v_tr, v_call, 21, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 2225, 2485);

-- NW-20260902-0033 · Ananya Bose · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260902-0033', '22222222-2222-4222-8222-000000000007', '11111111-1111-4111-8111-000000000003', 'CUST-80545', 'inbound',
  'phone', 'seed', 'en', '2026-09-02T14:19:48+00:00',
  '2026-09-02T14:25:32+00:00', 344, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.88, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "mid", "diagnosis": "good", "hold": "not_applicable", "resolution": "mid", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.
Customer: Honestly it''s the three outages in two months. I can''t work like that.
Agent: That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.
Agent: I can give you a discount if you stay.
Customer: How much?
Agent: Twenty percent for six months.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 245, 15, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 173),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 174, 267),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 268, 402),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 403, 453),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 454, 477),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 478, 499),
  (v_tr, v_call, 6, 'agent', 'Agent', 'I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.', 500, 720),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Honestly it''s the three outages in two months. I can''t work like that.', 721, 801),
  (v_tr, v_call, 8, 'agent', 'Agent', 'That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.', 802, 938),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I can give you a discount if you stay.', 939, 984),
  (v_tr, v_call, 10, 'customer', 'Customer', 'How much?', 985, 1004),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Twenty percent for six months.', 1005, 1042),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Anything else?', 1043, 1064),
  (v_tr, v_call, 13, 'customer', 'Customer', 'No, that''s it.', 1065, 1089),
  (v_tr, v_call, 14, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1090, 1350);

-- NW-20260825-0034 · Meera Raghavan · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260825-0034', '22222222-2222-4222-8222-000000000009', '11111111-1111-4111-8111-000000000003', 'CUST-83975', 'inbound',
  'phone', 'seed', 'en', '2026-08-25T18:34:01+00:00',
  '2026-08-25T18:42:54+00:00', 533, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.92, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "not_applicable", "resolution": "mid", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.
Customer: Honestly it''s the three outages in two months. I can''t work like that.
Agent: That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.
Agent: I can give you a discount if you stay.
Customer: How much?
Agent: Twenty percent for six months.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 298, 19, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 173, 266),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 267, 401),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 402, 528),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 529, 590),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 591, 705),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 706, 728),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 729, 789),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.', 790, 1010),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Honestly it''s the three outages in two months. I can''t work like that.', 1011, 1091),
  (v_tr, v_call, 10, 'agent', 'Agent', 'That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.', 1092, 1228),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I can give you a discount if you stay.', 1229, 1274),
  (v_tr, v_call, 12, 'customer', 'Customer', 'How much?', 1275, 1294),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Twenty percent for six months.', 1295, 1332),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1333, 1414),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1415, 1458),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1459, 1533),
  (v_tr, v_call, 17, 'customer', 'Customer', 'No, that''s everything.', 1534, 1566),
  (v_tr, v_call, 18, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1567, 1644);

-- NW-20260807-0035 · Priya Nair · billing_double_charge
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260807-0035', '22222222-2222-4222-8222-000000000001', '11111111-1111-4111-8111-000000000001', 'CUST-80702', 'inbound',
  'phone', 'seed', 'en', '2026-08-07T13:53:05+00:00',
  '2026-08-07T14:01:06+00:00', 481, 'transcribed',
  '{"scenario": "billing_double_charge", "intent": "billing_dispute", "topics": ["billing", "duplicate_charge", "refund"], "agent_skill_profile": 0.85, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "good", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: I can see both transactions here, both on the 3rd. Looking at the payment log, your auto-debit mandate fired and then a manual payment was also processed from the app about four minutes later. So this is a duplicate, not a pricing change on your plan.
Customer: I did tap pay in the app because it showed as pending.
Agent: That explains it exactly, and that pending display is a known lag on our side. The charge is genuinely duplicated and you''re owed it back.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I''m raising a duplicate payment reversal for 1,299 now. That goes back to the original card and takes three working days. Your next invoice on the 3rd of October will be the normal 1,299, with no adjustment needed.
Customer: And I don''t need to do anything?
Agent: Nothing at all. I''ll also send you the reference number by email so you have it in writing.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 397, 20, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.', 173, 322),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 323, 457),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 458, 584),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 585, 646),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 647, 761),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 762, 784),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 785, 845),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I can see both transactions here, both on the 3rd. Looking at the payment log, your auto-debit mandate fired and then a manual payment was also processed from the app about four minutes later. So this is a duplicate, not a pricing change on your plan.', 846, 1104),
  (v_tr, v_call, 9, 'customer', 'Customer', 'I did tap pay in the app because it showed as pending.', 1105, 1169),
  (v_tr, v_call, 10, 'agent', 'Agent', 'That explains it exactly, and that pending display is a known lag on our side. The charge is genuinely duplicated and you''re owed it back.', 1170, 1315),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 1316, 1433),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s fine.', 1434, 1461),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 1462, 1545),
  (v_tr, v_call, 14, 'agent', 'Agent', 'I''m raising a duplicate payment reversal for 1,299 now. That goes back to the original card and takes three working days. Your next invoice on the 3rd of October will be the normal 1,299, with no adjustment needed.', 1546, 1767),
  (v_tr, v_call, 15, 'customer', 'Customer', 'And I don''t need to do anything?', 1768, 1810),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Nothing at all. I''ll also send you the reference number by email so you have it in writing.', 1811, 1909),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Anything else?', 1910, 1931),
  (v_tr, v_call, 18, 'customer', 'Customer', 'No, that''s it.', 1932, 1956),
  (v_tr, v_call, 19, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1957, 2217);

-- NW-20260803-0036 · Priya Nair · billing_plan_change
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260803-0036', '22222222-2222-4222-8222-000000000001', '11111111-1111-4111-8111-000000000001', 'CUST-58351', 'inbound',
  'phone', 'seed', 'en', '2026-08-03T10:36:13+00:00',
  '2026-08-03T10:43:21+00:00', 428, 'transcribed',
  '{"scenario": "billing_plan_change", "intent": "plan_enquiry", "topics": ["billing", "plan_change", "pricing"], "agent_skill_profile": 0.85, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "mid", "diagnosis": "good", "hold": "good", "resolution": "mid", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My bill went up by 400 rupees this month and nobody told me it was going to change.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Let me walk you through the invoice line by line. Your promotional rate of 899 ran for twelve months and ended on the 15th of last month, so this invoice has fifteen days at the promo rate and fifteen at the standard 1,299. That''s why it looks like an odd number rather than a clean increase.
Customer: I don''t remember being told the promo was ending.
Agent: I can see a notification was sent to your registered email on the 1st, but I completely understand those are easy to miss, and I''m not going to argue that point with you.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I can offer you a discounted rate of 1,099 if you want.
Customer: Fine, do that.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 337, 19, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My bill went up by 400 rupees this month and nobody told me it was going to change.', 173, 266),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 267, 401),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 402, 452),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 453, 476),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 477, 498),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Let me walk you through the invoice line by line. Your promotional rate of 899 ran for twelve months and ended on the 15th of last month, so this invoice has fifteen days at the promo rate and fifteen at the standard 1,299. That''s why it looks like an odd number rather than a clean increase.', 499, 798),
  (v_tr, v_call, 7, 'customer', 'Customer', 'I don''t remember being told the promo was ending.', 799, 858),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I can see a notification was sent to your registered email on the 1st, but I completely understand those are easy to miss, and I''m not going to argue that point with you.', 859, 1036),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 1037, 1154),
  (v_tr, v_call, 10, 'customer', 'Customer', 'Yes, that''s fine.', 1155, 1182),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 1183, 1266),
  (v_tr, v_call, 12, 'agent', 'Agent', 'I can offer you a discounted rate of 1,099 if you want.', 1267, 1329),
  (v_tr, v_call, 13, 'customer', 'Customer', 'Fine, do that.', 1330, 1354),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1355, 1436),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1437, 1480),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1481, 1555),
  (v_tr, v_call, 17, 'customer', 'Customer', 'No, that''s everything.', 1556, 1588),
  (v_tr, v_call, 18, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1589, 1849);

-- NW-20260809-0037 · Sneha Kulkarni · billing_refund_status
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260809-0037', '22222222-2222-4222-8222-000000000003', '11111111-1111-4111-8111-000000000001', 'CUST-92213', 'inbound',
  'phone', 'seed', 'en', '2026-08-09T15:45:12+00:00',
  '2026-08-09T15:51:34+00:00', 382, 'transcribed',
  '{"scenario": "billing_refund_status", "intent": "refund_status", "topics": ["billing", "refund", "follow_up"], "agent_skill_profile": 0.9, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "mid", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Sneha. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Let me check. It seems it hasn''t been processed yet.
Customer: Why not?
Agent: I''m not sure.
Agent: I''m re-issuing it to your current card now and marking it priority, which brings it to twenty-four hours rather than three days. I''m also adding a 300 rupee credit for the inconvenience of three calls, applied immediately. Reference NW-90118.
Customer: I appreciate that, thank you.
Agent: And I''ve set a reminder on my side to verify it landed tomorrow. If it hasn''t, you''ll get a call from us rather than you having to chase again.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 325, 19, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Sneha. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.', 173, 296),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 297, 431),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 432, 558),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 559, 620),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 621, 735),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 736, 758),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 759, 819),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Let me check. It seems it hasn''t been processed yet.', 820, 879),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Why not?', 880, 898),
  (v_tr, v_call, 10, 'agent', 'Agent', 'I''m not sure.', 899, 919),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I''m re-issuing it to your current card now and marking it priority, which brings it to twenty-four hours rather than three days. I''m also adding a 300 rupee credit for the inconvenience of three calls, applied immediately. Reference NW-90118.', 920, 1169),
  (v_tr, v_call, 12, 'customer', 'Customer', 'I appreciate that, thank you.', 1170, 1209),
  (v_tr, v_call, 13, 'agent', 'Agent', 'And I''ve set a reminder on my side to verify it landed tomorrow. If it hasn''t, you''ll get a call from us rather than you having to chase again.', 1210, 1360),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1361, 1442),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1443, 1486),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1487, 1561),
  (v_tr, v_call, 17, 'customer', 'Customer', 'No, that''s everything.', 1562, 1594),
  (v_tr, v_call, 18, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1595, 1855);

-- NW-20260810-0038 · Arjun Deshmukh · tech_no_internet
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260810-0038', '22222222-2222-4222-8222-000000000004', '11111111-1111-4111-8111-000000000002', 'CUST-74251', 'inbound',
  'phone', 'seed', 'en', '2026-08-10T10:32:41+00:00',
  '2026-08-10T10:38:37+00:00', 356, 'transcribed',
  '{"scenario": "tech_no_internet", "intent": "service_outage", "topics": ["technical", "outage", "connectivity"], "agent_skill_profile": 0.78, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "mid", "diagnosis": "mid", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Arjun speaking, the call is recorded. What can I do for you?
Customer: My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Let me check. Yes, there seems to be an issue in your area.
Customer: How long will it take?
Agent: The repair crew is already assigned, with an estimated restoration by 6pm today. I''m adding your number to the SMS notification list so you get a text the moment the link is back. I''m also applying a two-day service credit to your account automatically, you don''t need to claim it.
Customer: That''s really helpful, thank you.
Agent: If it isn''t back by 6pm, call us and quote reference NW-88214 and it goes straight to the field team without you repeating any of this.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 276, 16, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Arjun speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.', 97, 251),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 252, 386),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 387, 437),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 438, 461),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 462, 483),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Let me check. Yes, there seems to be an issue in your area.', 484, 550),
  (v_tr, v_call, 7, 'customer', 'Customer', 'How long will it take?', 551, 583),
  (v_tr, v_call, 8, 'agent', 'Agent', 'The repair crew is already assigned, with an estimated restoration by 6pm today. I''m adding your number to the SMS notification list so you get a text the moment the link is back. I''m also applying a two-day service credit to your account automatically, you don''t need to claim it.', 584, 872),
  (v_tr, v_call, 9, 'customer', 'Customer', 'That''s really helpful, thank you.', 873, 916),
  (v_tr, v_call, 10, 'agent', 'Agent', 'If it isn''t back by 6pm, call us and quote reference NW-88214 and it goes straight to the field team without you repeating any of this.', 917, 1059),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1060, 1141),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1142, 1185),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1186, 1260),
  (v_tr, v_call, 14, 'customer', 'Customer', 'No, that''s everything.', 1261, 1293),
  (v_tr, v_call, 15, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1294, 1554);

-- NW-20260730-0039 · Rahul Menon · billing_plan_change
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260730-0039', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-45179', 'inbound',
  'phone', 'seed', 'en', '2026-07-30T16:29:27+00:00',
  '2026-07-30T16:37:16+00:00', 469, 'transcribed',
  '{"scenario": "billing_plan_change", "intent": "plan_enquiry", "topics": ["billing", "plan_change", "pricing"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "poor", "empathy": "mid", "verification": "mid", "diagnosis": "mid", "hold": "mid", "resolution": "poor", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Hello, support desk.
Customer: My bill went up by 400 rupees this month and nobody told me it was going to change.
Agent: Sorry about that. Let me check.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Your promotional pricing expired. That''s the standard rate now.
Customer: Nobody told me.
Agent: One moment.
Agent: Okay, I''m back.
Agent: I''ll definitely get that refunded for you, I guarantee it''ll be back by tomorrow.
Customer: Okay, thank you.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 139, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Hello, support desk.', 0, 27),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My bill went up by 400 rupees this month and nobody told me it was going to change.', 28, 121),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 122, 160),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 161, 211),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 212, 235),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 236, 257),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Your promotional pricing expired. That''s the standard rate now.', 258, 328),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Nobody told me.', 329, 354),
  (v_tr, v_call, 8, 'agent', 'Agent', 'One moment.', 355, 373),
  (v_tr, v_call, 9, 'agent', 'Agent', 'Okay, I''m back.', 374, 396),
  (v_tr, v_call, 10, 'agent', 'Agent', 'I''ll definitely get that refunded for you, I guarantee it''ll be back by tomorrow.', 397, 485),
  (v_tr, v_call, 11, 'customer', 'Customer', 'Okay, thank you.', 486, 512),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 513, 594),
  (v_tr, v_call, 13, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 595, 638),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 639, 713),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s everything.', 714, 746),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 747, 824);

-- NW-20260822-0040 · Vikram Iyer · tech_no_internet
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260822-0040', '22222222-2222-4222-8222-000000000006', '11111111-1111-4111-8111-000000000002', 'CUST-46655', 'inbound',
  'phone', 'seed', 'en', '2026-08-22T16:13:22+00:00',
  '2026-08-22T16:21:38+00:00', 496, 'transcribed',
  '{"scenario": "tech_no_internet", "intent": "service_outage", "topics": ["technical", "outage", "connectivity"], "agent_skill_profile": 0.7, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "mid", "diagnosis": "good", "hold": "mid", "resolution": "good", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Vikram speaking, the call is recorded. What can I do for you?
Customer: My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: A red light on that model usually means the fibre link itself is down rather than your wifi. Let me check the line status from our side. I can see your ONT last registered at 7:42pm yesterday and hasn''t come back since.
Customer: So it''s not something in my house?
Agent: Correct, and I want to be clear about that so you''re not troubleshooting things that can''t be the cause. There''s a confirmed fibre break affecting your distribution point, and you''re one of forty-one customers on it.
Agent: One moment.
Agent: Okay, I''m back.
Agent: The repair crew is already assigned, with an estimated restoration by 6pm today. I''m adding your number to the SMS notification list so you get a text the moment the link is back. I''m also applying a two-day service credit to your account automatically, you don''t need to claim it.
Customer: That''s really helpful, thank you.
Agent: If it isn''t back by 6pm, call us and quote reference NW-88214 and it goes straight to the field team without you repeating any of this.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 321, 19, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Vikram speaking, the call is recorded. What can I do for you?', 0, 97),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.', 98, 252),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 253, 387),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 388, 438),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 439, 462),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 463, 484),
  (v_tr, v_call, 6, 'agent', 'Agent', 'A red light on that model usually means the fibre link itself is down rather than your wifi. Let me check the line status from our side. I can see your ONT last registered at 7:42pm yesterday and hasn''t come back since.', 485, 711),
  (v_tr, v_call, 7, 'customer', 'Customer', 'So it''s not something in my house?', 712, 756),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Correct, and I want to be clear about that so you''re not troubleshooting things that can''t be the cause. There''s a confirmed fibre break affecting your distribution point, and you''re one of forty-one customers on it.', 757, 980),
  (v_tr, v_call, 9, 'agent', 'Agent', 'One moment.', 981, 999),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Okay, I''m back.', 1000, 1022),
  (v_tr, v_call, 11, 'agent', 'Agent', 'The repair crew is already assigned, with an estimated restoration by 6pm today. I''m adding your number to the SMS notification list so you get a text the moment the link is back. I''m also applying a two-day service credit to your account automatically, you don''t need to claim it.', 1023, 1311),
  (v_tr, v_call, 12, 'customer', 'Customer', 'That''s really helpful, thank you.', 1312, 1355),
  (v_tr, v_call, 13, 'agent', 'Agent', 'If it isn''t back by 6pm, call us and quote reference NW-88214 and it goes straight to the field team without you repeating any of this.', 1356, 1498),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1499, 1580),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1581, 1624),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1625, 1699),
  (v_tr, v_call, 17, 'customer', 'Customer', 'No, that''s everything.', 1700, 1732),
  (v_tr, v_call, 18, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1733, 1810);

-- NW-20260901-0041 · Fatima Sheikh · tech_router_setup
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260901-0041', '22222222-2222-4222-8222-000000000005', '11111111-1111-4111-8111-000000000002', 'CUST-50135', 'inbound',
  'phone', 'seed', 'en', '2026-09-01T10:18:14+00:00',
  '2026-09-01T10:24:49+00:00', 395, 'transcribed',
  '{"scenario": "tech_router_setup", "intent": "setup_assistance", "topics": ["technical", "installation", "router"], "agent_skill_profile": 0.48, "ground_truth": {"greeting": "good", "empathy": "poor", "verification": "good", "diagnosis": "mid", "hold": "mid", "resolution": "mid", "confirm": "mid", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Fatima. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.
Agent: Okay. What''s the account number.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: What lights are showing?
Customer: Green and orange.
Agent: Check the cable is in the right port.
Agent: One moment.
Agent: Okay, I''m back.
Agent: Move the cable to the blue port and it should work.
Customer: Okay, I''ll try.
Agent: Anything else?
Customer: No, that''s it.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 186, 18, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Fatima. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 173),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.', 174, 286),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Okay. What''s the account number.', 287, 326),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 327, 453),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 454, 515),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 516, 630),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 631, 653),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 654, 714),
  (v_tr, v_call, 8, 'agent', 'Agent', 'What lights are showing?', 715, 746),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Green and orange.', 747, 774),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Check the cable is in the right port.', 775, 819),
  (v_tr, v_call, 11, 'agent', 'Agent', 'One moment.', 820, 838),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Okay, I''m back.', 839, 861),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Move the cable to the blue port and it should work.', 862, 920),
  (v_tr, v_call, 14, 'customer', 'Customer', 'Okay, I''ll try.', 921, 946),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Anything else?', 947, 968),
  (v_tr, v_call, 16, 'customer', 'Customer', 'No, that''s it.', 969, 993),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 994, 1071);

-- NW-20260813-0042 · Vikram Iyer · tech_slow_speed
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260813-0042', '22222222-2222-4222-8222-000000000006', '11111111-1111-4111-8111-000000000002', 'CUST-34267', 'inbound',
  'phone', 'seed', 'en', '2026-08-13T10:47:34+00:00',
  '2026-08-13T10:57:33+00:00', 599, 'transcribed',
  '{"scenario": "tech_slow_speed", "intent": "performance_complaint", "topics": ["technical", "speed", "wifi"], "agent_skill_profile": 0.7, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "mid", "diagnosis": "mid", "hold": "good", "resolution": "good", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Vikram speaking, the call is recorded. What can I do for you?
Customer: I''m paying for 300 megabits but I''m getting about 40 on my laptop. This has been going on for two weeks.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Your line looks fine on our end. It''s probably your wifi.
Customer: So what do I do?
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: Two steps. First, on your laptop, connect to the network ending -5G instead of the plain one. Can you see that option now?
Customer: Yes, I''m connecting to it.
Agent: Run a speed test for me when it settles.
Customer: It''s showing 268 now. That''s a huge difference.
Agent: That''s what I''d expect. Second, I''ve pushed a channel optimisation to your router remotely, which should hold that speed during busy evenings.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 268, 21, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Vikram speaking, the call is recorded. What can I do for you?', 0, 97),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''m paying for 300 megabits but I''m getting about 40 on my laptop. This has been going on for two weeks.', 98, 212),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 213, 347),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 348, 398),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 399, 422),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 423, 444),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Your line looks fine on our end. It''s probably your wifi.', 445, 509),
  (v_tr, v_call, 7, 'customer', 'Customer', 'So what do I do?', 510, 536),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 537, 654),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Yes, that''s fine.', 655, 682),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 683, 766),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Two steps. First, on your laptop, connect to the network ending -5G instead of the plain one. Can you see that option now?', 767, 896),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, I''m connecting to it.', 897, 933),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Run a speed test for me when it settles.', 934, 981),
  (v_tr, v_call, 14, 'customer', 'Customer', 'It''s showing 268 now. That''s a huge difference.', 982, 1039),
  (v_tr, v_call, 15, 'agent', 'Agent', 'That''s what I''d expect. Second, I''ve pushed a channel optimisation to your router remotely, which should hold that speed during busy evenings.', 1040, 1189),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1190, 1271),
  (v_tr, v_call, 17, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1272, 1315),
  (v_tr, v_call, 18, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1316, 1390),
  (v_tr, v_call, 19, 'customer', 'Customer', 'No, that''s everything.', 1391, 1423),
  (v_tr, v_call, 20, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1424, 1501);

-- NW-20260810-0043 · Arjun Deshmukh · tech_no_internet
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260810-0043', '22222222-2222-4222-8222-000000000004', '11111111-1111-4111-8111-000000000002', 'CUST-45954', 'inbound',
  'phone', 'seed', 'en', '2026-08-10T11:19:00+00:00',
  '2026-08-10T11:25:37+00:00', 397, 'transcribed',
  '{"scenario": "tech_no_internet", "intent": "service_outage", "topics": ["technical", "outage", "connectivity"], "agent_skill_profile": 0.78, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "good", "diagnosis": "mid", "hold": "not_applicable", "resolution": "mid", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Arjun speaking, the call is recorded. What can I do for you?
Customer: My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Let me check. Yes, there seems to be an issue in your area.
Customer: How long will it take?
Agent: I''ve logged a fault. Engineering will look at it.
Customer: When?
Agent: I can''t give an exact time.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 228, 16, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Arjun speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.', 97, 251),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 252, 386),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 387, 513),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 514, 575),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 576, 690),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 691, 713),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 714, 774),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Let me check. Yes, there seems to be an issue in your area.', 775, 841),
  (v_tr, v_call, 9, 'customer', 'Customer', 'How long will it take?', 842, 874),
  (v_tr, v_call, 10, 'agent', 'Agent', 'I''ve logged a fault. Engineering will look at it.', 875, 931),
  (v_tr, v_call, 11, 'customer', 'Customer', 'When?', 932, 947),
  (v_tr, v_call, 12, 'agent', 'Agent', 'I can''t give an exact time.', 948, 982),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Anything else?', 983, 1004),
  (v_tr, v_call, 14, 'customer', 'Customer', 'No, that''s it.', 1005, 1029),
  (v_tr, v_call, 15, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1030, 1290);

-- NW-20260822-0044 · Priya Nair · billing_double_charge
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260822-0044', '22222222-2222-4222-8222-000000000001', '11111111-1111-4111-8111-000000000001', 'CUST-62521', 'inbound',
  'phone', 'seed', 'en', '2026-08-22T09:16:55+00:00',
  '2026-08-22T09:24:14+00:00', 439, 'transcribed',
  '{"scenario": "billing_double_charge", "intent": "billing_dispute", "topics": ["billing", "duplicate_charge", "refund"], "agent_skill_profile": 0.85, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "mid", "hold": "mid", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Yes, I can see two payments. It looks like a duplicate.
Customer: So what happens now?
Agent: One moment.
Agent: Okay, I''m back.
Agent: I''m raising a duplicate payment reversal for 1,299 now. That goes back to the original card and takes three working days. Your next invoice on the 3rd of October will be the normal 1,299, with no adjustment needed.
Customer: And I don''t need to do anything?
Agent: Nothing at all. I''ll also send you the reference number by email so you have it in writing.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 326, 20, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.', 173, 322),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 323, 457),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 458, 584),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 585, 646),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 647, 761),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 762, 784),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 785, 845),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Yes, I can see two payments. It looks like a duplicate.', 846, 908),
  (v_tr, v_call, 9, 'customer', 'Customer', 'So what happens now?', 909, 939),
  (v_tr, v_call, 10, 'agent', 'Agent', 'One moment.', 940, 958),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Okay, I''m back.', 959, 981),
  (v_tr, v_call, 12, 'agent', 'Agent', 'I''m raising a duplicate payment reversal for 1,299 now. That goes back to the original card and takes three working days. Your next invoice on the 3rd of October will be the normal 1,299, with no adjustment needed.', 982, 1203),
  (v_tr, v_call, 13, 'customer', 'Customer', 'And I don''t need to do anything?', 1204, 1246),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Nothing at all. I''ll also send you the reference number by email so you have it in writing.', 1247, 1345),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1346, 1427),
  (v_tr, v_call, 16, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1428, 1471),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1472, 1546),
  (v_tr, v_call, 18, 'customer', 'Customer', 'No, that''s everything.', 1547, 1579),
  (v_tr, v_call, 19, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1580, 1840);

-- NW-20260807-0045 · Karan Malhotra · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260807-0045', '22222222-2222-4222-8222-000000000008', '11111111-1111-4111-8111-000000000003', 'CUST-78494', 'inbound',
  'phone', 'seed', 'en', '2026-08-07T18:38:50+00:00',
  '2026-08-07T18:46:16+00:00', 446, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.42, "ground_truth": {"greeting": "mid", "empathy": "mid", "verification": "good", "diagnosis": "poor", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Karan speaking, the call is recorded. What can I do for you?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: Sorry about that. Let me check.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Okay, I''ll process the cancellation. There''s a 2,000 rupee early termination fee.
Agent: I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.
Customer: That''s more reasonable than I expected. Let me take the two months.
Agent: Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 289, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Karan speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 97, 190),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 191, 229),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 230, 356),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 357, 418),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 419, 533),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 534, 556),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 557, 617),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Okay, I''ll process the cancellation. There''s a 2,000 rupee early termination fee.', 618, 706),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.', 707, 1137),
  (v_tr, v_call, 10, 'customer', 'Customer', 'That''s more reasonable than I expected. Let me take the two months.', 1138, 1215),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.', 1216, 1350),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1351, 1432),
  (v_tr, v_call, 13, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1433, 1476),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1477, 1551),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s everything.', 1552, 1584),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1585, 1662);

-- NW-20260820-0046 · Ananya Bose · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260820-0046', '22222222-2222-4222-8222-000000000007', '11111111-1111-4111-8111-000000000003', 'CUST-32782', 'inbound',
  'phone', 'seed', 'en', '2026-08-20T12:16:42+00:00',
  '2026-08-20T12:22:02+00:00', 320, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.88, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "not_applicable", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Ananya speaking, the call is recorded. What can I do for you?
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.
Customer: So I''m over-subscribed?
Agent: Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.
Agent: Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.
Customer: Let''s go with the 150. I''d rather save the money.
Agent: Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 345, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Ananya speaking, the call is recorded. What can I do for you?', 0, 97),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 98, 201),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 202, 336),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 337, 463),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 464, 525),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 526, 640),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 641, 663),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 664, 724),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.', 725, 1012),
  (v_tr, v_call, 9, 'customer', 'Customer', 'So I''m over-subscribed?', 1013, 1046),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.', 1047, 1134),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.', 1135, 1446),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Let''s go with the 150. I''d rather save the money.', 1447, 1506),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.', 1507, 1685),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Anything else?', 1686, 1707),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s it.', 1708, 1732),
  (v_tr, v_call, 16, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1733, 1993);

-- NW-20260819-0047 · Meera Raghavan · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260819-0047', '22222222-2222-4222-8222-000000000009', '11111111-1111-4111-8111-000000000003', 'CUST-35928', 'inbound',
  'phone', 'seed', 'en', '2026-08-19T13:50:50+00:00',
  '2026-08-19T13:59:17+00:00', 507, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.92, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "good", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.
Customer: Honestly it''s the three outages in two months. I can''t work like that.
Agent: That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.
Customer: That''s more reasonable than I expected. Let me take the two months.
Agent: Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 433, 20, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 173, 266),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 267, 401),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 402, 528),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 529, 590),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 591, 705),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 706, 728),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 729, 789),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.', 790, 1010),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Honestly it''s the three outages in two months. I can''t work like that.', 1011, 1091),
  (v_tr, v_call, 10, 'agent', 'Agent', 'That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.', 1092, 1228),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 1229, 1346),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s fine.', 1347, 1374),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 1375, 1458),
  (v_tr, v_call, 14, 'agent', 'Agent', 'I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.', 1459, 1889),
  (v_tr, v_call, 15, 'customer', 'Customer', 'That''s more reasonable than I expected. Let me take the two months.', 1890, 1967),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.', 1968, 2102),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Anything else?', 2103, 2124),
  (v_tr, v_call, 18, 'customer', 'Customer', 'No, that''s it.', 2125, 2149),
  (v_tr, v_call, 19, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 2150, 2410);

-- NW-20260815-0048 · Ananya Bose · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260815-0048', '22222222-2222-4222-8222-000000000007', '11111111-1111-4111-8111-000000000003', 'CUST-62757', 'inbound',
  'phone', 'seed', 'en', '2026-08-15T16:07:29+00:00',
  '2026-08-15T16:15:02+00:00', 453, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.88, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "mid", "diagnosis": "mid", "hold": "good", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Can I ask why you''re leaving?
Customer: Too many outages.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.
Customer: That''s more reasonable than I expected. Let me take the two months.
Agent: Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 311, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 173),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 174, 267),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 268, 402),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 403, 453),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 454, 477),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 478, 499),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Can I ask why you''re leaving?', 500, 536),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Too many outages.', 537, 564),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 565, 682),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Yes, that''s fine.', 683, 710),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 711, 794),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.', 795, 1225),
  (v_tr, v_call, 12, 'customer', 'Customer', 'That''s more reasonable than I expected. Let me take the two months.', 1226, 1303),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.', 1304, 1438),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Anything else?', 1439, 1460),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s it.', 1461, 1485),
  (v_tr, v_call, 16, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1486, 1746);

-- NW-20260728-0049 · Fatima Sheikh · tech_router_setup
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260728-0049', '22222222-2222-4222-8222-000000000005', '11111111-1111-4111-8111-000000000002', 'CUST-85529', 'inbound',
  'phone', 'seed', 'en', '2026-07-28T18:01:48+00:00',
  '2026-07-28T18:07:43+00:00', 355, 'transcribed',
  '{"scenario": "tech_router_setup", "intent": "setup_assistance", "topics": ["technical", "installation", "router"], "agent_skill_profile": 0.48, "ground_truth": {"greeting": "mid", "empathy": "mid", "verification": "mid", "diagnosis": "poor", "hold": "not_applicable", "resolution": "mid", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Fatima speaking, the call is recorded. What can I do for you?
Customer: I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.
Agent: Sorry about that. Let me check.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: It should be plug and play. Just follow the leaflet in the box.
Agent: Move the cable to the blue port and it should work.
Customer: Okay, I''ll try.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 175, 14, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Fatima speaking, the call is recorded. What can I do for you?', 0, 97),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.', 98, 210),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 211, 249),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 250, 300),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 301, 324),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 325, 346),
  (v_tr, v_call, 6, 'agent', 'Agent', 'It should be plug and play. Just follow the leaflet in the box.', 347, 417),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Move the cable to the blue port and it should work.', 418, 476),
  (v_tr, v_call, 8, 'customer', 'Customer', 'Okay, I''ll try.', 477, 502),
  (v_tr, v_call, 9, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 503, 584),
  (v_tr, v_call, 10, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 585, 628),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 629, 703),
  (v_tr, v_call, 12, 'customer', 'Customer', 'No, that''s everything.', 704, 736),
  (v_tr, v_call, 13, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 737, 997);

-- NW-20260811-0050 · Priya Nair · billing_double_charge
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260811-0050', '22222222-2222-4222-8222-000000000001', '11111111-1111-4111-8111-000000000001', 'CUST-53228', 'inbound',
  'phone', 'seed', 'en', '2026-08-11T15:21:20+00:00',
  '2026-08-11T15:28:15+00:00', 415, 'transcribed',
  '{"scenario": "billing_double_charge", "intent": "billing_dispute", "topics": ["billing", "duplicate_charge", "refund"], "agent_skill_profile": 0.85, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "mid", "diagnosis": "good", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: I can see both transactions here, both on the 3rd. Looking at the payment log, your auto-debit mandate fired and then a manual payment was also processed from the app about four minutes later. So this is a duplicate, not a pricing change on your plan.
Customer: I did tap pay in the app because it showed as pending.
Agent: That explains it exactly, and that pending display is a known lag on our side. The charge is genuinely duplicated and you''re owed it back.
Agent: I''m raising a duplicate payment reversal for 1,299 now. That goes back to the original card and takes three working days. Your next invoice on the 3rd of October will be the normal 1,299, with no adjustment needed.
Customer: And I don''t need to do anything?
Agent: Nothing at all. I''ll also send you the reference number by email so you have it in writing.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 338, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.', 173, 322),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 323, 457),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 458, 508),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 509, 532),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 533, 554),
  (v_tr, v_call, 6, 'agent', 'Agent', 'I can see both transactions here, both on the 3rd. Looking at the payment log, your auto-debit mandate fired and then a manual payment was also processed from the app about four minutes later. So this is a duplicate, not a pricing change on your plan.', 555, 813),
  (v_tr, v_call, 7, 'customer', 'Customer', 'I did tap pay in the app because it showed as pending.', 814, 878),
  (v_tr, v_call, 8, 'agent', 'Agent', 'That explains it exactly, and that pending display is a known lag on our side. The charge is genuinely duplicated and you''re owed it back.', 879, 1024),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I''m raising a duplicate payment reversal for 1,299 now. That goes back to the original card and takes three working days. Your next invoice on the 3rd of October will be the normal 1,299, with no adjustment needed.', 1025, 1246),
  (v_tr, v_call, 10, 'customer', 'Customer', 'And I don''t need to do anything?', 1247, 1289),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Nothing at all. I''ll also send you the reference number by email so you have it in writing.', 1290, 1388),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1389, 1470),
  (v_tr, v_call, 13, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1471, 1514),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1515, 1589),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s everything.', 1590, 1622),
  (v_tr, v_call, 16, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1623, 1883);

-- NW-20260801-0051 · Ananya Bose · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260801-0051', '22222222-2222-4222-8222-000000000007', '11111111-1111-4111-8111-000000000003', 'CUST-17104', 'inbound',
  'phone', 'seed', 'en', '2026-08-01T09:42:55+00:00',
  '2026-08-01T09:50:06+00:00', 431, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.88, "ground_truth": {"greeting": "good", "empathy": "mid", "verification": "mid", "diagnosis": "good", "hold": "good", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: Sorry about that. Let me check.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.
Customer: So I''m over-subscribed?
Agent: Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.
Customer: Let''s go with the 150. I''d rather save the money.
Agent: Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 330, 18, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 173),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 174, 277),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 278, 316),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 317, 367),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 368, 391),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 392, 413),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.', 414, 701),
  (v_tr, v_call, 7, 'customer', 'Customer', 'So I''m over-subscribed?', 702, 735),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.', 736, 823),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 824, 941),
  (v_tr, v_call, 10, 'customer', 'Customer', 'Yes, that''s fine.', 942, 969),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 970, 1053),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.', 1054, 1365),
  (v_tr, v_call, 13, 'customer', 'Customer', 'Let''s go with the 150. I''d rather save the money.', 1366, 1425),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.', 1426, 1604),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Anything else?', 1605, 1626),
  (v_tr, v_call, 16, 'customer', 'Customer', 'No, that''s it.', 1627, 1651),
  (v_tr, v_call, 17, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1652, 1912);

-- NW-20260826-0052 · Arjun Deshmukh · tech_router_setup
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260826-0052', '22222222-2222-4222-8222-000000000004', '11111111-1111-4111-8111-000000000002', 'CUST-30758', 'inbound',
  'phone', 'seed', 'en', '2026-08-26T09:40:38+00:00',
  '2026-08-26T09:50:06+00:00', 568, 'transcribed',
  '{"scenario": "tech_router_setup", "intent": "setup_assistance", "topics": ["technical", "installation", "router"], "agent_skill_profile": 0.78, "ground_truth": {"greeting": "good", "empathy": "mid", "verification": "good", "diagnosis": "mid", "hold": "good", "resolution": "mid", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Arjun. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.
Agent: Sorry about that. Let me check.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: What lights are showing?
Customer: Green and orange.
Agent: Check the cable is in the right port.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: Move the cable to the blue port and it should work.
Customer: Okay, I''ll try.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 255, 21, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Arjun. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.', 173, 285),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 286, 324),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 325, 451),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 452, 513),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 514, 628),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 629, 651),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 652, 712),
  (v_tr, v_call, 8, 'agent', 'Agent', 'What lights are showing?', 713, 744),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Green and orange.', 745, 772),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Check the cable is in the right port.', 773, 817),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 818, 935),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s fine.', 936, 963),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 964, 1047),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Move the cable to the blue port and it should work.', 1048, 1106),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Okay, I''ll try.', 1107, 1132),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1133, 1214),
  (v_tr, v_call, 17, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1215, 1258),
  (v_tr, v_call, 18, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1259, 1333),
  (v_tr, v_call, 19, 'customer', 'Customer', 'No, that''s everything.', 1334, 1366),
  (v_tr, v_call, 20, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1367, 1444);

-- NW-20260815-0053 · Fatima Sheikh · tech_router_setup
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260815-0053', '22222222-2222-4222-8222-000000000005', '11111111-1111-4111-8111-000000000002', 'CUST-71894', 'inbound',
  'phone', 'seed', 'en', '2026-08-15T17:45:17+00:00',
  '2026-08-15T17:51:29+00:00', 372, 'transcribed',
  '{"scenario": "tech_router_setup", "intent": "setup_assistance", "topics": ["technical", "installation", "router"], "agent_skill_profile": 0.48, "ground_truth": {"greeting": "good", "empathy": "mid", "verification": "good", "diagnosis": "poor", "hold": "poor", "resolution": "mid", "confirm": "good", "closing": "poor"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Fatima. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.
Agent: Sorry about that. Let me check.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: It should be plug and play. Just follow the leaflet in the box.
Agent: Move the cable to the blue port and it should work.
Customer: Okay, I''ll try.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Alright. Bye.', 200, 16, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Fatima. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 173),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.', 174, 286),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 287, 325),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 326, 452),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 453, 514),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 515, 629),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 630, 652),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 653, 713),
  (v_tr, v_call, 8, 'agent', 'Agent', 'It should be plug and play. Just follow the leaflet in the box.', 714, 784),
  (v_tr, v_call, 9, 'agent', 'Agent', 'Move the cable to the blue port and it should work.', 785, 843),
  (v_tr, v_call, 10, 'customer', 'Customer', 'Okay, I''ll try.', 844, 869),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 870, 951),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 952, 995),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 996, 1070),
  (v_tr, v_call, 14, 'customer', 'Customer', 'No, that''s everything.', 1071, 1103),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Alright. Bye.', 1104, 1124);

-- NW-20260807-0054 · Arjun Deshmukh · tech_slow_speed
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260807-0054', '22222222-2222-4222-8222-000000000004', '11111111-1111-4111-8111-000000000002', 'CUST-47072', 'inbound',
  'phone', 'seed', 'en', '2026-08-07T14:59:50+00:00',
  '2026-08-07T15:05:47+00:00', 357, 'transcribed',
  '{"scenario": "tech_slow_speed", "intent": "performance_complaint", "topics": ["technical", "speed", "wifi"], "agent_skill_profile": 0.78, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "mid", "diagnosis": "good", "hold": "not_applicable", "resolution": "mid", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Arjun. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I''m paying for 300 megabits but I''m getting about 40 on my laptop. This has been going on for two weeks.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Let me separate two things: the speed into your home, and the speed across your wifi. From our side your line is currently syncing at 297 megabits, so the fibre is delivering what you pay for. The drop is happening between the router and your laptop.
Customer: How can you tell?
Agent: Your router reports your laptop connected on the 2.4 gigahertz band, which tops out well below 300. On the 5 gigahertz band you''d see close to the full speed.
Agent: Try connecting to the 5G network name instead.
Customer: Alright, I''ll try that later.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 247, 16, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Arjun. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''m paying for 300 megabits but I''m getting about 40 on my laptop. This has been going on for two weeks.', 173, 287),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 288, 422),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 423, 473),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 474, 497),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 498, 519),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Let me separate two things: the speed into your home, and the speed across your wifi. From our side your line is currently syncing at 297 megabits, so the fibre is delivering what you pay for. The drop is happening between the router and your laptop.', 520, 777),
  (v_tr, v_call, 7, 'customer', 'Customer', 'How can you tell?', 778, 805),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Your router reports your laptop connected on the 2.4 gigahertz band, which tops out well below 300. On the 5 gigahertz band you''d see close to the full speed.', 806, 971),
  (v_tr, v_call, 9, 'agent', 'Agent', 'Try connecting to the 5G network name instead.', 972, 1025),
  (v_tr, v_call, 10, 'customer', 'Customer', 'Alright, I''ll try that later.', 1026, 1065),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1066, 1147),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1148, 1191),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1192, 1266),
  (v_tr, v_call, 14, 'customer', 'Customer', 'No, that''s everything.', 1267, 1299),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1300, 1377);

-- NW-20260821-0055 · Fatima Sheikh · tech_router_setup
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260821-0055', '22222222-2222-4222-8222-000000000005', '11111111-1111-4111-8111-000000000002', 'CUST-63841', 'inbound',
  'phone', 'seed', 'en', '2026-08-21T12:36:24+00:00',
  '2026-08-21T12:41:49+00:00', 325, 'transcribed',
  '{"scenario": "tech_router_setup", "intent": "setup_assistance", "topics": ["technical", "installation", "router"], "agent_skill_profile": 0.48, "ground_truth": {"greeting": "mid", "empathy": "mid", "verification": "poor", "diagnosis": "mid", "hold": "mid", "resolution": "mid", "confirm": "mid", "closing": "poor"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Fatima speaking, the call is recorded. What can I do for you?
Customer: I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.
Agent: Sorry about that. Let me check.
Agent: Okay, I''ve pulled up the account, I can see your plan and your last three invoices here.
Agent: What lights are showing?
Customer: Green and orange.
Agent: Check the cable is in the right port.
Agent: One moment.
Agent: Okay, I''m back.
Agent: Move the cable to the blue port and it should work.
Customer: Okay, I''ll try.
Agent: Anything else?
Customer: No, that''s it.
Agent: Alright. Bye.', 115, 14, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Fatima speaking, the call is recorded. What can I do for you?', 0, 97),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.', 98, 210),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 211, 249),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Okay, I''ve pulled up the account, I can see your plan and your last three invoices here.', 250, 345),
  (v_tr, v_call, 4, 'agent', 'Agent', 'What lights are showing?', 346, 377),
  (v_tr, v_call, 5, 'customer', 'Customer', 'Green and orange.', 378, 405),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Check the cable is in the right port.', 406, 450),
  (v_tr, v_call, 7, 'agent', 'Agent', 'One moment.', 451, 469),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Okay, I''m back.', 470, 492),
  (v_tr, v_call, 9, 'agent', 'Agent', 'Move the cable to the blue port and it should work.', 493, 551),
  (v_tr, v_call, 10, 'customer', 'Customer', 'Okay, I''ll try.', 552, 577),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Anything else?', 578, 599),
  (v_tr, v_call, 12, 'customer', 'Customer', 'No, that''s it.', 600, 624),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Alright. Bye.', 625, 645);

-- NW-20260831-0056 · Priya Nair · billing_plan_change
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260831-0056', '22222222-2222-4222-8222-000000000001', '11111111-1111-4111-8111-000000000001', 'CUST-67711', 'inbound',
  'phone', 'seed', 'en', '2026-08-31T11:32:37+00:00',
  '2026-08-31T11:37:33+00:00', 296, 'transcribed',
  '{"scenario": "billing_plan_change", "intent": "plan_enquiry", "topics": ["billing", "plan_change", "pricing"], "agent_skill_profile": 0.85, "ground_truth": {"greeting": "mid", "empathy": "mid", "verification": "mid", "diagnosis": "good", "hold": "not_applicable", "resolution": "mid", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Priya speaking, the call is recorded. What can I do for you?
Customer: My bill went up by 400 rupees this month and nobody told me it was going to change.
Agent: Sorry about that. Let me check.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Let me walk you through the invoice line by line. Your promotional rate of 899 ran for twelve months and ended on the 15th of last month, so this invoice has fifteen days at the promo rate and fifteen at the standard 1,299. That''s why it looks like an odd number rather than a clean increase.
Customer: I don''t remember being told the promo was ending.
Agent: I can see a notification was sent to your registered email on the 1st, but I completely understand those are easy to miss, and I''m not going to argue that point with you.
Agent: I can offer you a discounted rate of 1,099 if you want.
Customer: Fine, do that.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 227, 14, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Priya speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My bill went up by 400 rupees this month and nobody told me it was going to change.', 97, 190),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 191, 229),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 230, 280),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 281, 304),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 305, 326),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Let me walk you through the invoice line by line. Your promotional rate of 899 ran for twelve months and ended on the 15th of last month, so this invoice has fifteen days at the promo rate and fifteen at the standard 1,299. That''s why it looks like an odd number rather than a clean increase.', 327, 626),
  (v_tr, v_call, 7, 'customer', 'Customer', 'I don''t remember being told the promo was ending.', 627, 686),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I can see a notification was sent to your registered email on the 1st, but I completely understand those are easy to miss, and I''m not going to argue that point with you.', 687, 864),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I can offer you a discounted rate of 1,099 if you want.', 865, 927),
  (v_tr, v_call, 10, 'customer', 'Customer', 'Fine, do that.', 928, 952),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Anything else?', 953, 974),
  (v_tr, v_call, 12, 'customer', 'Customer', 'No, that''s it.', 975, 999),
  (v_tr, v_call, 13, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1000, 1260);

-- NW-20260725-0057 · Rahul Menon · billing_refund_status
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260725-0057', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-79942', 'inbound',
  'phone', 'seed', 'en', '2026-07-25T15:41:05+00:00',
  '2026-07-25T15:48:15+00:00', 430, 'transcribed',
  '{"scenario": "billing_refund_status", "intent": "refund_status", "topics": ["billing", "refund", "follow_up"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "poor", "empathy": "good", "verification": "good", "diagnosis": "poor", "hold": "not_applicable", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Hello, support desk.
Customer: I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: It says approved here, so it should be with you. You''d have to check with your bank.
Agent: I''m re-issuing it to your current card now and marking it priority, which brings it to twenty-four hours rather than three days. I''m also adding a 300 rupee credit for the inconvenience of three calls, applied immediately. Reference NW-90118.
Customer: I appreciate that, thank you.
Agent: And I''ve set a reminder on my side to verify it landed tomorrow. If it hasn''t, you''ll get a call from us rather than you having to chase again.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 265, 15, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Hello, support desk.', 0, 27),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.', 28, 151),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 152, 286),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 287, 413),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 414, 475),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 476, 590),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 591, 613),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 614, 674),
  (v_tr, v_call, 8, 'agent', 'Agent', 'It says approved here, so it should be with you. You''d have to check with your bank.', 675, 766),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I''m re-issuing it to your current card now and marking it priority, which brings it to twenty-four hours rather than three days. I''m also adding a 300 rupee credit for the inconvenience of three calls, applied immediately. Reference NW-90118.', 767, 1016),
  (v_tr, v_call, 10, 'customer', 'Customer', 'I appreciate that, thank you.', 1017, 1056),
  (v_tr, v_call, 11, 'agent', 'Agent', 'And I''ve set a reminder on my side to verify it landed tomorrow. If it hasn''t, you''ll get a call from us rather than you having to chase again.', 1057, 1207),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Anything else?', 1208, 1229),
  (v_tr, v_call, 13, 'customer', 'Customer', 'No, that''s it.', 1230, 1254),
  (v_tr, v_call, 14, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1255, 1515);

-- NW-20260819-0058 · Ananya Bose · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260819-0058', '22222222-2222-4222-8222-000000000007', '11111111-1111-4111-8111-000000000003', 'CUST-23173', 'inbound',
  'phone', 'seed', 'en', '2026-08-19T10:27:06+00:00',
  '2026-08-19T10:35:39+00:00', 513, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.88, "ground_truth": {"greeting": "good", "empathy": "mid", "verification": "good", "diagnosis": "good", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: Sorry about that. Let me check.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.
Customer: So I''m over-subscribed?
Agent: Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.
Agent: Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.
Customer: Let''s go with the 150. I''d rather save the money.
Agent: Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 371, 19, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 173),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 174, 277),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 278, 316),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 317, 443),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 444, 505),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 506, 620),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 621, 643),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 644, 704),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.', 705, 992),
  (v_tr, v_call, 9, 'customer', 'Customer', 'So I''m over-subscribed?', 993, 1026),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.', 1027, 1114),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.', 1115, 1426),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Let''s go with the 150. I''d rather save the money.', 1427, 1486),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.', 1487, 1665),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1666, 1747),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1748, 1791),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1792, 1866),
  (v_tr, v_call, 17, 'customer', 'Customer', 'No, that''s everything.', 1867, 1899),
  (v_tr, v_call, 18, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1900, 2160);

-- NW-20260822-0059 · Karan Malhotra · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260822-0059', '22222222-2222-4222-8222-000000000008', '11111111-1111-4111-8111-000000000003', 'CUST-91226', 'inbound',
  'phone', 'seed', 'en', '2026-08-22T11:11:05+00:00',
  '2026-08-22T11:18:04+00:00', 419, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.42, "ground_truth": {"greeting": "mid", "empathy": "poor", "verification": "good", "diagnosis": "poor", "hold": "mid", "resolution": "good", "confirm": "mid", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Karan speaking, the call is recorded. What can I do for you?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: Okay. What''s the account number.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Okay, I''ll process the cancellation. There''s a 2,000 rupee early termination fee.
Agent: One moment.
Agent: Okay, I''m back.
Agent: I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.
Customer: That''s more reasonable than I expected. Let me take the two months.
Agent: Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.
Agent: Anything else?
Customer: No, that''s it.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 262, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Karan speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 97, 190),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Okay. What''s the account number.', 191, 230),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 231, 357),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 358, 419),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 420, 534),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 535, 557),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 558, 618),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Okay, I''ll process the cancellation. There''s a 2,000 rupee early termination fee.', 619, 707),
  (v_tr, v_call, 9, 'agent', 'Agent', 'One moment.', 708, 726),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Okay, I''m back.', 727, 749),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.', 750, 1180),
  (v_tr, v_call, 12, 'customer', 'Customer', 'That''s more reasonable than I expected. Let me take the two months.', 1181, 1258),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.', 1259, 1393),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Anything else?', 1394, 1415),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s it.', 1416, 1440),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1441, 1518);

-- NW-20260823-0060 · Arjun Deshmukh · tech_slow_speed
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260823-0060', '22222222-2222-4222-8222-000000000004', '11111111-1111-4111-8111-000000000002', 'CUST-93746', 'inbound',
  'phone', 'seed', 'en', '2026-08-23T10:28:22+00:00',
  '2026-08-23T10:37:12+00:00', 530, 'transcribed',
  '{"scenario": "tech_slow_speed", "intent": "performance_complaint", "topics": ["technical", "speed", "wifi"], "agent_skill_profile": 0.78, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "good", "resolution": "mid", "confirm": "mid", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Arjun speaking, the call is recorded. What can I do for you?
Customer: I''m paying for 300 megabits but I''m getting about 40 on my laptop. This has been going on for two weeks.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Let me separate two things: the speed into your home, and the speed across your wifi. From our side your line is currently syncing at 297 megabits, so the fibre is delivering what you pay for. The drop is happening between the router and your laptop.
Customer: How can you tell?
Agent: Your router reports your laptop connected on the 2.4 gigahertz band, which tops out well below 300. On the 5 gigahertz band you''d see close to the full speed.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: Try connecting to the 5G network name instead.
Customer: Alright, I''ll try that later.
Agent: Anything else?
Customer: No, that''s it.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 292, 19, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Arjun speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''m paying for 300 megabits but I''m getting about 40 on my laptop. This has been going on for two weeks.', 97, 211),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 212, 346),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 347, 473),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 474, 535),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 536, 650),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 651, 673),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 674, 734),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Let me separate two things: the speed into your home, and the speed across your wifi. From our side your line is currently syncing at 297 megabits, so the fibre is delivering what you pay for. The drop is happening between the router and your laptop.', 735, 992),
  (v_tr, v_call, 9, 'customer', 'Customer', 'How can you tell?', 993, 1020),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Your router reports your laptop connected on the 2.4 gigahertz band, which tops out well below 300. On the 5 gigahertz band you''d see close to the full speed.', 1021, 1186),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 1187, 1304),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s fine.', 1305, 1332),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 1333, 1416),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Try connecting to the 5G network name instead.', 1417, 1470),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Alright, I''ll try that later.', 1471, 1510),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Anything else?', 1511, 1532),
  (v_tr, v_call, 17, 'customer', 'Customer', 'No, that''s it.', 1533, 1557),
  (v_tr, v_call, 18, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1558, 1635);

-- NW-20260901-0061 · Ananya Bose · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260901-0061', '22222222-2222-4222-8222-000000000007', '11111111-1111-4111-8111-000000000003', 'CUST-16428', 'inbound',
  'phone', 'seed', 'en', '2026-09-01T15:17:00+00:00',
  '2026-09-01T15:24:54+00:00', 474, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.88, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "mid", "diagnosis": "mid", "hold": "good", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: I can show you our current plans.
Customer: Go ahead.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.
Customer: Let''s go with the 150. I''d rather save the money.
Agent: Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 328, 19, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 173),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 174, 277),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 278, 412),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 413, 463),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 464, 487),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 488, 509),
  (v_tr, v_call, 6, 'agent', 'Agent', 'I can show you our current plans.', 510, 550),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Go ahead.', 551, 570),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 571, 688),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Yes, that''s fine.', 689, 716),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 717, 800),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.', 801, 1112),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Let''s go with the 150. I''d rather save the money.', 1113, 1172),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.', 1173, 1351),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1352, 1433),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1434, 1477),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1478, 1552),
  (v_tr, v_call, 17, 'customer', 'Customer', 'No, that''s everything.', 1553, 1585),
  (v_tr, v_call, 18, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1586, 1846);

-- NW-20260825-0062 · Karan Malhotra · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260825-0062', '22222222-2222-4222-8222-000000000008', '11111111-1111-4111-8111-000000000003', 'CUST-67779', 'inbound',
  'phone', 'seed', 'en', '2026-08-25T10:57:40+00:00',
  '2026-08-25T11:03:11+00:00', 331, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.42, "ground_truth": {"greeting": "poor", "empathy": "good", "verification": "poor", "diagnosis": "good", "hold": "good", "resolution": "poor", "confirm": "poor", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Hello, support desk.
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Okay, I''ve pulled up the account, I can see your plan and your last three invoices here.
Agent: Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.
Customer: So I''m over-subscribed?
Agent: Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I''d stay on 300 personally. I''ll just renew you on the same thing.
Customer: I suppose that''s easiest.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 210, 13, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Hello, support desk.', 0, 27),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 28, 131),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 132, 266),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Okay, I''ve pulled up the account, I can see your plan and your last three invoices here.', 267, 362),
  (v_tr, v_call, 4, 'agent', 'Agent', 'Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.', 363, 650),
  (v_tr, v_call, 5, 'customer', 'Customer', 'So I''m over-subscribed?', 651, 684),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.', 685, 772),
  (v_tr, v_call, 7, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 773, 890),
  (v_tr, v_call, 8, 'customer', 'Customer', 'Yes, that''s fine.', 891, 918),
  (v_tr, v_call, 9, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 919, 1002),
  (v_tr, v_call, 10, 'agent', 'Agent', 'I''d stay on 300 personally. I''ll just renew you on the same thing.', 1003, 1076),
  (v_tr, v_call, 11, 'customer', 'Customer', 'I suppose that''s easiest.', 1077, 1112),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1113, 1190);

-- NW-20260801-0063 · Priya Nair · billing_refund_status
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260801-0063', '22222222-2222-4222-8222-000000000001', '11111111-1111-4111-8111-000000000001', 'CUST-48684', 'inbound',
  'phone', 'seed', 'en', '2026-08-01T13:53:10+00:00',
  '2026-08-01T13:59:15+00:00', 365, 'transcribed',
  '{"scenario": "billing_refund_status", "intent": "refund_status", "topics": ["billing", "refund", "follow_up"], "agent_skill_profile": 0.85, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "mid", "diagnosis": "good", "hold": "good", "resolution": "mid", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Three calls for the same thing is genuinely not acceptable and I''m sorry you''ve had to chase this. Let me find out exactly what happened rather than just re-raising it. I can see the refund was approved on the 8th, but it was queued against a closed payment method, which is why it never actually moved.
Customer: So it was just stuck the whole time?
Agent: Yes, and it would have stayed stuck. I''m glad you called back.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I''ll escalate it to the billing team.
Customer: That''s what the last person said.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 284, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.', 173, 296),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 297, 431),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 432, 482),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 483, 506),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 507, 528),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Three calls for the same thing is genuinely not acceptable and I''m sorry you''ve had to chase this. Let me find out exactly what happened rather than just re-raising it. I can see the refund was approved on the 8th, but it was queued against a closed payment method, which is why it never actually moved.', 529, 839),
  (v_tr, v_call, 7, 'customer', 'Customer', 'So it was just stuck the whole time?', 840, 886),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Yes, and it would have stayed stuck. I''m glad you called back.', 887, 956),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 957, 1074),
  (v_tr, v_call, 10, 'customer', 'Customer', 'Yes, that''s fine.', 1075, 1102),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 1103, 1186),
  (v_tr, v_call, 12, 'agent', 'Agent', 'I''ll escalate it to the billing team.', 1187, 1231),
  (v_tr, v_call, 13, 'customer', 'Customer', 'That''s what the last person said.', 1232, 1275),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Anything else?', 1276, 1297),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s it.', 1298, 1322),
  (v_tr, v_call, 16, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1323, 1583);

-- NW-20260729-0064 · Vikram Iyer · tech_no_internet
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260729-0064', '22222222-2222-4222-8222-000000000006', '11111111-1111-4111-8111-000000000002', 'CUST-80329', 'inbound',
  'phone', 'seed', 'en', '2026-07-29T14:05:50+00:00',
  '2026-07-29T14:12:05+00:00', 375, 'transcribed',
  '{"scenario": "tech_no_internet", "intent": "service_outage", "topics": ["technical", "outage", "connectivity"], "agent_skill_profile": 0.7, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "mid", "diagnosis": "good", "hold": "not_applicable", "resolution": "mid", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Vikram. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: A red light on that model usually means the fibre link itself is down rather than your wifi. Let me check the line status from our side. I can see your ONT last registered at 7:42pm yesterday and hasn''t come back since.
Customer: So it''s not something in my house?
Agent: Correct, and I want to be clear about that so you''re not troubleshooting things that can''t be the cause. There''s a confirmed fibre break affecting your distribution point, and you''re one of forty-one customers on it.
Agent: I''ve logged a fault. Engineering will look at it.
Customer: When?
Agent: I can''t give an exact time.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 263, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Vikram. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 173),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.', 174, 328),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 329, 463),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 464, 514),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 515, 538),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 539, 560),
  (v_tr, v_call, 6, 'agent', 'Agent', 'A red light on that model usually means the fibre link itself is down rather than your wifi. Let me check the line status from our side. I can see your ONT last registered at 7:42pm yesterday and hasn''t come back since.', 561, 787),
  (v_tr, v_call, 7, 'customer', 'Customer', 'So it''s not something in my house?', 788, 832),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Correct, and I want to be clear about that so you''re not troubleshooting things that can''t be the cause. There''s a confirmed fibre break affecting your distribution point, and you''re one of forty-one customers on it.', 833, 1056),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I''ve logged a fault. Engineering will look at it.', 1057, 1113),
  (v_tr, v_call, 10, 'customer', 'Customer', 'When?', 1114, 1129),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I can''t give an exact time.', 1130, 1164),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1165, 1246),
  (v_tr, v_call, 13, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1247, 1290),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1291, 1365),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s everything.', 1366, 1398),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1399, 1476);

-- NW-20260725-0065 · Rahul Menon · billing_plan_change
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260725-0065', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-18285', 'inbound',
  'phone', 'seed', 'en', '2026-07-25T17:20:58+00:00',
  '2026-07-25T17:28:14+00:00', 436, 'transcribed',
  '{"scenario": "billing_plan_change", "intent": "plan_enquiry", "topics": ["billing", "plan_change", "pricing"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "good", "empathy": "mid", "verification": "good", "diagnosis": "good", "hold": "not_applicable", "resolution": "good", "confirm": "mid", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Rahul. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My bill went up by 400 rupees this month and nobody told me it was going to change.
Agent: Sorry about that. Let me check.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Let me walk you through the invoice line by line. Your promotional rate of 899 ran for twelve months and ended on the 15th of last month, so this invoice has fifteen days at the promo rate and fifteen at the standard 1,299. That''s why it looks like an odd number rather than a clean increase.
Customer: I don''t remember being told the promo was ending.
Agent: I can see a notification was sent to your registered email on the 1st, but I completely understand those are easy to miss, and I''m not going to argue that point with you.
Agent: Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.
Customer: The loyalty rate sounds fair. Let''s do that.
Agent: Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.
Agent: Anything else?
Customer: No, that''s it.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 345, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Rahul. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My bill went up by 400 rupees this month and nobody told me it was going to change.', 173, 266),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 267, 305),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 306, 432),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 433, 494),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 495, 609),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 610, 632),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 633, 693),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Let me walk you through the invoice line by line. Your promotional rate of 899 ran for twelve months and ended on the 15th of last month, so this invoice has fifteen days at the promo rate and fifteen at the standard 1,299. That''s why it looks like an odd number rather than a clean increase.', 694, 993),
  (v_tr, v_call, 9, 'customer', 'Customer', 'I don''t remember being told the promo was ending.', 994, 1053),
  (v_tr, v_call, 10, 'agent', 'Agent', 'I can see a notification was sent to your registered email on the 1st, but I completely understand those are easy to miss, and I''m not going to argue that point with you.', 1054, 1231),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.', 1232, 1594),
  (v_tr, v_call, 12, 'customer', 'Customer', 'The loyalty rate sounds fair. Let''s do that.', 1595, 1649),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.', 1650, 1779),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Anything else?', 1780, 1801),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s it.', 1802, 1826),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1827, 1904);

-- NW-20260809-0066 · Karan Malhotra · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260809-0066', '22222222-2222-4222-8222-000000000008', '11111111-1111-4111-8111-000000000003', 'CUST-80804', 'inbound',
  'phone', 'seed', 'en', '2026-08-09T16:23:42+00:00',
  '2026-08-09T16:32:50+00:00', 548, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.42, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Karan speaking, the call is recorded. What can I do for you?
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.
Customer: So I''m over-subscribed?
Agent: Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.
Agent: Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.
Customer: Let''s go with the 150. I''d rather save the money.
Agent: Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 348, 19, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Karan speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 97, 200),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 201, 335),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 336, 462),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 463, 524),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 525, 639),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 640, 662),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 663, 723),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Happy to go through that properly. Let me look at how you''ve actually been using the line so we''re talking about real numbers rather than guesses. You''re averaging about 380 gigabytes a month, mostly evenings, and you''ve never come close to saturating your 300 megabit connection.', 724, 1011),
  (v_tr, v_call, 9, 'customer', 'Customer', 'So I''m over-subscribed?', 1012, 1045),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Slightly, yes. I''d rather tell you that than sell you an upgrade you don''t need.', 1046, 1133),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.', 1134, 1445),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Let''s go with the 150. I''d rather save the money.', 1446, 1505),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.', 1506, 1684),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1685, 1766),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1767, 1810),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1811, 1885),
  (v_tr, v_call, 17, 'customer', 'Customer', 'No, that''s everything.', 1886, 1918),
  (v_tr, v_call, 18, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1919, 1996);

-- NW-20260805-0067 · Ananya Bose · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260805-0067', '22222222-2222-4222-8222-000000000007', '11111111-1111-4111-8111-000000000003', 'CUST-58147', 'inbound',
  'phone', 'seed', 'en', '2026-08-05T12:54:23+00:00',
  '2026-08-05T13:00:14+00:00', 351, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.88, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "mid", "diagnosis": "good", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Ananya speaking, the call is recorded. What can I do for you?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.
Customer: Honestly it''s the three outages in two months. I can''t work like that.
Agent: That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.
Agent: I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.
Customer: That''s more reasonable than I expected. Let me take the two months.
Agent: Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 360, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Ananya speaking, the call is recorded. What can I do for you?', 0, 97),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 98, 191),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 192, 326),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 327, 377),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 378, 401),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 402, 423),
  (v_tr, v_call, 6, 'agent', 'Agent', 'I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.', 424, 644),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Honestly it''s the three outages in two months. I can''t work like that.', 645, 725),
  (v_tr, v_call, 8, 'agent', 'Agent', 'That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.', 726, 862),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.', 863, 1293),
  (v_tr, v_call, 10, 'customer', 'Customer', 'That''s more reasonable than I expected. Let me take the two months.', 1294, 1371),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.', 1372, 1506),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1507, 1588),
  (v_tr, v_call, 13, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1589, 1632),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1633, 1707),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s everything.', 1708, 1740),
  (v_tr, v_call, 16, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1741, 2001);

-- NW-20260901-0068 · Meera Raghavan · retention_renewal
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260901-0068', '22222222-2222-4222-8222-000000000009', '11111111-1111-4111-8111-000000000003', 'CUST-84000', 'inbound',
  'phone', 'seed', 'en', '2026-09-01T09:50:21+00:00',
  '2026-09-01T09:55:43+00:00', 322, 'transcribed',
  '{"scenario": "retention_renewal", "intent": "contract_renewal", "topics": ["retention", "renewal", "contract"], "agent_skill_profile": 0.92, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "mid", "diagnosis": "mid", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: My contract is up next month and I want to know what my options are before I decide anything.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: I can show you our current plans.
Customer: Go ahead.
Agent: Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.
Customer: Let''s go with the 150. I''d rather save the money.
Agent: Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 286, 16, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My contract is up next month and I want to know what my options are before I decide anything.', 173, 276),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 277, 411),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 412, 462),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 463, 486),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 487, 508),
  (v_tr, v_call, 6, 'agent', 'Agent', 'I can show you our current plans.', 509, 549),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Go ahead.', 550, 569),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge.', 570, 881),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Let''s go with the 150. I''d rather save the money.', 882, 941),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Sensible choice. That''s 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there''s no downtime during the switch.', 942, 1120),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1121, 1202),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1203, 1246),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1247, 1321),
  (v_tr, v_call, 14, 'customer', 'Customer', 'No, that''s everything.', 1322, 1354),
  (v_tr, v_call, 15, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1355, 1615);

-- NW-20260824-0069 · Arjun Deshmukh · tech_no_internet
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260824-0069', '22222222-2222-4222-8222-000000000004', '11111111-1111-4111-8111-000000000002', 'CUST-96646', 'inbound',
  'phone', 'seed', 'en', '2026-08-24T11:34:16+00:00',
  '2026-08-24T11:42:42+00:00', 506, 'transcribed',
  '{"scenario": "tech_no_internet", "intent": "service_outage", "topics": ["technical", "outage", "connectivity"], "agent_skill_profile": 0.78, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "good", "diagnosis": "mid", "hold": "mid", "resolution": "mid", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Arjun speaking, the call is recorded. What can I do for you?
Customer: My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Let me check. Yes, there seems to be an issue in your area.
Customer: How long will it take?
Agent: One moment.
Agent: Okay, I''m back.
Agent: I''ve logged a fault. Engineering will look at it.
Customer: When?
Agent: I can''t give an exact time.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 268, 20, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Arjun speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.', 97, 251),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 252, 386),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 387, 513),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 514, 575),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 576, 690),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 691, 713),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 714, 774),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Let me check. Yes, there seems to be an issue in your area.', 775, 841),
  (v_tr, v_call, 9, 'customer', 'Customer', 'How long will it take?', 842, 874),
  (v_tr, v_call, 10, 'agent', 'Agent', 'One moment.', 875, 893),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Okay, I''m back.', 894, 916),
  (v_tr, v_call, 12, 'agent', 'Agent', 'I''ve logged a fault. Engineering will look at it.', 917, 973),
  (v_tr, v_call, 13, 'customer', 'Customer', 'When?', 974, 989),
  (v_tr, v_call, 14, 'agent', 'Agent', 'I can''t give an exact time.', 990, 1024),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1025, 1106),
  (v_tr, v_call, 16, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1107, 1150),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1151, 1225),
  (v_tr, v_call, 18, 'customer', 'Customer', 'No, that''s everything.', 1226, 1258),
  (v_tr, v_call, 19, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1259, 1519);

-- NW-20260803-0070 · Priya Nair · billing_double_charge
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260803-0070', '22222222-2222-4222-8222-000000000001', '11111111-1111-4111-8111-000000000001', 'CUST-69245', 'inbound',
  'phone', 'seed', 'en', '2026-08-03T16:49:23+00:00',
  '2026-08-03T16:57:12+00:00', 469, 'transcribed',
  '{"scenario": "billing_double_charge", "intent": "billing_dispute", "topics": ["billing", "duplicate_charge", "refund"], "agent_skill_profile": 0.85, "ground_truth": {"greeting": "good", "empathy": "mid", "verification": "good", "diagnosis": "good", "hold": "good", "resolution": "mid", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.
Agent: Sorry about that. Let me check.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: I can see both transactions here, both on the 3rd. Looking at the payment log, your auto-debit mandate fired and then a manual payment was also processed from the app about four minutes later. So this is a duplicate, not a pricing change on your plan.
Customer: I did tap pay in the app because it showed as pending.
Agent: That explains it exactly, and that pending display is a known lag on our side. The charge is genuinely duplicated and you''re owed it back.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I''ll raise a refund request. It should come back in a few days.
Customer: Okay.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 329, 21, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.', 173, 322),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 323, 361),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 362, 488),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 489, 550),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 551, 665),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 666, 688),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 689, 749),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I can see both transactions here, both on the 3rd. Looking at the payment log, your auto-debit mandate fired and then a manual payment was also processed from the app about four minutes later. So this is a duplicate, not a pricing change on your plan.', 750, 1008),
  (v_tr, v_call, 9, 'customer', 'Customer', 'I did tap pay in the app because it showed as pending.', 1009, 1073),
  (v_tr, v_call, 10, 'agent', 'Agent', 'That explains it exactly, and that pending display is a known lag on our side. The charge is genuinely duplicated and you''re owed it back.', 1074, 1219),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 1220, 1337),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s fine.', 1338, 1365),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 1366, 1449),
  (v_tr, v_call, 14, 'agent', 'Agent', 'I''ll raise a refund request. It should come back in a few days.', 1450, 1520),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Okay.', 1521, 1536),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1537, 1618),
  (v_tr, v_call, 17, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1619, 1662),
  (v_tr, v_call, 18, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1663, 1737),
  (v_tr, v_call, 19, 'customer', 'Customer', 'No, that''s everything.', 1738, 1770),
  (v_tr, v_call, 20, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1771, 1848);

-- NW-20260803-0071 · Meera Raghavan · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260803-0071', '22222222-2222-4222-8222-000000000009', '11111111-1111-4111-8111-000000000003', 'CUST-68138', 'inbound',
  'phone', 'seed', 'en', '2026-08-03T15:27:43+00:00',
  '2026-08-03T15:32:47+00:00', 304, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.92, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "mid", "diagnosis": "mid", "hold": "not_applicable", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Meera speaking, the call is recorded. What can I do for you?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Can I ask why you''re leaving?
Customer: Too many outages.
Agent: I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.
Customer: That''s more reasonable than I expected. Let me take the two months.
Agent: Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 255, 14, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Meera speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 97, 190),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 191, 325),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 326, 376),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 377, 400),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 401, 422),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Can I ask why you''re leaving?', 423, 459),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Too many outages.', 460, 487),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.', 488, 918),
  (v_tr, v_call, 9, 'customer', 'Customer', 'That''s more reasonable than I expected. Let me take the two months.', 919, 996),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.', 997, 1131),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Anything else?', 1132, 1153),
  (v_tr, v_call, 12, 'customer', 'Customer', 'No, that''s it.', 1154, 1178),
  (v_tr, v_call, 13, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1179, 1439);

-- NW-20260815-0072 · Rahul Menon · billing_double_charge
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260815-0072', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-24996', 'inbound',
  'phone', 'seed', 'en', '2026-08-15T16:32:38+00:00',
  '2026-08-15T16:39:33+00:00', 415, 'transcribed',
  '{"scenario": "billing_double_charge", "intent": "billing_dispute", "topics": ["billing", "duplicate_charge", "refund"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "mid", "hold": "not_applicable", "resolution": "mid", "confirm": "good", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Rahul. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Yes, I can see two payments. It looks like a duplicate.
Customer: So what happens now?
Agent: I''ll raise a refund request. It should come back in a few days.
Customer: Okay.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 239, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Rahul. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.', 173, 322),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 323, 457),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 458, 584),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 585, 646),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 647, 761),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 762, 784),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 785, 845),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Yes, I can see two payments. It looks like a duplicate.', 846, 908),
  (v_tr, v_call, 9, 'customer', 'Customer', 'So what happens now?', 909, 939),
  (v_tr, v_call, 10, 'agent', 'Agent', 'I''ll raise a refund request. It should come back in a few days.', 940, 1010),
  (v_tr, v_call, 11, 'customer', 'Customer', 'Okay.', 1011, 1026),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1027, 1108),
  (v_tr, v_call, 13, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1109, 1152),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1153, 1227),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s everything.', 1228, 1260),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 1261, 1338);

-- NW-20260824-0073 · Meera Raghavan · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260824-0073', '22222222-2222-4222-8222-000000000009', '11111111-1111-4111-8111-000000000003', 'CUST-66606', 'inbound',
  'phone', 'seed', 'en', '2026-08-24T16:04:05+00:00',
  '2026-08-24T16:13:00+00:00', 535, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.92, "ground_truth": {"greeting": "good", "empathy": "mid", "verification": "good", "diagnosis": "mid", "hold": "good", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: Sorry about that. Let me check.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Can I ask why you''re leaving?
Customer: Too many outages.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.
Customer: That''s more reasonable than I expected. Let me take the two months.
Agent: Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 373, 21, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 173, 266),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 267, 305),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 306, 432),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 433, 494),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 495, 609),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 610, 632),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 633, 693),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Can I ask why you''re leaving?', 694, 730),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Too many outages.', 731, 758),
  (v_tr, v_call, 10, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 759, 876),
  (v_tr, v_call, 11, 'customer', 'Customer', 'Yes, that''s fine.', 877, 904),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 905, 988),
  (v_tr, v_call, 13, 'agent', 'Agent', 'I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.', 989, 1419),
  (v_tr, v_call, 14, 'customer', 'Customer', 'That''s more reasonable than I expected. Let me take the two months.', 1420, 1497),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.', 1498, 1632),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1633, 1714),
  (v_tr, v_call, 17, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1715, 1758),
  (v_tr, v_call, 18, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1759, 1833),
  (v_tr, v_call, 19, 'customer', 'Customer', 'No, that''s everything.', 1834, 1866),
  (v_tr, v_call, 20, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1867, 2127);

-- NW-20260806-0074 · Rahul Menon · billing_refund_status
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260806-0074', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-85748', 'inbound',
  'phone', 'seed', 'en', '2026-08-06T09:18:38+00:00',
  '2026-08-06T09:24:29+00:00', 351, 'transcribed',
  '{"scenario": "billing_refund_status", "intent": "refund_status", "topics": ["billing", "refund", "follow_up"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "mid", "empathy": "mid", "verification": "mid", "diagnosis": "mid", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?
Customer: I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.
Agent: Sorry about that. Let me check.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Let me check. It seems it hasn''t been processed yet.
Customer: Why not?
Agent: I''m not sure.
Agent: I''m re-issuing it to your current card now and marking it priority, which brings it to twenty-four hours rather than three days. I''m also adding a 300 rupee credit for the inconvenience of three calls, applied immediately. Reference NW-90118.
Customer: I appreciate that, thank you.
Agent: And I''ve set a reminder on my side to verify it landed tomorrow. If it hasn''t, you''ll get a call from us rather than you having to chase again.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 240, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.', 97, 220),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 221, 259),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 260, 310),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 311, 334),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 335, 356),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Let me check. It seems it hasn''t been processed yet.', 357, 416),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Why not?', 417, 435),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I''m not sure.', 436, 456),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I''m re-issuing it to your current card now and marking it priority, which brings it to twenty-four hours rather than three days. I''m also adding a 300 rupee credit for the inconvenience of three calls, applied immediately. Reference NW-90118.', 457, 706),
  (v_tr, v_call, 10, 'customer', 'Customer', 'I appreciate that, thank you.', 707, 746),
  (v_tr, v_call, 11, 'agent', 'Agent', 'And I''ve set a reminder on my side to verify it landed tomorrow. If it hasn''t, you''ll get a call from us rather than you having to chase again.', 747, 897),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 898, 979),
  (v_tr, v_call, 13, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 980, 1023),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1024, 1098),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s everything.', 1099, 1131),
  (v_tr, v_call, 16, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1132, 1392);

-- NW-20260806-0075 · Meera Raghavan · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260806-0075', '22222222-2222-4222-8222-000000000009', '11111111-1111-4111-8111-000000000003', 'CUST-94239', 'inbound',
  'phone', 'seed', 'en', '2026-08-06T17:49:52+00:00',
  '2026-08-06T17:57:12+00:00', 440, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.92, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "mid", "diagnosis": "good", "hold": "not_applicable", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.
Customer: Honestly it''s the three outages in two months. I can''t work like that.
Agent: That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.
Agent: I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.
Customer: That''s more reasonable than I expected. Let me take the two months.
Agent: Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 374, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 173, 266),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 267, 401),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 402, 452),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 453, 476),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 477, 498),
  (v_tr, v_call, 6, 'agent', 'Agent', 'I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.', 499, 719),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Honestly it''s the three outages in two months. I can''t work like that.', 720, 800),
  (v_tr, v_call, 8, 'agent', 'Agent', 'That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.', 801, 937),
  (v_tr, v_call, 9, 'agent', 'Agent', 'I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.', 938, 1368),
  (v_tr, v_call, 10, 'customer', 'Customer', 'That''s more reasonable than I expected. Let me take the two months.', 1369, 1446),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.', 1447, 1581),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1582, 1663),
  (v_tr, v_call, 13, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1664, 1707),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1708, 1782),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s everything.', 1783, 1815),
  (v_tr, v_call, 16, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1816, 2076);

-- NW-20260824-0076 · Meera Raghavan · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260824-0076', '22222222-2222-4222-8222-000000000009', '11111111-1111-4111-8111-000000000003', 'CUST-92991', 'inbound',
  'phone', 'seed', 'en', '2026-08-24T18:42:25+00:00',
  '2026-08-24T18:49:39+00:00', 434, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.92, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "good", "resolution": "mid", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.
Customer: Honestly it''s the three outages in two months. I can''t work like that.
Agent: That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I can give you a discount if you stay.
Customer: How much?
Agent: Twenty percent for six months.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 370, 22, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Meera. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 173, 266),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 267, 401),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 402, 528),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 529, 590),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 591, 705),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 706, 728),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 729, 789),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.', 790, 1010),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Honestly it''s the three outages in two months. I can''t work like that.', 1011, 1091),
  (v_tr, v_call, 10, 'agent', 'Agent', 'That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.', 1092, 1228),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 1229, 1346),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s fine.', 1347, 1374),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 1375, 1458),
  (v_tr, v_call, 14, 'agent', 'Agent', 'I can give you a discount if you stay.', 1459, 1504),
  (v_tr, v_call, 15, 'customer', 'Customer', 'How much?', 1505, 1524),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Twenty percent for six months.', 1525, 1562),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1563, 1644),
  (v_tr, v_call, 18, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1645, 1688),
  (v_tr, v_call, 19, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1689, 1763),
  (v_tr, v_call, 20, 'customer', 'Customer', 'No, that''s everything.', 1764, 1796),
  (v_tr, v_call, 21, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1797, 2057);

-- NW-20260830-0077 · Priya Nair · billing_double_charge
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260830-0077', '22222222-2222-4222-8222-000000000001', '11111111-1111-4111-8111-000000000001', 'CUST-20693', 'inbound',
  'phone', 'seed', 'en', '2026-08-30T11:10:48+00:00',
  '2026-08-30T11:19:14+00:00', 506, 'transcribed',
  '{"scenario": "billing_double_charge", "intent": "billing_dispute", "topics": ["billing", "duplicate_charge", "refund"], "agent_skill_profile": 0.85, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "mid", "resolution": "mid", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Priya speaking, the call is recorded. What can I do for you?
Customer: I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: I can see both transactions here, both on the 3rd. Looking at the payment log, your auto-debit mandate fired and then a manual payment was also processed from the app about four minutes later. So this is a duplicate, not a pricing change on your plan.
Customer: I did tap pay in the app because it showed as pending.
Agent: That explains it exactly, and that pending display is a known lag on our side. The charge is genuinely duplicated and you''re owed it back.
Agent: One moment.
Agent: Okay, I''m back.
Agent: I''ll raise a refund request. It should come back in a few days.
Customer: Okay.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 331, 20, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Priya speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.', 97, 246),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 247, 381),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 382, 508),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 509, 570),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 571, 685),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 686, 708),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 709, 769),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I can see both transactions here, both on the 3rd. Looking at the payment log, your auto-debit mandate fired and then a manual payment was also processed from the app about four minutes later. So this is a duplicate, not a pricing change on your plan.', 770, 1028),
  (v_tr, v_call, 9, 'customer', 'Customer', 'I did tap pay in the app because it showed as pending.', 1029, 1093),
  (v_tr, v_call, 10, 'agent', 'Agent', 'That explains it exactly, and that pending display is a known lag on our side. The charge is genuinely duplicated and you''re owed it back.', 1094, 1239),
  (v_tr, v_call, 11, 'agent', 'Agent', 'One moment.', 1240, 1258),
  (v_tr, v_call, 12, 'agent', 'Agent', 'Okay, I''m back.', 1259, 1281),
  (v_tr, v_call, 13, 'agent', 'Agent', 'I''ll raise a refund request. It should come back in a few days.', 1282, 1352),
  (v_tr, v_call, 14, 'customer', 'Customer', 'Okay.', 1353, 1368),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1369, 1450),
  (v_tr, v_call, 16, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1451, 1494),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1495, 1569),
  (v_tr, v_call, 18, 'customer', 'Customer', 'No, that''s everything.', 1570, 1602),
  (v_tr, v_call, 19, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1603, 1863);

-- NW-20260727-0078 · Fatima Sheikh · tech_slow_speed
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260727-0078', '22222222-2222-4222-8222-000000000005', '11111111-1111-4111-8111-000000000002', 'CUST-61807', 'inbound',
  'phone', 'seed', 'en', '2026-07-27T16:33:42+00:00',
  '2026-07-27T16:39:40+00:00', 358, 'transcribed',
  '{"scenario": "tech_slow_speed", "intent": "performance_complaint", "topics": ["technical", "speed", "wifi"], "agent_skill_profile": 0.48, "ground_truth": {"greeting": "mid", "empathy": "mid", "verification": "mid", "diagnosis": "good", "hold": "not_applicable", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Fatima speaking, the call is recorded. What can I do for you?
Customer: I''m paying for 300 megabits but I''m getting about 40 on my laptop. This has been going on for two weeks.
Agent: Sorry about that. Let me check.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Let me separate two things: the speed into your home, and the speed across your wifi. From our side your line is currently syncing at 297 megabits, so the fibre is delivering what you pay for. The drop is happening between the router and your laptop.
Customer: How can you tell?
Agent: Your router reports your laptop connected on the 2.4 gigahertz band, which tops out well below 300. On the 5 gigahertz band you''d see close to the full speed.
Agent: Two steps. First, on your laptop, connect to the network ending -5G instead of the plain one. Can you see that option now?
Customer: Yes, I''m connecting to it.
Agent: Run a speed test for me when it settles.
Customer: It''s showing 268 now. That''s a huge difference.
Agent: That''s what I''d expect. Second, I''ve pushed a channel optimisation to your router remotely, which should hold that speed during busy evenings.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 266, 17, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Fatima speaking, the call is recorded. What can I do for you?', 0, 97),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''m paying for 300 megabits but I''m getting about 40 on my laptop. This has been going on for two weeks.', 98, 212),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 213, 251),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 252, 302),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 303, 326),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 327, 348),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Let me separate two things: the speed into your home, and the speed across your wifi. From our side your line is currently syncing at 297 megabits, so the fibre is delivering what you pay for. The drop is happening between the router and your laptop.', 349, 606),
  (v_tr, v_call, 7, 'customer', 'Customer', 'How can you tell?', 607, 634),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Your router reports your laptop connected on the 2.4 gigahertz band, which tops out well below 300. On the 5 gigahertz band you''d see close to the full speed.', 635, 800),
  (v_tr, v_call, 9, 'agent', 'Agent', 'Two steps. First, on your laptop, connect to the network ending -5G instead of the plain one. Can you see that option now?', 801, 930),
  (v_tr, v_call, 10, 'customer', 'Customer', 'Yes, I''m connecting to it.', 931, 967),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Run a speed test for me when it settles.', 968, 1015),
  (v_tr, v_call, 12, 'customer', 'Customer', 'It''s showing 268 now. That''s a huge difference.', 1016, 1073),
  (v_tr, v_call, 13, 'agent', 'Agent', 'That''s what I''d expect. Second, I''ve pushed a channel optimisation to your router remotely, which should hold that speed during busy evenings.', 1074, 1223),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Anything else?', 1224, 1245),
  (v_tr, v_call, 15, 'customer', 'Customer', 'No, that''s it.', 1246, 1270),
  (v_tr, v_call, 16, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1271, 1531);

-- NW-20260730-0079 · Priya Nair · billing_double_charge
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260730-0079', '22222222-2222-4222-8222-000000000001', '11111111-1111-4111-8111-000000000001', 'CUST-19447', 'inbound',
  'phone', 'seed', 'en', '2026-07-30T12:32:35+00:00',
  '2026-07-30T12:40:59+00:00', 504, 'transcribed',
  '{"scenario": "billing_double_charge", "intent": "billing_dispute", "topics": ["billing", "duplicate_charge", "refund"], "agent_skill_profile": 0.85, "ground_truth": {"greeting": "good", "empathy": "mid", "verification": "mid", "diagnosis": "mid", "hold": "good", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.
Agent: Sorry about that. Let me check.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Yes, I can see two payments. It looks like a duplicate.
Customer: So what happens now?
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I''m raising a duplicate payment reversal for 1,299 now. That goes back to the original card and takes three working days. Your next invoice on the 3rd of October will be the normal 1,299, with no adjustment needed.
Customer: And I don''t need to do anything?
Agent: Nothing at all. I''ll also send you the reference number by email so you have it in writing.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 290, 19, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Priya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 172),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I''ve been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I''m really not happy about it.', 173, 322),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 323, 361),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 362, 412),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 413, 436),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 437, 458),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Yes, I can see two payments. It looks like a duplicate.', 459, 521),
  (v_tr, v_call, 7, 'customer', 'Customer', 'So what happens now?', 522, 552),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 553, 670),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Yes, that''s fine.', 671, 698),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 699, 782),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I''m raising a duplicate payment reversal for 1,299 now. That goes back to the original card and takes three working days. Your next invoice on the 3rd of October will be the normal 1,299, with no adjustment needed.', 783, 1004),
  (v_tr, v_call, 12, 'customer', 'Customer', 'And I don''t need to do anything?', 1005, 1047),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Nothing at all. I''ll also send you the reference number by email so you have it in writing.', 1048, 1146),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1147, 1228),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1229, 1272),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1273, 1347),
  (v_tr, v_call, 17, 'customer', 'Customer', 'No, that''s everything.', 1348, 1380),
  (v_tr, v_call, 18, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1381, 1641);

-- NW-20260813-0080 · Ananya Bose · retention_cancel
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260813-0080', '22222222-2222-4222-8222-000000000007', '11111111-1111-4111-8111-000000000003', 'CUST-57428', 'inbound',
  'phone', 'seed', 'en', '2026-08-13T11:51:39+00:00',
  '2026-08-13T12:00:16+00:00', 517, 'transcribed',
  '{"scenario": "retention_cancel", "intent": "cancellation_request", "topics": ["retention", "cancellation", "churn"], "agent_skill_profile": 0.88, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "good", "hold": "good", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I want to cancel my connection. I''m moving to a competitor at the end of the month.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.
Customer: Honestly it''s the three outages in two months. I can''t work like that.
Agent: That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.
Customer: That''s more reasonable than I expected. Let me take the two months.
Agent: Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 466, 22, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Ananya. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 173),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I want to cancel my connection. I''m moving to a competitor at the end of the month.', 174, 267),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 268, 402),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 403, 529),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 530, 591),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 592, 706),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 707, 729),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 730, 790),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I''ll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what''s driving the move? It genuinely helps us, and there''s a chance I can fix whatever it is.', 791, 1011),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Honestly it''s the three outages in two months. I can''t work like that.', 1012, 1092),
  (v_tr, v_call, 10, 'agent', 'Agent', 'That''s a completely fair reason and I''m not going to try to talk you out of it. Let me check what actually happened on your line.', 1093, 1229),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 1230, 1347),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s fine.', 1348, 1375),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 1376, 1459),
  (v_tr, v_call, 14, 'agent', 'Agent', 'I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I''m not going to promise you it will never happen again, because I can''t control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I''ll waive the termination fee entirely.', 1460, 1890),
  (v_tr, v_call, 15, 'customer', 'Customer', 'That''s more reasonable than I expected. Let me take the two months.', 1891, 1968),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Done. I''ve also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue.', 1969, 2103),
  (v_tr, v_call, 17, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 2104, 2185),
  (v_tr, v_call, 18, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 2186, 2229),
  (v_tr, v_call, 19, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 2230, 2304),
  (v_tr, v_call, 20, 'customer', 'Customer', 'No, that''s everything.', 2305, 2337),
  (v_tr, v_call, 21, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 2338, 2598);

-- NW-20260801-0081 · Rahul Menon · billing_plan_change
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260801-0081', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-55793', 'inbound',
  'phone', 'seed', 'en', '2026-08-01T10:33:32+00:00',
  '2026-08-01T10:40:21+00:00', 409, 'transcribed',
  '{"scenario": "billing_plan_change", "intent": "plan_enquiry", "topics": ["billing", "plan_change", "pricing"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "mid", "diagnosis": "mid", "hold": "good", "resolution": "good", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?
Customer: My bill went up by 400 rupees this month and nobody told me it was going to change.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: Your promotional pricing expired. That''s the standard rate now.
Customer: Nobody told me.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.
Customer: The loyalty rate sounds fair. Let''s do that.
Agent: Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 320, 19, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'My bill went up by 400 rupees this month and nobody told me it was going to change.', 97, 190),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 191, 325),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 326, 376),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 377, 400),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 401, 422),
  (v_tr, v_call, 6, 'agent', 'Agent', 'Your promotional pricing expired. That''s the standard rate now.', 423, 493),
  (v_tr, v_call, 7, 'customer', 'Customer', 'Nobody told me.', 494, 519),
  (v_tr, v_call, 8, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 520, 637),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Yes, that''s fine.', 638, 665),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 666, 749),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you''ve been with us three years. I''d want you to pick based on what you actually use rather than what sounds cheapest.', 750, 1112),
  (v_tr, v_call, 12, 'customer', 'Customer', 'The loyalty rate sounds fair. Let''s do that.', 1113, 1167),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months.', 1168, 1297),
  (v_tr, v_call, 14, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1298, 1379),
  (v_tr, v_call, 15, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1380, 1423),
  (v_tr, v_call, 16, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1424, 1498),
  (v_tr, v_call, 17, 'customer', 'Customer', 'No, that''s everything.', 1499, 1531),
  (v_tr, v_call, 18, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1532, 1792);

-- NW-20260724-0082 · Vikram Iyer · tech_router_setup
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260724-0082', '22222222-2222-4222-8222-000000000006', '11111111-1111-4111-8111-000000000002', 'CUST-68838', 'inbound',
  'phone', 'seed', 'en', '2026-07-24T16:29:48+00:00',
  '2026-07-24T16:39:02+00:00', 554, 'transcribed',
  '{"scenario": "tech_router_setup", "intent": "setup_assistance", "topics": ["technical", "installation", "router"], "agent_skill_profile": 0.7, "ground_truth": {"greeting": "mid", "empathy": "mid", "verification": "good", "diagnosis": "good", "hold": "good", "resolution": "good", "confirm": "mid", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Vikram speaking, the call is recorded. What can I do for you?
Customer: I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.
Agent: Sorry about that. Let me check.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: Not a problem at all, we''ll go one step at a time and I won''t rush you. Can you tell me what colour the lights on the front are right now?
Customer: There''s a green one and one that''s flashing orange.
Agent: That''s actually good news. Green means power is fine, and flashing orange means it''s looking for the connection but hasn''t found it yet. Nine times out of ten that''s the fibre cable in the wrong port.
Agent: I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?
Customer: Yes, that''s fine.
Agent: Thank you for holding, I appreciate your patience. I''ve got the details now.
Agent: On the back of the router there''s a row of yellow ports and one separate blue port. Can you tell me which one the thin cable from the wall is plugged into?
Customer: It''s in a yellow one.
Agent: That''s it, that''s the whole problem. Move it to the blue port for me, and take your time.
Customer: Okay, moved. Oh, the orange light just went solid green.
Agent: That''s exactly right. Your wifi name and password are printed on the sticker underneath the router. Try connecting your phone and tell me if it works.
Customer: It''s connected. Thank you so much, I was dreading this call.
Agent: Anything else?
Customer: No, that''s it.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 391, 23, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Vikram speaking, the call is recorded. What can I do for you?', 0, 97),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.', 98, 210),
  (v_tr, v_call, 2, 'agent', 'Agent', 'Sorry about that. Let me check.', 211, 249),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 250, 376),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 377, 438),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 439, 553),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 554, 576),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 577, 637),
  (v_tr, v_call, 8, 'agent', 'Agent', 'Not a problem at all, we''ll go one step at a time and I won''t rush you. Can you tell me what colour the lights on the front are right now?', 638, 783),
  (v_tr, v_call, 9, 'customer', 'Customer', 'There''s a green one and one that''s flashing orange.', 784, 845),
  (v_tr, v_call, 10, 'agent', 'Agent', 'That''s actually good news. Green means power is fine, and flashing orange means it''s looking for the connection but hasn''t found it yet. Nine times out of ten that''s the fibre cable in the wrong port.', 846, 1053),
  (v_tr, v_call, 11, 'agent', 'Agent', 'I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?', 1054, 1171),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Yes, that''s fine.', 1172, 1199),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Thank you for holding, I appreciate your patience. I''ve got the details now.', 1200, 1283),
  (v_tr, v_call, 14, 'agent', 'Agent', 'On the back of the router there''s a row of yellow ports and one separate blue port. Can you tell me which one the thin cable from the wall is plugged into?', 1284, 1446),
  (v_tr, v_call, 15, 'customer', 'Customer', 'It''s in a yellow one.', 1447, 1478),
  (v_tr, v_call, 16, 'agent', 'Agent', 'That''s it, that''s the whole problem. Move it to the blue port for me, and take your time.', 1479, 1575),
  (v_tr, v_call, 17, 'customer', 'Customer', 'Okay, moved. Oh, the orange light just went solid green.', 1576, 1642),
  (v_tr, v_call, 18, 'agent', 'Agent', 'That''s exactly right. Your wifi name and password are printed on the sticker underneath the router. Try connecting your phone and tell me if it works.', 1643, 1800),
  (v_tr, v_call, 19, 'customer', 'Customer', 'It''s connected. Thank you so much, I was dreading this call.', 1801, 1871),
  (v_tr, v_call, 20, 'agent', 'Agent', 'Anything else?', 1872, 1893),
  (v_tr, v_call, 21, 'customer', 'Customer', 'No, that''s it.', 1894, 1918),
  (v_tr, v_call, 22, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1919, 2179);

-- NW-20260804-0083 · Vikram Iyer · tech_router_setup
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260804-0083', '22222222-2222-4222-8222-000000000006', '11111111-1111-4111-8111-000000000002', 'CUST-20057', 'inbound',
  'phone', 'seed', 'en', '2026-08-04T16:02:03+00:00',
  '2026-08-04T16:08:35+00:00', 392, 'transcribed',
  '{"scenario": "tech_router_setup", "intent": "setup_assistance", "topics": ["technical", "installation", "router"], "agent_skill_profile": 0.7, "ground_truth": {"greeting": "good", "empathy": "good", "verification": "good", "diagnosis": "mid", "hold": "not_applicable", "resolution": "mid", "confirm": "good", "closing": "good"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Thank you for calling Northwind Broadband, my name is Vikram. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?
Customer: I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Before I open the account, could you confirm the registered name and the last four digits of the account number for me?
Customer: Sure, it''s under my name and the account ends 4471.
Agent: Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?
Customer: It''s 411004.
Agent: Thank you, you''re fully verified. Let me take a look.
Agent: What lights are showing?
Customer: Green and orange.
Agent: Check the cable is in the right port.
Agent: Move the cable to the blue port and it should work.
Customer: Okay, I''ll try.
Agent: Just to confirm before we finish, is the issue fully resolved for you now?
Customer: Yes, that''s sorted it. Thank you.
Agent: Wonderful. Is there anything else at all I can help you with today?
Customer: No, that''s everything.
Agent: To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 264, 18, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Thank you for calling Northwind Broadband, my name is Vikram. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?', 0, 173),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I got the new router today but I can''t get it working. I''m not very technical, so please bear with me.', 174, 286),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 287, 421),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Before I open the account, could you confirm the registered name and the last four digits of the account number for me?', 422, 548),
  (v_tr, v_call, 4, 'customer', 'Customer', 'Sure, it''s under my name and the account ends 4471.', 549, 610),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?', 611, 725),
  (v_tr, v_call, 6, 'customer', 'Customer', 'It''s 411004.', 726, 748),
  (v_tr, v_call, 7, 'agent', 'Agent', 'Thank you, you''re fully verified. Let me take a look.', 749, 809),
  (v_tr, v_call, 8, 'agent', 'Agent', 'What lights are showing?', 810, 841),
  (v_tr, v_call, 9, 'customer', 'Customer', 'Green and orange.', 842, 869),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Check the cable is in the right port.', 870, 914),
  (v_tr, v_call, 11, 'agent', 'Agent', 'Move the cable to the blue port and it should work.', 915, 973),
  (v_tr, v_call, 12, 'customer', 'Customer', 'Okay, I''ll try.', 974, 999),
  (v_tr, v_call, 13, 'agent', 'Agent', 'Just to confirm before we finish, is the issue fully resolved for you now?', 1000, 1081),
  (v_tr, v_call, 14, 'customer', 'Customer', 'Yes, that''s sorted it. Thank you.', 1082, 1125),
  (v_tr, v_call, 15, 'agent', 'Agent', 'Wonderful. Is there anything else at all I can help you with today?', 1126, 1200),
  (v_tr, v_call, 16, 'customer', 'Customer', 'No, that''s everything.', 1201, 1233),
  (v_tr, v_call, 17, 'agent', 'Agent', 'To summarise: I''ve raised the correction, you''ll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing Northwind Broadband. Have a good afternoon.', 1234, 1494);

-- NW-20260821-0084 · Rahul Menon · billing_refund_status
insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,
  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)
values ('NW-20260821-0084', '22222222-2222-4222-8222-000000000002', '11111111-1111-4111-8111-000000000001', 'CUST-69050', 'inbound',
  'phone', 'seed', 'en', '2026-08-21T14:38:30+00:00',
  '2026-08-21T14:42:44+00:00', 254, 'transcribed',
  '{"scenario": "billing_refund_status", "intent": "refund_status", "topics": ["billing", "refund", "follow_up"], "agent_skill_profile": 0.55, "ground_truth": {"greeting": "mid", "empathy": "good", "verification": "mid", "diagnosis": "poor", "hold": "not_applicable", "resolution": "good", "confirm": "poor", "closing": "mid"}}'::jsonb)
returning id into v_call;

insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)
values (v_call, 'Agent: Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?
Customer: I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.
Agent: I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.
Agent: Can you give me your account number please?
Customer: It ends 4471.
Agent: Right, got it.
Agent: It says approved here, so it should be with you. You''d have to check with your bank.
Agent: I''m re-issuing it to your current card now and marking it priority, which brings it to twenty-four hours rather than three days. I''m also adding a 300 rupee credit for the inconvenience of three calls, applied immediately. Reference NW-90118.
Customer: I appreciate that, thank you.
Agent: And I''ve set a reminder on my side to verify it landed tomorrow. If it hasn''t, you''ll get a call from us rather than you having to chase again.
Agent: Okay, that''s been raised. Someone will update you. Thanks for calling.', 191, 11, 'en', 'import')
returning id into v_tr;

insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values
  (v_tr, v_call, 0, 'agent', 'Agent', 'Northwind Broadband, this is Rahul speaking, the call is recorded. What can I do for you?', 0, 96),
  (v_tr, v_call, 1, 'customer', 'Customer', 'I was promised a refund three weeks ago and it still hasn''t arrived. This is the third time I''m calling about it.', 97, 220),
  (v_tr, v_call, 2, 'agent', 'Agent', 'I can hear how frustrating this has been, and honestly I''d feel the same way. Let me get to the bottom of it for you right now.', 221, 355),
  (v_tr, v_call, 3, 'agent', 'Agent', 'Can you give me your account number please?', 356, 406),
  (v_tr, v_call, 4, 'customer', 'Customer', 'It ends 4471.', 407, 430),
  (v_tr, v_call, 5, 'agent', 'Agent', 'Right, got it.', 431, 452),
  (v_tr, v_call, 6, 'agent', 'Agent', 'It says approved here, so it should be with you. You''d have to check with your bank.', 453, 544),
  (v_tr, v_call, 7, 'agent', 'Agent', 'I''m re-issuing it to your current card now and marking it priority, which brings it to twenty-four hours rather than three days. I''m also adding a 300 rupee credit for the inconvenience of three calls, applied immediately. Reference NW-90118.', 545, 794),
  (v_tr, v_call, 8, 'customer', 'Customer', 'I appreciate that, thank you.', 795, 834),
  (v_tr, v_call, 9, 'agent', 'Agent', 'And I''ve set a reminder on my side to verify it landed tomorrow. If it hasn''t, you''ll get a call from us rather than you having to chase again.', 835, 985),
  (v_tr, v_call, 10, 'agent', 'Agent', 'Okay, that''s been raised. Someone will update you. Thanks for calling.', 986, 1063);

raise notice 'Seeded % calls with transcripts and turns', (select count(*) from calls where source = 'seed');
end $$;
