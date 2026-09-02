"""Turn raw transcript input into the canonical form the database expects.

THE INVARIANT THIS FILE EXISTS TO PROTECT
-----------------------------------------
`transcripts.full_text` is the single canonical string, and every
`transcript_turns.char_start` / `char_end` indexes into it. The UI highlights a
cited excerpt by slicing that literal range. If offsets and text ever disagree,
every citation in the product silently points at the wrong words.

So the parser NEVER accepts a caller-supplied full_text alongside separately
supplied turns. It always rebuilds full_text from the parsed turns and computes
offsets in the same pass. Producing both from one source makes disagreement
structurally impossible rather than merely unlikely.

Accepted inputs
---------------
1. Speaker-prefixed text (the common case from telephony exports):

       Agent: Thank you for calling, how can I help?
       Customer: My bill is wrong.

2. The same with leading timestamps, which are parsed into start_ms:

       [00:01:23] Agent: Thank you for calling...
       00:01:23 Agent: ...

3. A JSON array of turn objects:

       [{"speaker": "agent", "text": "...", "start_ms": 1200}, ...]

4. Unlabelled prose, which is stored as a single 'unknown' turn rather than
   being rejected — a transcript with no speaker labels is still searchable and
   summarisable, it just cannot support per-speaker statistics.
"""

import re
from dataclasses import dataclass, field

# ── Speaker label normalisation ─────────────────────────────────────────────
# Real exports use wildly inconsistent labels. Mapping them to the speaker_role
# enum here means the rest of the system only ever sees four values.
_AGENT_LABELS = {
    "agent", "rep", "representative", "csr", "advisor", "support",
    "operator", "executive", "associate", "staff", "a",
}
_CUSTOMER_LABELS = {
    "customer", "caller", "client", "user", "subscriber", "member", "c",
}
_SYSTEM_LABELS = {"system", "ivr", "bot", "automated", "recording", "sys"}

# "Agent:", "AGENT_01:", "Agent (Priya):" — capture the label and the remainder.
# The label is bounded to 40 chars so a sentence containing a colon
# ("The problem is this: my bill doubled") is not mistaken for a speaker line.
_SPEAKER_RE = re.compile(r"^\s*([A-Za-z][A-Za-z0-9 _\-\.\(\)]{0,39}?)\s*:\s*(.*)$")

# [00:01:23] / [01:23] / 00:01:23 / (00:01:23)
_TIMESTAMP_RE = re.compile(
    r"^\s*[\[\(]?(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\.(\d{1,3}))?[\]\)]?\s+"
)


def normalise_speaker(label: str) -> str:
    """Map an arbitrary speaker label to the `speaker_role` enum."""
    if not label:
        return "unknown"

    # Strip trailing digits and separators: AGENT_01 -> agent, Speaker 2 -> speaker
    cleaned = re.sub(r"[\s_\-]*\d+$", "", label.strip()).strip().lower()
    # Drop a parenthetical name: "Agent (Priya)" -> "agent"
    cleaned = re.sub(r"\s*\(.*?\)\s*", "", cleaned).strip()

    if cleaned in _AGENT_LABELS:
        return "agent"
    if cleaned in _CUSTOMER_LABELS:
        return "customer"
    if cleaned in _SYSTEM_LABELS:
        return "system"

    # Fall back to substring matching for compounds like "support agent".
    for token in _AGENT_LABELS:
        if len(token) > 1 and token in cleaned:
            return "agent"
    for token in _CUSTOMER_LABELS:
        if len(token) > 1 and token in cleaned:
            return "customer"
    return "unknown"


def _parse_timestamp(line: str) -> tuple[int | None, str]:
    """Strip a leading timestamp, returning (milliseconds, remaining_line)."""
    m = _TIMESTAMP_RE.match(line)
    if not m:
        return None, line

    a, b, c, frac = m.group(1), m.group(2), m.group(3), m.group(4)
    if c is not None:                      # H:MM:SS
        ms = (int(a) * 3600 + int(b) * 60 + int(c)) * 1000
    else:                                  # MM:SS
        ms = (int(a) * 60 + int(b)) * 1000
    if frac:
        ms += int(frac.ljust(3, "0"))

    return ms, line[m.end():]


