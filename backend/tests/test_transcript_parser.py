"""Tests for the transcript parser.

The offset invariant is the thing worth defending: every test that produces a
transcript calls verify(), which slices full_text at each turn's stored offsets
and compares. If those ever drift, every citation in the product points at the
wrong words.
"""

import pytest

from app.services.transcript_parser import (
    compute_statistics,
    normalise_speaker,
    parse,
    parse_text_transcript,
    parse_turn_list,
)


class TestSpeakerNormalisation:
    @pytest.mark.parametrize(
        "label,expected",
        [
            ("Agent", "agent"),
            ("AGENT_01", "agent"),
            ("agent (Priya)", "agent"),
            ("Rep", "agent"),
            ("CSR", "agent"),
            ("Support Agent", "agent"),
            ("Customer", "customer"),
            ("CALLER", "customer"),
            ("Client 2", "customer"),
            ("IVR", "system"),
            ("Speaker 3", "unknown"),
            ("", "unknown"),
        ],
    )
    def test_maps_real_world_labels(self, label, expected):
        assert normalise_speaker(label) == expected


class TestPlainTextParsing:
    def test_basic_two_speaker_transcript(self):
        result = parse_text_transcript(
            "Agent: Thank you for calling Northwind.\n"
            "Customer: My bill is wrong.\n"
            "Agent: Let me check that for you."
        )
        assert result.turn_count == 3
        assert [t.speaker for t in result.turns] == ["agent", "customer", "agent"]
        result.verify()

    def test_offsets_slice_back_exactly(self):
        result = parse_text_transcript(
            "Agent: Hello there.\nCustomer: Hi, I have a problem.\nAgent: Tell me about it."
        )
        for turn in result.turns:
            assert (
                result.full_text[turn.char_start : turn.char_end]
                == f"{turn.speaker_label}: {turn.text}"
            )

    def test_multi_line_turn_stays_one_turn(self):
        """A wrapped paragraph must not fragment into several turns."""
        result = parse_text_transcript(
            "Agent: This is a long explanation\n"
            "that wraps across lines\n"
            "and keeps going.\n"
            "Customer: Understood."
        )
        assert result.turn_count == 2
        assert "wraps across lines" in result.turns[0].text
        result.verify()

    def test_colon_inside_a_sentence_is_not_a_speaker(self):
        """The bug this guards: 'The problem is this: my bill doubled' must not
        be read as a speaker named 'The problem is this'."""
        result = parse_text_transcript(
            "Customer: Here is my issue.\n"
            "The problem is honestly quite simple: my bill doubled.\n"
            "Agent: I see."
        )
        assert result.turn_count == 2
        assert "my bill doubled" in result.turns[0].text
        result.verify()

    def test_timestamps_are_parsed_and_stripped(self):
        result = parse_text_transcript(
            "[00:00:05] Agent: Good morning.\n[00:01:23] Customer: Hello."
        )
        assert result.turns[0].start_ms == 5_000
        assert result.turns[1].start_ms == 83_000
        assert result.turns[0].text == "Good morning."
        result.verify()

    def test_mm_ss_timestamps(self):
        result = parse_text_transcript("01:30 Agent: Hello.")
        assert result.turns[0].start_ms == 90_000

    def test_unlabelled_prose_is_kept_not_rejected(self):
        result = parse_text_transcript("Just some text with no speaker labels at all.")
        assert result.turn_count == 1
        assert result.turns[0].speaker == "unknown"
        result.verify()

    def test_labels_are_canonicalised_in_full_text(self):
        """AGENT_01 and Rep must both render as 'Agent' so full_text is uniform
        regardless of which vendor produced the export."""
        result = parse_text_transcript("AGENT_01: Hello.\nCALLER: Hi.")
        assert result.full_text == "Agent: Hello.\nCustomer: Hi."
        result.verify()

    def test_blank_lines_ignored(self):
        result = parse_text_transcript("Agent: One.\n\n\nCustomer: Two.\n")
        assert result.turn_count == 2
        result.verify()

    def test_crlf_line_endings(self):
        result = parse_text_transcript("Agent: One.\r\nCustomer: Two.")
        assert result.turn_count == 2
        assert "\r" not in result.full_text
        result.verify()

    def test_empty_input_rejected(self):
        with pytest.raises(ValueError):
            parse_text_transcript("   \n  \n ")


class TestTurnListParsing:
    def test_json_turn_array(self):
        result = parse_turn_list(
            [
                {"speaker": "agent", "text": "Hello.", "start_ms": 0},
                {"speaker": "customer", "text": "Hi.", "start_ms": 2000},
            ]
        )
        assert result.turn_count == 2
        assert result.turns[1].start_ms == 2000
        result.verify()

    def test_alternate_field_names(self):
        """Different vendors use role/content or speaker/utterance."""
        result = parse_turn_list(
            [{"role": "Rep", "content": "Hello."}, {"role": "Caller", "utterance": "Hi."}]
        )
        assert [t.speaker for t in result.turns] == ["agent", "customer"]
        result.verify()

    def test_fractional_second_start(self):
        result = parse_turn_list([{"speaker": "agent", "text": "Hi.", "start": 1.5}])
        assert result.turns[0].start_ms == 1500

    def test_blank_turns_dropped(self):
        result = parse_turn_list(
            [{"speaker": "agent", "text": "Hello."}, {"speaker": "customer", "text": "   "}]
        )
        assert result.turn_count == 1


class TestDispatch:
    def test_parse_dispatches_on_type(self):
        assert parse("Agent: Hi.").turn_count == 1
        assert parse([{"speaker": "agent", "text": "Hi."}]).turn_count == 1


class TestStatistics:
    def test_talk_ratio_and_counts(self):
        parsed = parse_text_transcript(
            "Agent: I will explain this in some detail for you now.\n"
            "Customer: Okay.\n"
            "Agent: Does that make sense to you?"
        )
        stats = compute_statistics(parsed)
        assert stats["agent_turn_count"] == 2
        assert stats["customer_turn_count"] == 1
        assert stats["question_count_agent"] == 1
        # The agent dominates, so the ratio must be well above half.
        assert stats["agent_talk_ratio"] > 0.8

    def test_interruption_proxy(self):
        parsed = parse_text_transcript(
            "Agent: So the first thing is.\nCustomer: But I.\nAgent: As I was saying."
        )
        assert compute_statistics(parsed)["interruption_count"] == 1
