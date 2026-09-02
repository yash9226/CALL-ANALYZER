"""FastAPI application entrypoint.

Run:  uvicorn app.main:app --reload --port 8000
Docs: http://localhost:8000/docs
"""

import logging
from contextlib import asynccontextmanager

import asyncpg
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import db
from app.config import get_settings
from app.errors import AppError, app_error_handler, postgres_error_handler
from app.llm import close_provider
from app.routers import analytics, calls, evaluations, framework, ingestion, meta

settings = get_settings()

logging.basicConfig(
    level=settings.log_level,
    format="%(asctime)s %(levelname)-8s %(name)s: %(message)s",
)
log = logging.getLogger("callanalyzer")


@asynccontextmanager
async def lifespan(_: FastAPI):
    # Fail fast and loudly rather than letting the dev bypass reach a real
    # database. AUTH_DEV_BYPASS makes every unauthenticated request an admin,
    # which is fine against localhost and catastrophic against production.
    if settings.auth_dev_bypass and not settings.is_local_database:
        raise RuntimeError(
            "AUTH_DEV_BYPASS is enabled against a non-local database. "
            "Set AUTH_DEV_BYPASS=false before pointing at a hosted Supabase project."
        )

    await db.connect()
    if settings.auth_dev_bypass:
        log.warning("AUTH_DEV_BYPASS is ON — unauthenticated requests are treated as admin")
    log.info("CALL-ANALYZER API ready")
    yield
    await close_provider()
    await db.disconnect()


app = FastAPI(
    title="CALL-ANALYZER API",
    version="0.5.0",
    description=(
        "AI-powered customer support call intelligence.\n\n"
        "**Phase 5** — dashboard analytics.\n\n"
        "The framework is versioned copy-on-write: published versions are immutable, "
        "edits happen on a draft, and publishing validates that weights sum to 100 at "
        "every level. Re-weighting a rubric re-scores history with zero LLM calls."
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_exception_handler(AppError, app_error_handler)
app.add_exception_handler(asyncpg.PostgresError, postgres_error_handler)

app.include_router(meta.router)
app.include_router(framework.router)
app.include_router(calls.router)
app.include_router(ingestion.router)
app.include_router(evaluations.router)
app.include_router(analytics.router)


@app.get("/", include_in_schema=False)
async def root():
    return {"name": "CALL-ANALYZER API", "version": "0.5.0", "docs": "/docs"}
