# Frontend

React dashboard. **Generated with Lovable against the typed contract in
[`src/lib/api.ts`](src/lib/api.ts)**, then wired to the live backend.

## The contract is the point

`src/lib/api.ts` is hand-written to match the live FastAPI schema exactly. It is
the only place the app talks to the network.

That constraint exists because Lovable, left alone, invents its own Supabase
tables and queries — and merging that into a real schema is miserable. Pinning
every call to one typed module makes the handoff a swap rather than a rewrite:
integrating a generated frontend is `MOCK = false` plus a `VITE_API_URL`.

Three rules for anything added here:

1. **No `fetch` outside `src/lib/api.ts`.**
2. **No Supabase client.** Scoring, weighting and access control live behind the
   API; bypassing it produces numbers that disagree with the rest of the product.
3. **Never invent a field.** If it is not in the types, the backend does not
   return it.

The backend has contract tests (`backend/tests/test_api_contract.py`) that fail
if a response stops matching these types, so drift is caught in CI rather than
appearing as a blank cell in a dashboard weeks later.

## Generating the UI

The full Lovable prompt is in [`docs/LOVABLE_PROMPT.md`](../docs/LOVABLE_PROMPT.md).

## Running against the real backend

```bash
echo "VITE_API_URL=http://localhost:8000" > .env
npm install
npm run dev
```

Then set `export const MOCK = false;` in `src/lib/api.ts`.

With `MOCK = true` the app runs entirely on fixtures — useful for building UI
before the backend is up, and for demos.

## Two details that are easy to get wrong

**Citation highlighting.** Use `char_start` / `char_end` from the citation, and
the `highlightSegments()` helper. Do **not** search the transcript for
`quoted_text` — the model paraphrases, so the search fails. The offsets are
guaranteed exact against `transcript.full_text`.

**Not-applicable scores.** `is_applicable === false` must render as "N/A", never
as 0. The backend removes those criteria from the weighted denominator; showing
0 misrepresents the agent's performance.

---

## Built directly, not generated

The Lovable route stalled (its build agent does not reliably inherit chat
history, and its default backend is Supabase), so the UI was written here
against the same `api.ts` contract the prompt pack specifies. The prompt pack in
[docs/lovable/](../docs/lovable/) is still valid if you want to regenerate the
UI later — the contract is unchanged.

## Verified against the live backend

Rendered headlessly and checked, not just compiled:

| Check | Result |
|---|---|
| `tsc --noEmit` | clean |
| `npm run build` | succeeds |
| Console errors, all pages | 0 |
| Dashboard | 84 calls, 8 live analytics endpoints, 2 charts |
| Calls list | 84 rows, server-side pagination, transcript full-text search |
| Drill-down | 5 tabs, 16 transcript turns, auto-fail banner with reason |
| Citation highlighting | clicking a criterion highlights exactly its cited turns |
| Light and dark | both verified by screenshot |

### Bugs this surfaced

- **Pipeline tab read "Scoring — retried ×12"** when nothing had been retried.
  The scoring agent issues one request per sub-section and was summing raw
  attempt counts, so a clean 12-request run reported as 12 retries. Fixed in the
  backend; `attempt_count` now measures retry pressure and
  `subsection_requests` reports volume separately. Two regression tests added.
- **Scorecard sections rendered alphabetically** (Closing first). Now ordered by
  the rubric's own `display_order`, so a reviewer reads Opening → Communication
  → Resolution → Compliance → Closing, which is the order the call happened in.
- Charts appeared empty on first paint — Recharts' entry animation. Disabled;
  in a tool where every filter change redraws each chart, it read as flicker.
- Distribution y-axis labels were clipped to their last digit by a negative
  margin, so every tick read "0".
