#!/usr/bin/env python3
"""
Generate realistic seeded call transcripts as SQL.

WHY A GENERATOR AND NOT 80 HAND-WRITTEN TRANSCRIPTS
---------------------------------------------------
Three reasons, in order of importance:

1. GROUND TRUTH. Every transcript is assembled from blocks whose quality tier
   ("good" / "mid" / "poor") we choose deliberately. That intended tier is
   written into calls.metadata. Once the scoring agent runs in Phase 3 we can
   measure its scores against the tier that actually produced the text — which
   turns "the AI scores calls" into "the AI agrees with ground truth 87% of the
   time", a real evaluation section for the project report.

2. AGENT PERSONALITY. Each support agent gets a fixed skill profile, so their
   calls are consistently strong or consistently weak. Without this the
   dashboard's agent leaderboard is pure noise and every chart looks flat.

3. COMPLIANCE REALISM. Weak agents skip the recording disclosure and identity
   verification at a realistic rate, which means the seeded data naturally
   contains auto-fail calls to demonstrate that path.

Output: supabase/seeds/02_calls.sql   (idempotent, safe to re-run)
Usage:  python3 scripts/generate_seed_calls.py
No third-party dependencies, no model downloads. Deterministic (seed=42).
"""

import random
import json
from datetime import datetime, timedelta, timezone

RANDOM_SEED = 42
NUM_CALLS = 84
# Calls are spread backwards from this date so the dashboard's 6-week trend
# charts have data on every week.
END_DATE = datetime(2026, 9, 2, tzinfo=timezone.utc)
WEEKS_OF_HISTORY = 6

# ── Agent roster ────────────────────────────────────────────────────────────
# skill drives how often each agent draws a "good" block. Deliberately spread:
# two strong performers, two weak ones, the rest in between, so the leaderboard
# has a real shape instead of a flat line.
AGENTS = [
    # (uuid,                                   code,       name,             team_uuid,                                skill)
    ("22222222-2222-4222-8222-000000000001", "AGT-1001", "Priya Nair",     "11111111-1111-4111-8111-000000000001", 0.85),
    ("22222222-2222-4222-8222-000000000002", "AGT-1002", "Rahul Menon",    "11111111-1111-4111-8111-000000000001", 0.55),
    ("22222222-2222-4222-8222-000000000003", "AGT-1003", "Sneha Kulkarni", "11111111-1111-4111-8111-000000000001", 0.90),
    ("22222222-2222-4222-8222-000000000004", "AGT-1004", "Arjun Deshmukh", "11111111-1111-4111-8111-000000000002", 0.78),
    ("22222222-2222-4222-8222-000000000005", "AGT-1005", "Fatima Sheikh",  "11111111-1111-4111-8111-000000000002", 0.48),
    ("22222222-2222-4222-8222-000000000006", "AGT-1006", "Vikram Iyer",    "11111111-1111-4111-8111-000000000002", 0.70),
    ("22222222-2222-4222-8222-000000000007", "AGT-1007", "Ananya Bose",    "11111111-1111-4111-8111-000000000003", 0.88),
    ("22222222-2222-4222-8222-000000000008", "AGT-1008", "Karan Malhotra", "11111111-1111-4111-8111-000000000003", 0.42),
    ("22222222-2222-4222-8222-000000000009", "AGT-1009", "Meera Raghavan", "11111111-1111-4111-8111-000000000003", 0.92),
]

TEAM_BILLING = "11111111-1111-4111-8111-000000000001"
TEAM_TECH    = "11111111-1111-4111-8111-000000000002"
TEAM_RETAIN  = "11111111-1111-4111-8111-000000000003"

COMPANY = "Northwind Broadband"

# ── Conversation blocks ─────────────────────────────────────────────────────
# Each block is keyed by quality tier. "A" = agent turn, "C" = customer turn.
# {name} is substituted with the agent's first name.

