"""asyncpg connection pool and query helpers.

WHY RAW SQL AND NOT AN ORM
--------------------------
The scoring engine lives inside Postgres as functions (recompute_evaluation_scores,
publish_framework_version, claim_next_job, search_transcript_chunks). An ORM adds
a mapping layer that these calls would have to punch straight through anyway,
while making the resulting SQL harder to read than the SQL itself.

The pool is created on startup and closed on shutdown; every request borrows a
connection through the `db` dependency in deps.py.
"""

import json
import logging
from typing import Any

import asyncpg

from app.config import get_settings

log = logging.getLogger(__name__)

_pool: asyncpg.Pool | None = None


async def _init_connection(conn: asyncpg.Connection) -> None:
    """Register a JSON codec so jsonb columns come back as dicts, not strings.

    Without this every jsonb read needs a manual json.loads() at the call site,
    which is exactly the kind of thing that gets forgotten in one place and
    produces a confusing bug later.
    """
    await conn.set_type_codec(
        "jsonb", encoder=json.dumps, decoder=json.loads, schema="pg_catalog"
    )
    await conn.set_type_codec(
        "json", encoder=json.dumps, decoder=json.loads, schema="pg_catalog"
    )


async def connect() -> asyncpg.Pool:
    global _pool
    if _pool is None:
        settings = get_settings()
        _pool = await asyncpg.create_pool(
            dsn=settings.database_url,
            min_size=settings.db_pool_min_size,
            max_size=settings.db_pool_max_size,
            init=_init_connection,
            command_timeout=60,
        )
        log.info("database pool created (%s)", settings.database_url.split("@")[-1])
    return _pool


async def disconnect() -> None:
    global _pool
    if _pool is not None:
        await _pool.close()
        _pool = None
        log.info("database pool closed")


def get_pool() -> asyncpg.Pool:
    if _pool is None:
        raise RuntimeError("Database pool not initialised — call connect() on startup")
    return _pool


# ── Convenience wrappers ────────────────────────────────────────────────────
# Thin, but they keep `dict(row)` conversions out of every service function.

async def fetch(query: str, *args: Any) -> list[dict]:
    async with get_pool().acquire() as conn:
        rows = await conn.fetch(query, *args)
        return [dict(r) for r in rows]


async def fetchrow(query: str, *args: Any) -> dict | None:
    async with get_pool().acquire() as conn:
        row = await conn.fetchrow(query, *args)
        return dict(row) if row else None


async def fetchval(query: str, *args: Any) -> Any:
    async with get_pool().acquire() as conn:
        return await conn.fetchval(query, *args)


async def execute(query: str, *args: Any) -> str:
    async with get_pool().acquire() as conn:
        return await conn.execute(query, *args)
