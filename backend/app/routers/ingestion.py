"""Ingestion — single call, and CSV/JSON batch upload."""

from typing import Any
from uuid import UUID

from fastapi import APIRouter, File, Query, UploadFile, status
from pydantic import BaseModel, Field

from app.config import get_settings
from app.errors import ValidationError
from app.security import AdminDep, CurrentUserDep
from app.services import ingestion_service as svc

router = APIRouter(prefix="/api/ingestion", tags=["ingestion"])


class SingleCallIn(BaseModel):
    call_code: str = Field(..., description="Unique external call id. Re-posting updates in place.")
    transcript: str | list[dict] = Field(
        ..., description="Speaker-prefixed text, or a JSON array of turn objects"
    )
    agent_code: str | None = Field(None, description="Matched against support_agents.agent_code")
    customer_ref: str | None = None
    started_at: str | None = Field(None, description="ISO 8601; defaults to now")
    duration_seconds: int | None = None
    direction: str | None = Field(None, description="inbound|outbound")
    channel: str | None = Field(None, description="phone|voip|chat|email")
    language: str | None = "en"
    metadata: dict[str, Any] = Field(default_factory=dict)


@router.post("/calls", status_code=status.HTTP_201_CREATED)
async def ingest_single_call(body: SingleCallIn, _: AdminDep):
    """Ingest one call and its transcript.

    The transcript is parsed into speaker turns with exact character offsets
    into the stored full_text, which is what makes later score citations
    highlight the literal justifying words.
    """
    return await svc.ingest_one(body.model_dump(), source="api")


@router.post("/batch", status_code=status.HTTP_201_CREATED)
async def ingest_batch(_: AdminDep, file: UploadFile = File(...)):
    """Bulk import from CSV or JSON.

    Partial-tolerant: bad rows are recorded in the batch's error_log and the
    rest still import, so a 500-row file with three malformed rows yields 497
    calls rather than an unhelpful failure.

    Column names are matched flexibly (call_id / callid / conversation_id all
    map to call_code), and unrecognised columns are preserved in metadata.
    """
    settings = get_settings()
    content = await file.read()
    if len(content) > settings.max_upload_bytes:
        raise ValidationError(
            f"File is {len(content) // 1024}KB; the limit is "
            f"{settings.max_upload_bytes // 1024 // 1024}MB."
        )

    rows = svc.parse_upload(file.filename or "upload", content)
    return await svc.ingest_batch(file.filename or "upload", rows, None, settings.max_batch_rows)


@router.get("/batches")
async def list_batches(_: CurrentUserDep, limit: int = Query(50, ge=1, le=200)):
    return await svc.list_batches(limit)


@router.get("/batches/{batch_id}")
async def get_batch(batch_id: UUID, _: CurrentUserDep):
    """Batch status including the full per-row error log."""
    return await svc.get_batch(batch_id)