GREETING = {
    "good": [("A", f"Thank you for calling {COMPANY}, my name is {{name}}. Just to let you know, this call is recorded for quality and training purposes. How can I help you today?")],
    "mid":  [("A", f"{COMPANY}, this is {{name}} speaking, the call is recorded. What can I do for you?")],
    "poor": [("A", "Hello, support desk.")],
}

VERIFICATION = {
    "good": [
        ("A", "Before I open the account, could you confirm the registered name and the last four digits of the account number for me?"),
        ("C", "Sure, it's under my name and the account ends 4471."),
        ("A", "Perfect, that matches what I have. And could you confirm the registered billing postcode as a second check?"),
        ("C", "It's 411004."),
        ("A", "Thank you, you're fully verified. Let me take a look."),
    ],
    "mid": [
        ("A", "Can you give me your account number please?"),
        ("C", "It ends 4471."),
        ("A", "Right, got it."),
    ],
    "poor": [
        ("A", "Okay, I've pulled up the account, I can see your plan and your last three invoices here."),
    ],
}

EMPATHY = {
    "good": [("A", "I can hear how frustrating this has been, and honestly I'd feel the same way. Let me get to the bottom of it for you right now.")],
    "mid":  [("A", "Sorry about that. Let me check.")],
    "poor": [("A", "Okay. What's the account number.")],
}

HOLD = {
    "good": [
        ("A", "I need about ninety seconds to check this with our billing system. Is it alright if I put you on a short hold?"),
        ("C", "Yes, that's fine."),
        ("A", "Thank you for holding, I appreciate your patience. I've got the details now."),
    ],
    "mid": [
        ("A", "One moment."),
        ("A", "Okay, I'm back."),
    ],
    "poor": [],
}

CONFIRM = {
    "good": [
        ("A", "Just to confirm before we finish, is the issue fully resolved for you now?"),
        ("C", "Yes, that's sorted it. Thank you."),
        ("A", "Wonderful. Is there anything else at all I can help you with today?"),
        ("C", "No, that's everything."),
    ],
    "mid": [
        ("A", "Anything else?"),
        ("C", "No, that's it."),
    ],
    "poor": [],
}

CLOSING = {
    "good": [
        ("A", "To summarise: I've raised the correction, you'll get a confirmation email within two hours, and the credit lands within three working days. Thank you so much for your patience today, and thank you for choosing {company}. Have a good afternoon."),
    ],
    "mid": [
        ("A", "Okay, that's been raised. Someone will update you. Thanks for calling."),
    ],
    "poor": [
        ("A", "Alright. Bye."),
    ],
}

# ── Scenarios ───────────────────────────────────────────────────────────────
# Each scenario supplies the customer's problem statement plus tiered diagnosis
# and resolution blocks, so the middle of the call is genuinely different
# between a billing dispute and a router fault.

