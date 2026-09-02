"""Test fixtures.

These are INTEGRATION tests: they run against the real local Supabase database,
because the behaviour worth testing here — the immutability trigger, the
publish-time weight validation, cascade deletes — lives in Postgres. Mocking the
database would test the mock.

The `clean_framework` fixture restores framework v1 as the published version and
removes anything a test created, so the suite is re-runnable and leaves the
seeded state intact.
"""

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from app import db
from app.main import app


@pytest_asyncio.fixture
async def client():
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        await db.connect()
        try:
            yield ac
        finally:
            await db.disconnect()


@pytest_asyncio.fixture
async def clean_framework(client):
    """Restore framework v1 as published and drop any versions a test created."""
    yield
    # Versions must be moved to 'draft' before deletion: the immutability
    # trigger refuses cascade deletes beneath a published or archived tree.
    await db.execute("update framework_versions set status = 'draft' where version_no > 1")
    await db.execute("delete from framework_versions where version_no > 1")
    await db.execute(
        """
        update framework_versions
           set status = 'published', archived_at = null
         where version_no = 1
        """
    )


@pytest_asyncio.fixture
async def clean_calls(client):
    """Remove calls created by a test (identified by the TEST- code prefix)."""
    yield
    await db.execute("delete from calls where call_code like 'TEST-%'")
    await db.execute("delete from ingestion_batches where filename like 'test_%'")