@dataclass
class ParsedTurn:
    turn_index: int
    speaker: str            # speaker_role enum value
    speaker_label: str      # the original label, preserved for audit
    text: str
    char_start: int
    char_end: int
    start_ms: int | None = None


@dataclass
class ParsedTranscript:
    full_text: str
    turns: list[ParsedTurn] = field(default_factory=list)
    word_count: int = 0

    @property
    def turn_count(self) -> int:
        return len(self.turns)

    def verify(self) -> None:
        """Assert every offset slices back to its own rendered line.

        Cheap (a substring compare per turn) and it converts a whole class of
        silent citation corruption into a loud failure at ingest time. Called
        unconditionally by both parse entry points.
        """
        for turn in self.turns:
            sliced = self.full_text[turn.char_start:turn.char_end]
            expected = f"{turn.speaker_label}: {turn.text}"
            if sliced != expected:
                raise ValueError(
                    f"Offset mismatch on turn {turn.turn_index}: "
                    f"expected {expected!r}, full_text slice gave {sliced!r}"
                )


def _assemble(raw_turns: list[tuple[str, str, str, int | None]]) -> ParsedTranscript:
    """Build canonical full_text and exact offsets from (role, label, text, ms).

    This is the single place full_text is constructed, which is what makes the
    offsets trustworthy.
    """
    lines: list[str] = []
    turns: list[ParsedTurn] = []
    cursor = 0

    for index, (role, label, text, start_ms) in enumerate(raw_turns):
        line = f"{label}: {text}"
        turns.append(
            ParsedTurn(
                turn_index=index,
                speaker=role,
                speaker_label=label,
                text=text,
                char_start=cursor,
                char_end=cursor + len(line),
                start_ms=start_ms,
            )
        )
        lines.append(line)
        cursor += len(line) + 1          # +1 for the '\n' joining the lines

    full_text = "\n".join(lines)
    result = ParsedTranscript(
        full_text=full_text, turns=turns, word_count=len(full_text.split())
    )
    result.verify()
    return result


# ── Canonical display labels ────────────────────────────────────────────────
# Normalising the rendered label (not just the role) keeps full_text uniform
# across sources, so "AGENT_01:" and "Rep:" both render as "Agent:". Prompts and
# search behave consistently as a result.
_DISPLAY = {"agent": "Agent", "customer": "Customer", "system": "System", "unknown": "Speaker"}


def parse_text_transcript(raw: str) -> ParsedTranscript:
    """Parse speaker-prefixed plain text.

    A turn continues across subsequent lines until the next speaker prefix, so
    wrapped paragraphs stay in one turn instead of fragmenting.
    """
    if not raw or not raw.strip():
        raise ValueError("Transcript is empty.")

    collected: list[tuple[str, str, str, int | None]] = []
    current: list[str] | None = None
    current_role = current_label = ""
    current_ms: int | None = None

    for raw_line in raw.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        line = raw_line.strip()
        if not line:
            continue

        start_ms, line = _parse_timestamp(line)
        match = _SPEAKER_RE.match(line)

        if match:
            label_raw, remainder = match.group(1).strip(), match.group(2).strip()
            role = normalise_speaker(label_raw)

            # A colon inside a sentence produces a "label" that normalises to
            # unknown and reads like prose. Treat it as a continuation of the
            # current turn rather than starting a bogus new speaker.
            looks_like_prose = role == "unknown" and (
                " " in label_raw.strip() and len(label_raw.split()) > 3
            )
            if looks_like_prose and current is not None:
                current.append(line)
                continue

            if current is not None:
                collected.append((current_role, current_label, " ".join(current), current_ms))

            current_role = role
            current_label = _DISPLAY[role]
            current_ms = start_ms
            current = [remainder] if remainder else []
        elif current is not None:
            current.append(line)
        else:
            # Text before any speaker label: open an unlabelled turn.
            current_role, current_label, current_ms = "unknown", _DISPLAY["unknown"], start_ms
            current = [line]

    if current is not None:
        collected.append((current_role, current_label, " ".join(current), current_ms))

    collected = [(r, lb, t.strip(), ms) for r, lb, t, ms in collected if t.strip()]
    if not collected:
        raise ValueError("Transcript contains no usable turns.")

    return _assemble(collected)