SCENARIOS = [
    {
        "key": "billing_double_charge", "team": TEAM_BILLING, "topics": ["billing", "duplicate_charge", "refund"],
        "intent": "billing_dispute", "issue": [("C", "I've been charged twice for my FIBER-300 plan this month. Two payments of 1,299 went out on the same day and I'm really not happy about it.")],
        "diagnosis": {
            "good": [
                ("A", "I can see both transactions here, both on the 3rd. Looking at the payment log, your auto-debit mandate fired and then a manual payment was also processed from the app about four minutes later. So this is a duplicate, not a pricing change on your plan."),
                ("C", "I did tap pay in the app because it showed as pending."),
                ("A", "That explains it exactly, and that pending display is a known lag on our side. The charge is genuinely duplicated and you're owed it back."),
            ],
            "mid": [("A", "Yes, I can see two payments. It looks like a duplicate."), ("C", "So what happens now?")],
            "poor": [("A", "The system shows two charges. That's probably just how the billing cycle worked out this month.")],
        },
        "resolution": {
            "good": [
                ("A", "I'm raising a duplicate payment reversal for 1,299 now. That goes back to the original card and takes three working days. Your next invoice on the 3rd of October will be the normal 1,299, with no adjustment needed."),
                ("C", "And I don't need to do anything?"),
                ("A", "Nothing at all. I'll also send you the reference number by email so you have it in writing."),
            ],
            "mid": [("A", "I'll raise a refund request. It should come back in a few days."), ("C", "Okay.")],
            "poor": [("A", "I'll put a note on the account. You'll probably see it adjusted next month."), ("C", "Probably? That's not really good enough.")],
        },
    },
    {
        "key": "tech_no_internet", "team": TEAM_TECH, "topics": ["technical", "outage", "connectivity"],
        "intent": "service_outage", "issue": [("C", "My internet has been completely down since yesterday evening. The router light is red and I work from home, so this is a serious problem for me.")],
        "diagnosis": {
            "good": [
                ("A", "A red light on that model usually means the fibre link itself is down rather than your wifi. Let me check the line status from our side. I can see your ONT last registered at 7:42pm yesterday and hasn't come back since."),
                ("C", "So it's not something in my house?"),
                ("A", "Correct, and I want to be clear about that so you're not troubleshooting things that can't be the cause. There's a confirmed fibre break affecting your distribution point, and you're one of forty-one customers on it."),
            ],
            "mid": [("A", "Let me check. Yes, there seems to be an issue in your area."), ("C", "How long will it take?")],
            "poor": [("A", "Have you tried restarting the router?"), ("C", "Yes, four times."), ("A", "Try it again and leave it off for ten minutes.")],
        },
        "resolution": {
            "good": [
                ("A", "The repair crew is already assigned, with an estimated restoration by 6pm today. I'm adding your number to the SMS notification list so you get a text the moment the link is back. I'm also applying a two-day service credit to your account automatically, you don't need to claim it."),
                ("C", "That's really helpful, thank you."),
                ("A", "If it isn't back by 6pm, call us and quote reference NW-88214 and it goes straight to the field team without you repeating any of this."),
            ],
            "mid": [("A", "I've logged a fault. Engineering will look at it."), ("C", "When?"), ("A", "I can't give an exact time.")],
            "poor": [("A", "There's an outage, it'll be fixed when it's fixed. Nothing I can do from here."), ("C", "That's not an answer.")],
        },
    },
    {
        "key": "tech_slow_speed", "team": TEAM_TECH, "topics": ["technical", "speed", "wifi"],
        "intent": "performance_complaint", "issue": [("C", "I'm paying for 300 megabits but I'm getting about 40 on my laptop. This has been going on for two weeks.")],
        "diagnosis": {
            "good": [
                ("A", "Let me separate two things: the speed into your home, and the speed across your wifi. From our side your line is currently syncing at 297 megabits, so the fibre is delivering what you pay for. The drop is happening between the router and your laptop."),
                ("C", "How can you tell?"),
                ("A", "Your router reports your laptop connected on the 2.4 gigahertz band, which tops out well below 300. On the 5 gigahertz band you'd see close to the full speed."),
            ],
            "mid": [("A", "Your line looks fine on our end. It's probably your wifi."), ("C", "So what do I do?")],
            "poor": [("A", "300 is the maximum, not a guarantee. 40 is within normal range.")],
        },
        "resolution": {
            "good": [
                ("A", "Two steps. First, on your laptop, connect to the network ending -5G instead of the plain one. Can you see that option now?"),
                ("C", "Yes, I'm connecting to it."),
                ("A", "Run a speed test for me when it settles."),
                ("C", "It's showing 268 now. That's a huge difference."),
                ("A", "That's what I'd expect. Second, I've pushed a channel optimisation to your router remotely, which should hold that speed during busy evenings."),
            ],
            "mid": [("A", "Try connecting to the 5G network name instead."), ("C", "Alright, I'll try that later.")],
            "poor": [("A", "I'd suggest upgrading to our 500 plan, that'd give you more headroom."), ("C", "I don't want to pay more to get what I already pay for.")],
        },
    },
    {
        "key": "billing_plan_change", "team": TEAM_BILLING, "topics": ["billing", "plan_change", "pricing"],
        "intent": "plan_enquiry", "issue": [("C", "My bill went up by 400 rupees this month and nobody told me it was going to change.")],
        "diagnosis": {
            "good": [
                ("A", "Let me walk you through the invoice line by line. Your promotional rate of 899 ran for twelve months and ended on the 15th of last month, so this invoice has fifteen days at the promo rate and fifteen at the standard 1,299. That's why it looks like an odd number rather than a clean increase."),
                ("C", "I don't remember being told the promo was ending."),
                ("A", "I can see a notification was sent to your registered email on the 1st, but I completely understand those are easy to miss, and I'm not going to argue that point with you."),
            ],
            "mid": [("A", "Your promotional pricing expired. That's the standard rate now."), ("C", "Nobody told me.")],
            "poor": [("A", "Prices go up, it's in the terms and conditions you agreed to.")],
        },
        "resolution": {
            "good": [
                ("A", "Here are your real options. You can stay on 1,299 for the same 300 megabits. You can move to our 150 megabit plan at 949, which for two people streaming is genuinely enough. Or I can apply a loyalty rate of 1,099 for twelve months given you've been with us three years. I'd want you to pick based on what you actually use rather than what sounds cheapest."),
                ("C", "The loyalty rate sounds fair. Let's do that."),
                ("A", "Applied from your next cycle. To be precise: 1,099 plus 18 percent GST, so 1,297 total per month, fixed for twelve months."),
            ],
            "mid": [("A", "I can offer you a discounted rate of 1,099 if you want."), ("C", "Fine, do that.")],
            "poor": [("A", "I'll definitely get that refunded for you, I guarantee it'll be back by tomorrow."), ("C", "Okay, thank you.")],
        },
    },
    {
        "key": "retention_cancel", "team": TEAM_RETAIN, "topics": ["retention", "cancellation", "churn"],
        "intent": "cancellation_request", "issue": [("C", "I want to cancel my connection. I'm moving to a competitor at the end of the month.")],
        "diagnosis": {
            "good": [
                ("A", "I'll absolutely process that for you, and I want to make sure it goes smoothly. Before I do, would you mind telling me what's driving the move? It genuinely helps us, and there's a chance I can fix whatever it is."),
                ("C", "Honestly it's the three outages in two months. I can't work like that."),
                ("A", "That's a completely fair reason and I'm not going to try to talk you out of it. Let me check what actually happened on your line."),
            ],
            "mid": [("A", "Can I ask why you're leaving?"), ("C", "Too many outages.")],
            "poor": [("A", "Okay, I'll process the cancellation. There's a 2,000 rupee early termination fee.")],
        },
        "resolution": {
            "good": [
                ("A", "I can see all three outages on your line and they were all the same distribution point, which was permanently rebuilt on the 20th. So the specific cause of your problem is genuinely fixed. I'm not going to promise you it will never happen again, because I can't control that. What I can do is offer two months at no charge while you decide, and if you still want to leave after that I'll waive the termination fee entirely."),
                ("C", "That's more reasonable than I expected. Let me take the two months."),
                ("A", "Done. I've also flagged your account so any future outage on that line escalates automatically instead of waiting in the queue."),
            ],
            "mid": [("A", "I can give you a discount if you stay."), ("C", "How much?"), ("A", "Twenty percent for six months.")],
            "poor": [("A", "That's the policy, there's nothing I can do about the fee."), ("C", "Then just cancel it. This is exactly why I'm leaving.")],
        },
    },
    {
        "key": "tech_router_setup", "team": TEAM_TECH, "topics": ["technical", "installation", "router"],
        "intent": "setup_assistance", "issue": [("C", "I got the new router today but I can't get it working. I'm not very technical, so please bear with me.")],
        "diagnosis": {
            "good": [
                ("A", "Not a problem at all, we'll go one step at a time and I won't rush you. Can you tell me what colour the lights on the front are right now?"),
                ("C", "There's a green one and one that's flashing orange."),
                ("A", "That's actually good news. Green means power is fine, and flashing orange means it's looking for the connection but hasn't found it yet. Nine times out of ten that's the fibre cable in the wrong port."),
            ],
            "mid": [("A", "What lights are showing?"), ("C", "Green and orange."), ("A", "Check the cable is in the right port.")],
            "poor": [("A", "It should be plug and play. Just follow the leaflet in the box.")],
        },
        "resolution": {
            "good": [
                ("A", "On the back of the router there's a row of yellow ports and one separate blue port. Can you tell me which one the thin cable from the wall is plugged into?"),
                ("C", "It's in a yellow one."),
                ("A", "That's it, that's the whole problem. Move it to the blue port for me, and take your time."),
                ("C", "Okay, moved. Oh, the orange light just went solid green."),
                ("A", "That's exactly right. Your wifi name and password are printed on the sticker underneath the router. Try connecting your phone and tell me if it works."),
                ("C", "It's connected. Thank you so much, I was dreading this call."),
            ],
            "mid": [("A", "Move the cable to the blue port and it should work."), ("C", "Okay, I'll try.")],
            "poor": [("A", "If it's still not working after that you'll need to book an engineer visit."), ("C", "How do I do that?"), ("A", "It's on the website.")],
        },
    },
    {
        "key": "billing_refund_status", "team": TEAM_BILLING, "topics": ["billing", "refund", "follow_up"],
        "intent": "refund_status", "issue": [("C", "I was promised a refund three weeks ago and it still hasn't arrived. This is the third time I'm calling about it.")],
        "diagnosis": {
            "good": [
                ("A", "Three calls for the same thing is genuinely not acceptable and I'm sorry you've had to chase this. Let me find out exactly what happened rather than just re-raising it. I can see the refund was approved on the 8th, but it was queued against a closed payment method, which is why it never actually moved."),
                ("C", "So it was just stuck the whole time?"),
                ("A", "Yes, and it would have stayed stuck. I'm glad you called back."),
            ],
            "mid": [("A", "Let me check. It seems it hasn't been processed yet."), ("C", "Why not?"), ("A", "I'm not sure.")],
            "poor": [("A", "It says approved here, so it should be with you. You'd have to check with your bank.")],
        },
        "resolution": {
            "good": [
                ("A", "I'm re-issuing it to your current card now and marking it priority, which brings it to twenty-four hours rather than three days. I'm also adding a 300 rupee credit for the inconvenience of three calls, applied immediately. Reference NW-90118."),
                ("C", "I appreciate that, thank you."),
                ("A", "And I've set a reminder on my side to verify it landed tomorrow. If it hasn't, you'll get a call from us rather than you having to chase again."),
            ],
            "mid": [("A", "I'll escalate it to the billing team."), ("C", "That's what the last person said.")],
            "poor": [("A", "I'll raise it again. Give it another week."), ("C", "Another week? This is ridiculous.")],
        },
    },
    {
        "key": "retention_renewal", "team": TEAM_RETAIN, "topics": ["retention", "renewal", "contract"],
        "intent": "contract_renewal", "issue": [("C", "My contract is up next month and I want to know what my options are before I decide anything.")],
        "diagnosis": {
            "good": [
                ("A", "Happy to go through that properly. Let me look at how you've actually been using the line so we're talking about real numbers rather than guesses. You're averaging about 380 gigabytes a month, mostly evenings, and you've never come close to saturating your 300 megabit connection."),
                ("C", "So I'm over-subscribed?"),
                ("A", "Slightly, yes. I'd rather tell you that than sell you an upgrade you don't need."),
            ],
            "mid": [("A", "I can show you our current plans."), ("C", "Go ahead.")],
            "poor": [("A", "Our best offer is the 500 megabit plan at 1,799. That's what I'd recommend.")],
        },
        "resolution": {
            "good": [
                ("A", "Given that, the honest recommendation is the 150 megabit plan at 949, which saves you 350 a month and you would not notice the difference in daily use. If you want headroom for the future, staying at 300 with a renewal discount brings it to 1,149. Both are twelve month terms with no installation charge."),
                ("C", "Let's go with the 150. I'd rather save the money."),
                ("A", "Sensible choice. That's 949 plus GST, so 1,120 a month, starting from your renewal date on the 14th. Nothing changes before then and there's no downtime during the switch."),
            ],
            "mid": [("A", "The 150 plan is 949 if you want to save money."), ("C", "Okay, put me on that.")],
            "poor": [("A", "I'd stay on 300 personally. I'll just renew you on the same thing."), ("C", "I suppose that's easiest.")],
        },
    },
]


