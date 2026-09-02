#!/usr/bin/env python3
"""Generate the ready-to-paste Lovable files from docs/LOVABLE_PROMPT.md.

The prompt document is the single source of truth; these are derived artefacts.
Editing LOVABLE_PROMPT.md or frontend/src/lib/api.ts and re-running this keeps
them in step.

Why the derived files exist at all: Lovable's build agent does not reliably
inherit chat history, so a prompt that says "use the api.ts I sent earlier"
stalls. File 1 therefore embeds api.ts inline, making each message
self-contained.

Usage: python3 scripts/build_lovable_files.py
"""

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "lovable"

# Bound to a name deliberately. Written inline after adjacent string literals,
# `"header" "=" * 70` concatenates the literals FIRST and then repeats the whole
# thing 70 times — which is exactly the bug this comment exists to prevent.
RULE = "=" * 70

BUILD_NOW = (
    "BUILD THIS NOW. Do not ask clarifying questions, do not ask me to re-supply\n"
    "the specification, and do not pause for confirmation — everything you need is\n"
    "in this message. If a detail is unspecified, pick a sensible default, note it\n"
    "in one line at the end, and keep building.\n"
)


def header(line1: str, line2: str = "") -> str:
    return line1 + "\n" + (line2 + "\n" if line2 else "") + RULE + "\n\n"


def extract_prompt_blocks(markdown: str) -> dict[int, str]:
    """Pull the fenced block out of each '## Part N — ...' section."""
    parts = re.split(r"^## Part (\d) — ", markdown, flags=re.M)
    blocks: dict[int, str] = {}
    for i in range(1, len(parts), 2):
        match = re.search(r"^```\n(.*?)^```", parts[i + 1], flags=re.M | re.S)
        if match:
            blocks[int(parts[i])] = match.group(1).rstrip()
    return blocks


def main() -> None:
    markdown = (ROOT / "docs" / "LOVABLE_PROMPT.md").read_text()
    api = (ROOT / "frontend" / "src" / "lib" / "api.ts").read_text().rstrip()
    blocks = extract_prompt_blocks(markdown)

    missing = {1, 2, 3, 4, 5} - set(blocks)
    if missing:
        raise SystemExit(f"LOVABLE_PROMPT.md is missing prompt block(s): {sorted(missing)}")

    OUT.mkdir(parents=True, exist_ok=True)

    (OUT / "0-KNOWLEDGE-paste-into-settings.txt").write_text(
        header("PASTE THIS INTO: Lovable -> Settings -> Knowledge   (NOT the chat box)")
        + blocks[1] + "\n"
    )

    (OUT / "1-PASTE-THIS-FIRST.txt").write_text(
        header("PASTE THIS WHOLE FILE AS ONE MESSAGE IN THE LOVABLE CHAT.",
               "Select all, copy, paste into Lovable, press Enter. Do not split it up.")
        + BUILD_NOW + "\n"
        + "STEP 1 - Create the file src/lib/api.ts with EXACTLY this content:\n\n"
        + "```typescript\n" + api + "\n```\n\n"
        + "STEP 2 - Now build the following, using that file as the only data source:\n\n"
        + blocks[2] + "\n"
    )

    for num, name, what in [
        (3, "2-PASTE-SECOND-calls-pages.txt", "the Calls list and Call drill-down pages"),
        (4, "3-PASTE-THIRD-admin-panel.txt", "the Framework admin panel"),
        (5, "4-PASTE-FOURTH-assistant.txt", "the Assistant (chat) page"),
    ]:
        (OUT / name).write_text(
            header(f"PASTE THIS WHOLE FILE AS ONE MESSAGE - adds {what}.",
                   "Only send this after the previous file's build has FINISHED.")
            + BUILD_NOW + "\n" + blocks[num] + "\n"
        )

    # Guard against a silently truncated embed — the failure mode that would be
    # hardest to spot by eye in a 41 KB file.
    first = (OUT / "1-PASTE-THIS-FIRST.txt").read_text()
    if api not in first:
        raise SystemExit("api.ts was not embedded completely in 1-PASTE-THIS-FIRST.txt")

    for f in sorted(OUT.glob("*.txt")):
        text = f.read_text()
        print(f"  {f.name:42} {len(text.splitlines()):>5} lines  {len(text) // 1024:>4} KB")
    print("\napi.ts embedded and verified complete.")


if __name__ == "__main__":
    main()
