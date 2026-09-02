# Ready-to-paste Lovable files

Five files. Open one, select all, copy, paste into Lovable. Nothing to assemble.

| Order | File | Where it goes |
|---|---|---|
| 0 | `0-KNOWLEDGE-paste-into-settings.txt` | Lovable → **Settings → Knowledge** (not the chat) |
| 1 | `1-PASTE-THIS-FIRST.txt` | Chat. Design system + app shell + dashboard. **41 KB — send as one message.** |
| 2 | `2-PASTE-SECOND-calls-pages.txt` | Chat. Calls list + drill-down |
| 3 | `3-PASTE-THIRD-admin-panel.txt` | Chat. Framework admin |
| 4 | `4-PASTE-FOURTH-assistant.txt` | Chat. Assistant page |

Wait for each build to finish before sending the next.

File 1 already contains the full `api.ts` inline, so the build agent never has
to remember an earlier message — which is what made the first attempt stall.

**Regenerate them** after editing `LOVABLE_PROMPT.md` or `api.ts`:

```bash
python3 scripts/build_lovable_files.py
```

## If Lovable creates Supabase tables anyway

Its default backend is Supabase, so it sometimes does. Reply:

> Stop. Remove all Supabase code, the client, and any tables you created. This
> app has an existing FastAPI backend. ALL data must come from `src/lib/api.ts`.
> Do not create a database.

Then re-send the file it was working on.