def pick_tier(rng, skill):
    """Draw a block quality tier from an agent's skill level.

    A high-skill agent still has bad moments and a weak agent still has good
    ones — the distribution is weighted, not deterministic. That variance is
    what makes the seeded score_stddev on the agent scorecard meaningful.
    """
    r = rng.random()
    if r < skill - 0.15:
        return "good"
    if r < skill + 0.30:
        return "mid"
    return "poor"


def build_transcript(rng, scenario, agent_name, skill):
    """Assemble one conversation and return (turns, tier_map).

    tier_map is the ground truth: which quality tier each structural block was
    drawn from. It is stored in calls.metadata for later accuracy measurement.
    """
    turns, tiers = [], {}

    def add(block_dict, key, **fmt):
        tier = pick_tier(rng, skill)
        tiers[key] = tier
        for speaker, text in block_dict[tier]:
            turns.append((speaker, text.format(name=agent_name, company=COMPANY, **fmt)))

    add(GREETING, "greeting")
    turns.extend(scenario["issue"])
    add(EMPATHY, "empathy")
    add(VERIFICATION, "verification")
    add(scenario["diagnosis"], "diagnosis")
    # Roughly half of calls involve a hold. Modelled explicitly so the
    # HOLD_ETIQUETTE criterion has genuine not-applicable cases to exercise the
    # N/A renormalisation path.
    if rng.random() < 0.5:
        add(HOLD, "hold")
    else:
        tiers["hold"] = "not_applicable"
    add(scenario["resolution"], "resolution")
    add(CONFIRM, "confirm")
    add(CLOSING, "closing")

    return turns, tiers


