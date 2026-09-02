"""Manager assistant endpoints."""

from uuid import UUID

from fastapi import APIRouter, Query
from pydantic import BaseModel, Field

from app.security import AdminDep, CurrentUserDep
from app.services import chat_service as svc
from app.services import embedding_service as embed

router = APIRouter(prefix="/api/chat", tags=["chat"])


class AskRequest(BaseModel):
    question: str = Field(..., min_length=2, max_length=2000)
    session_id: UUID | None = Field(None, description="Omit for a one-off question")


class SessionCreate(BaseModel):
    title: str = "New conversation"


@router.post("/ask")
async def ask(body: AskRequest, user: CurrentUserDep):
    """Answer a question over transcripts and scores.

    The response carries its full grounding trail: which retrieval path was
    chosen, the transcript excerpts cited, and — for analytical questions — the
    SQL that produced the numbers. A manager must be able to check any figure
    the assistant states.
    """
    return await svc.ask(user, body.question, body.session_id)


@router.get("/sessions")
async def list_sessions(user: CurrentUserDep):
    return await svc.list_sessions(user)


@router.post("/sessions")
async def create_session(body: SessionCreate, user: CurrentUserDep):
    return await svc.create_session(user, body.title)


@router.get("/sessions/{session_id}/messages")
async def get_messages(session_id: UUID, user: CurrentUserDep):
    return await svc.get_messages(user, session_id)


# ── Embedding index ─────────────────────────────────────────────────────────

@router.get("/index/status")
async def index_status(_: CurrentUserDep):
    """How much of the corpus is searchable."""
    return await embed.coverage()


@router.post("/index/build")
async def build_index(
    _: AdminDep,
    limit: int = Query(500, ge=1, le=5000),
    force: bool = Query(False, description="Re-embed calls that already have chunks"),
):
    """Chunk and embed transcripts that are not yet indexed.

    Synchronous: embedding is one API call per chunk batch and the corpus is
    small. A larger deployment would queue this as a job.
    """
    return await embed.embed_pending(limit=limit, force=force)
