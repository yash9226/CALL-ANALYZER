# Backend

FastAPI application. Framework CRUD and ingestion (Phase 2); the agent pipeline
and chatbot land here in Phases 3–7.

## Run

```bash
cd backend
uv venv --python 3.12
uv pip install -e ".[dev]"
.venv/bin/uvicorn app.main:app --reload --port 8000
```

Interactive docs: <http://localhost:8000/docs>

Requires the local Supabase stack (`supabase start` from the repo root) and a
`.env` at the repo root — see `.env.example`.

## Test

```bash
.venv/bin/python -m pytest tests/ -q
```

These are **integration tests against the real local database**, not mocks. The
behaviour worth testing — the immutability trigger, publish-time weight
validation, cascade deletes — lives in Postgres, so mocking it would only test
the mock. Fixtures restore the seeded state afterwards, so the suite is
re-runnable.

## Auth during development

`AUTH_DEV_BYPASS=true` makes unauthenticated requests behave as an admin, so the
frontend can be built before auth is wired up. The app **refuses to start** if
this is ever true alongside a non-local `DATABASE_URL`, so it cannot reach a
hosted project by accident.
