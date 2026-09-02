"""Framework CRUD — the endpoints the admin panel drives.

Read endpoints are open to any authenticated user (managers must see the rubric
to interpret scores). Every mutating endpoint requires an admin.
"""

from uuid import UUID

from fastapi import APIRouter, Query, status

from app.errors import ValidationError
from app.schemas import framework as s
from app.security import AdminDep, CurrentUserDep
from app.services import framework_service as svc

router = APIRouter(prefix="/api/framework", tags=["framework"])


# ── Versions ────────────────────────────────────────────────────────────────

@router.get("/versions", response_model=list[s.FrameworkVersionSummary])
async def list_versions(_: CurrentUserDep):
    """All framework versions, newest first, with node and usage counts."""
    return await svc.list_versions()


@router.get("/active", response_model=s.FrameworkVersionDetail)
async def get_active_framework(_: CurrentUserDep):
    """The currently published rubric tree — what new evaluations score against."""
    return await svc.get_tree(await svc.get_active_version_id())


@router.post("/draft", response_model=s.FrameworkVersionDetail)
async def get_or_create_draft(user: AdminDep):
    """Return an editable draft, cloning the published version if none exists.

    The admin panel calls this when the user clicks "Edit framework", so they
    are never editing a published version by accident.
    """
    tree, _created = await svc.ensure_draft(user.id)
    return tree


@router.get("/versions/{version_id}", response_model=s.FrameworkVersionDetail)
async def get_version(version_id: UUID, _: CurrentUserDep):
    return await svc.get_tree(version_id)


@router.post("/versions/{version_id}/clone", response_model=s.FrameworkVersionDetail)
async def clone_version(version_id: UUID, body: s.CloneRequest, user: AdminDep):
    """Deep-copy a version into a new draft. The only way to change a published rubric."""
    return await svc.clone_version(version_id, body.name, user.id)


@router.get("/versions/{version_id}/validate", response_model=s.ValidationResult)
async def validate_version(version_id: UUID, _: CurrentUserDep):
    """Weight and structure problems. Empty issues list means publishable.

    The admin panel polls this as the user edits, so imbalance is visible
    immediately rather than only being discovered at publish time.
    """
    return await svc.validate_weights(version_id)


@router.post("/versions/{version_id}/normalize", response_model=s.FrameworkVersionDetail)
async def normalize_version(version_id: UUID, _: AdminDep):
    """Auto-balance: rescale enabled siblings to sum to 100, preserving proportions."""
    return await svc.normalize_weights(version_id)


@router.post("/versions/{version_id}/publish", response_model=s.PublishResult)
async def publish_version(version_id: UUID, user: AdminDep):
    """Validate, archive the incumbent, and promote this draft — atomically.

    Fails with 409 and the specific imbalance if the tree does not sum to 100
    at every level.
    """
    return await svc.publish_version(version_id, user.id)


@router.post("/versions/{version_id}/apply", response_model=s.ReprojectResult)
async def apply_to_history(
    version_id: UUID,
    _: AdminDep,
    only_current: bool = Query(True, description="Only re-project current evaluations"),
):
    """Apply this version's weights across historical evaluations.

    Returns how many were recomputed instantly (pure arithmetic, no LLM calls)
    versus how many were queued for re-scoring because this version introduced
    criteria that have never been scored.
    """
    return await svc.reproject(version_id, only_current)


# ── Sections ────────────────────────────────────────────────────────────────

@router.post("/sections", response_model=s.Section, status_code=status.HTTP_201_CREATED)
async def create_section(body: s.SectionCreate, _: AdminDep):
    row = await svc.create_section(body.model_dump())
    return {**row, "subsections": []}


@router.patch("/sections/{section_id}", response_model=s.Section)
async def update_section(section_id: UUID, body: s.SectionUpdate, _: AdminDep):
    row = await svc.update_section(section_id, body.model_dump(exclude_unset=True))
    return {**row, "subsections": []}


@router.delete("/sections/{section_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_section(section_id: UUID, _: AdminDep):
    await svc.delete_section(section_id)


# ── Sub-sections ────────────────────────────────────────────────────────────

@router.post("/subsections", response_model=s.Subsection, status_code=status.HTTP_201_CREATED)
async def create_subsection(body: s.SubsectionCreate, _: AdminDep):
    row = await svc.create_subsection(body.model_dump())
    return {**row, "criteria": []}


@router.patch("/subsections/{subsection_id}", response_model=s.Subsection)
async def update_subsection(subsection_id: UUID, body: s.SubsectionUpdate, _: AdminDep):
    row = await svc.update_subsection(subsection_id, body.model_dump(exclude_unset=True))
    return {**row, "criteria": []}


@router.delete("/subsections/{subsection_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_subsection(subsection_id: UUID, _: AdminDep):
    await svc.delete_subsection(subsection_id)


# ── Criteria ────────────────────────────────────────────────────────────────

@router.post("/criteria", response_model=s.Criterion, status_code=status.HTTP_201_CREATED)
async def create_criterion(body: s.CriterionCreate, _: AdminDep):
    return await svc.create_criterion(body.model_dump())


@router.patch("/criteria/{criterion_id}", response_model=s.Criterion)
async def update_criterion(criterion_id: UUID, body: s.CriterionUpdate, _: AdminDep):
    return await svc.update_criterion(criterion_id, body.model_dump(exclude_unset=True))


@router.delete("/criteria/{criterion_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_criterion(criterion_id: UUID, _: AdminDep):
    await svc.delete_criterion(criterion_id)


# ── Reordering ──────────────────────────────────────────────────────────────

@router.post("/{level}/reorder")
async def reorder(level: str, body: s.ReorderRequest, _: AdminDep):
    """Bulk display_order update for drag-and-drop reordering."""
    if level not in ("sections", "subsections", "criteria"):
        raise ValidationError("level must be one of: sections, subsections, criteria")
    updated = await svc.reorder(level, [i.model_dump() for i in body.items])
    return {"message": f"Reordered {updated} {level}.", "details": {"updated": updated}}