def sql_escape(s):
    return s.replace("'", "''")


def main():
    rng = random.Random(RANDOM_SEED)
    out = []

    out.append("-- ============================================================")
    out.append("-- SEED · Calls, transcripts and turns")
    out.append("-- GENERATED FILE — edit scripts/generate_seed_calls.py instead.")
    out.append(f"-- {NUM_CALLS} calls · {len(AGENTS)} agents · {WEEKS_OF_HISTORY} weeks of history")
    out.append("--")
    out.append("-- calls.metadata.ground_truth records the quality tier each block was")
    out.append("-- generated from, so Phase 3 can measure AI scoring accuracy against it.")
    out.append("-- ============================================================")
    out.append("")
    out.append("do $$")
    out.append("declare v_call uuid; v_tr uuid;")
    out.append("begin")
    out.append("if exists (select 1 from calls where source = 'seed') then")
    out.append("  raise notice 'Calls already seeded, skipping.'; return;")
    out.append("end if;")
    out.append("")

    for i in range(NUM_CALLS):
        agent_id, agent_code, agent_name, team_id, skill = rng.choice(AGENTS)
        first_name = agent_name.split()[0]

        # Match the scenario to the agent's team so a billing agent isn't
        # handling router faults — the kind of detail that makes a demo credible.
        team_scenarios = [s for s in SCENARIOS if s["team"] == team_id]
        scenario = rng.choice(team_scenarios)

        turns, tiers = build_transcript(rng, scenario, first_name, skill)

        # Build full_text and exact character offsets in one pass. These offsets
        # are what the UI uses to highlight cited excerpts.
        lines, offsets, cursor = [], [], 0
        for speaker, text in turns:
            label = "Agent" if speaker == "A" else "Customer"
            line = f"{label}: {text}"
            offsets.append((cursor, cursor + len(line)))
            lines.append(line)
            cursor += len(line) + 1          # +1 for the newline separator
        full_text = "\n".join(lines)

        # Spread calls across the history window, weekdays biased to business hours.
        days_back = rng.randint(0, WEEKS_OF_HISTORY * 7 - 1)
        started = (END_DATE - timedelta(days=days_back)).replace(
            hour=rng.randint(9, 18), minute=rng.randint(0, 59), second=rng.randint(0, 59)
        )
        # Duration correlates with turn count plus noise — a 4-turn call cannot
        # plausibly last eleven minutes.
        duration = int(len(turns) * rng.uniform(16, 26) + rng.randint(20, 70))

        call_code = f"NW-{2026}{started.strftime('%m%d')}-{i+1:04d}"
        customer_ref = f"CUST-{rng.randint(10000, 99999)}"
        word_count = len(full_text.split())

        metadata = {
            "scenario": scenario["key"],
            "intent": scenario["intent"],
            "topics": scenario["topics"],
            "agent_skill_profile": skill,
            # ★ ground truth for measuring the scoring agent's accuracy
            "ground_truth": tiers,
        }

        out.append(f"-- {call_code} · {agent_name} · {scenario['key']}")
        out.append("insert into calls (call_code, support_agent_id, team_id, customer_ref, direction,")
        out.append("  channel, source, language, started_at, ended_at, duration_seconds, status, metadata)")
        out.append(f"values ('{call_code}', '{agent_id}', '{team_id}', '{customer_ref}', 'inbound',")
        out.append(f"  'phone', 'seed', 'en', '{started.isoformat()}',")
        out.append(f"  '{(started + timedelta(seconds=duration)).isoformat()}', {duration}, 'transcribed',")
        out.append(f"  '{sql_escape(json.dumps(metadata))}'::jsonb)")
        out.append("returning id into v_call;")
        out.append("")
        out.append("insert into transcripts (call_id, full_text, word_count, turn_count, language, transcription_provider)")
        out.append(f"values (v_call, '{sql_escape(full_text)}', {word_count}, {len(turns)}, 'en', 'import')")
        out.append("returning id into v_tr;")
        out.append("")
        out.append("insert into transcript_turns (transcript_id, call_id, turn_index, speaker, speaker_label, text, char_start, char_end) values")
        rows = []
        for idx, ((speaker, text), (cs, ce)) in enumerate(zip(turns, offsets)):
            role = "agent" if speaker == "A" else "customer"
            label = "Agent" if speaker == "A" else "Customer"
            rows.append(f"  (v_tr, v_call, {idx}, '{role}', '{label}', '{sql_escape(text)}', {cs}, {ce})")
        out.append(",\n".join(rows) + ";")
        out.append("")

    out.append(f"raise notice 'Seeded % calls with transcripts and turns', (select count(*) from calls where source = 'seed');")
    out.append("end $$;")

    path = "supabase/seeds/02_calls.sql"
    with open(path, "w") as f:
        f.write("\n".join(out) + "\n")

    print(f"Wrote {path}")
    print(f"  calls: {NUM_CALLS}")
    print(f"  agents: {len(AGENTS)}   scenarios: {len(SCENARIOS)}")
    print(f"  window: {WEEKS_OF_HISTORY} weeks ending {END_DATE.date()}")


if __name__ == "__main__":
    main()