def parse_turn_list(turns: list[dict]) -> ParsedTranscript:
    """Parse a JSON array of turn objects.

    Accepts {speaker|role|speaker_label} and {text|content|utterance} so that
    exports from different vendors do not each need their own adapter.
    """
    if not turns:
        raise ValueError("Turn list is empty.")

    collected: list[tuple[str, str, str, int | None]] = []
    for raw in turns:
        label_raw = str(
            raw.get("speaker") or raw.get("role") or raw.get("speaker_label") or ""
        ).strip()
        text = str(raw.get("text") or raw.get("content") or raw.get("utterance") or "").strip()
        if not text:
            continue

        role = normalise_speaker(label_raw)
        start_ms = raw.get("start_ms")
        if start_ms is None and raw.get("start") is not None:
            # Some exports use fractional seconds.
            start_ms = int(float(raw["start"]) * 1000)

        collected.append((role, _DISPLAY[role], text, start_ms))

    if not collected:
        raise ValueError("Turn list contains no usable turns.")

    return _assemble(collected)


def parse(payload: str | list[dict]) -> ParsedTranscript:
    """Entry point: dispatch on input shape."""
    if isinstance(payload, list):
        return parse_turn_list(payload)
    return parse_text_transcript(payload)


# ── Deterministic conversation statistics ───────────────────────────────────
# Computed without an LLM. Feeds `call_statistics` and is injected as context
# into the scoring prompt in Phase 3 — an agent who spoke 85% of the time was
# probably not listening, and telling the model that improves its judgement.

_FILLERS = ("um", "uh", "er", "hmm", "like,", "you know", "basically", "actually")


def compute_statistics(parsed: ParsedTranscript) -> dict:
    agent_turns = [t for t in parsed.turns if t.speaker == "agent"]
    customer_turns = [t for t in parsed.turns if t.speaker == "customer"]

    agent_words = sum(len(t.text.split()) for t in agent_turns)
    customer_words = sum(len(t.text.split()) for t in customer_turns)
    total_words = agent_words + customer_words

    # Heuristic interruption proxy for text-only transcripts: the agent speaking
    # twice in a row right after a very short customer turn. Not exact, and
    # honestly labelled as a proxy — with real audio timings we would use
    # overlapping start/end times instead.
    interruptions = 0
    for i in range(1, len(parsed.turns) - 1):
        prev, cur, nxt = parsed.turns[i - 1], parsed.turns[i], parsed.turns[i + 1]
        if (
            cur.speaker == "customer"
            and len(cur.text.split()) <= 4
            and prev.speaker == "agent"
            and nxt.speaker == "agent"
        ):
            interruptions += 1

    lowered = " ".join(t.text.lower() for t in agent_turns)

    return {
        "agent_turn_count": len(agent_turns),
        "customer_turn_count": len(customer_turns),
        "agent_word_count": agent_words,
        "customer_word_count": customer_words,
        "agent_talk_ratio": round(agent_words / total_words, 4) if total_words else None,
        "longest_agent_turn_words": max((len(t.text.split()) for t in agent_turns), default=0),
        "interruption_count": interruptions,
        "question_count_agent": sum(t.text.count("?") for t in agent_turns),
        "filler_word_count": sum(lowered.count(f) for f in _FILLERS),
    }
