"""Request/response models for the quality framework.

These double as the API contract handed to the frontend: FastAPI turns them into
OpenAPI, and the typed api.ts the React app is built against is generated from
the same shapes.
"""

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

ScoringType = Literal["binary", "scale_5", "scale_10", "numeric"]
FrameworkStatus = Literal["draft", "published", "archived"]


# ── Criteria ────────────────────────────────────────────────────────────────
class CriterionBase(BaseModel):
    code: str = Field(..., min_length=1, max_length=64, pattern=r"^[A-Z0-9_]+$")
    name: str = Field(..., min_length=1, max_length=200)
    description: str | None = None
    weight: float = Field(0, ge=0, le=1000)
    scoring_type: ScoringType = "scale_5"
    max_score: float = Field(5, gt=0)
    min_score: float = 0
    # Injected verbatim into the scoring agent's prompt. This field is the
    # mechanism by which a business user changes scoring behaviour without a
    # code deploy, so it is a first-class part of the API, not a note field.
    guidance: str | None = None
    examples: list[dict] = Field(default_factory=list)
    is_critical: bool = False
    allow_na: bool = True
    display_order: int = 0
    is_enabled: bool = True


class CriterionCreate(CriterionBase):
    subsection_id: UUID


class CriterionUpdate(BaseModel):
    """All fields optional — PATCH semantics, so the admin UI can send only what
    the user actually changed."""

    model_config = ConfigDict(extra="forbid")

    name: str | None = Field(None, min_length=1, max_length=200)
    description: str | None = None
    weight: float | None = Field(None, ge=0, le=1000)
    scoring_type: ScoringType | None = None
    max_score: float | None = Field(None, gt=0)
    min_score: float | None = None
    guidance: str | None = None
    examples: list[dict] | None = None
    is_critical: bool | None = None
    allow_na: bool | None = None
    display_order: int | None = None
    is_enabled: bool | None = None


class Criterion(CriterionBase):
    id: UUID
    subsection_id: UUID
    created_at: datetime
    updated_at: datetime


# ── Sub-sections ────────────────────────────────────────────────────────────
class SubsectionBase(BaseModel):
    code: str = Field(..., min_length=1, max_length=64, pattern=r"^[A-Z0-9_]+$")
    name: str = Field(..., min_length=1, max_length=200)
    description: str | None = None
    weight: float = Field(0, ge=0, le=1000)
    display_order: int = 0
    is_enabled: bool = True


class SubsectionCreate(SubsectionBase):
    section_id: UUID


class SubsectionUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str | None = Field(None, min_length=1, max_length=200)
    description: str | None = None
    weight: float | None = Field(None, ge=0, le=1000)
    display_order: int | None = None
    is_enabled: bool | None = None


class Subsection(SubsectionBase):
    id: UUID
    section_id: UUID
    criteria: list[Criterion] = Field(default_factory=list)


# ── Sections ────────────────────────────────────────────────────────────────
class SectionBase(BaseModel):
    code: str = Field(..., min_length=1, max_length=64, pattern=r"^[A-Z0-9_]+$")
    name: str = Field(..., min_length=1, max_length=200)
    description: str | None = None
    weight: float = Field(0, ge=0, le=1000)
    display_order: int = 0
    is_enabled: bool = True


class SectionCreate(SectionBase):
    framework_version_id: UUID


class SectionUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str | None = Field(None, min_length=1, max_length=200)
    description: str | None = None
    weight: float | None = Field(None, ge=0, le=1000)
    display_order: int | None = None
    is_enabled: bool | None = None


class Section(SectionBase):
    id: UUID
    framework_version_id: UUID
    subsections: list[Subsection] = Field(default_factory=list)


# ── Versions ────────────────────────────────────────────────────────────────
class FrameworkVersionSummary(BaseModel):
    id: UUID
    version_no: int
    name: str
    description: str | None = None
    status: FrameworkStatus
    notes: str | None = None
    cloned_from: UUID | None = None
    published_at: datetime | None = None
    archived_at: datetime | None = None
    created_at: datetime
    # Counts so the versions list can show shape without fetching whole trees.
    section_count: int = 0
    subsection_count: int = 0
    criterion_count: int = 0
    evaluation_count: int = 0


class FrameworkVersionDetail(FrameworkVersionSummary):
    sections: list[Section] = Field(default_factory=list)


class FrameworkVersionUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str | None = None
    description: str | None = None
    notes: str | None = None


class CloneRequest(BaseModel):
    name: str | None = Field(None, description="Defaults to '<source name> (vN)'")


# ── Validation & publishing ─────────────────────────────────────────────────
class WeightIssue(BaseModel):
    level: str            # 'section' | 'subsection' | 'criterion' | 'structure'
    node_path: str
    node_id: UUID | None = None
    issue: str
    actual_sum: float


class ValidationResult(BaseModel):
    is_valid: bool
    issues: list[WeightIssue] = Field(default_factory=list)


class PublishResult(BaseModel):
    published_version_id: UUID
    archived_version_id: UUID | None = None
    message: str


class ReprojectResult(BaseModel):
    """Outcome of applying a framework version across historical evaluations.

    The split is the point: `recomputed_instantly` cost nothing, while
    `queued_for_rescoring` needs the LLM because those evaluations are missing
    scores for criteria the new version introduced.
    """

    framework_version_id: UUID
    recomputed_instantly: int
    queued_for_rescoring: int
    message: str


class ReorderItem(BaseModel):
    id: UUID
    display_order: int


class ReorderRequest(BaseModel):
    items: list[ReorderItem]
