"""Business logic for the dynamic quality framework.

EDITING MODEL
-------------
A published version is immutable — enforced by a database trigger, so the API
cannot bypass it even by accident. Editing therefore always happens on a draft.

The API does NOT auto-clone behind the user's back. Silently forking the rubric
because someone changed a weight would make version history unpredictable and
fill the list with accidental drafts. Instead:

  * mutating a published version returns 409 with an actionable message
  * `ensure_draft()` (POST /framework/draft) returns the existing draft, or
    clones the published version into one, and tells the caller which happened

so the admin UI can show "Editing draft v3" before the user's first keystroke.
"""

import logging
from uuid import UUID

from app import db
from app.errors import Conflict, NotFound, ValidationError

log = logging.getLogger(__name__)

# Columns that are safe to PATCH, per level. Whitelisting rather than trusting
# the payload keeps a stray field name from being interpolated into SQL.
_SECTION_FIELDS = {"name", "description", "weight", "display_order", "is_enabled"}
_SUBSECTION_FIELDS = _SECTION_FIELDS
_CRITERION_FIELDS = {
    "name", "description", "weight", "scoring_type", "max_score", "min_score",
    "guidance", "examples", "is_critical", "allow_na", "display_order", "is_enabled",
}
_JSON_FIELDS = {"examples"}


# ── Version queries ─────────────────────────────────────────────────────────

async def list_versions() -> list[dict]:
    return await db.fetch(
        """
        select fv.id, fv.version_no, fv.name, fv.description, fv.status::text as status,
               fv.notes, fv.cloned_from, fv.published_at, fv.archived_at, fv.created_at,
               (select count(*) from sections s
                 where s.framework_version_id = fv.id)                    as section_count,
               (select count(*) from subsections ss
                  join sections s on s.id = ss.section_id
                 where s.framework_version_id = fv.id)                    as subsection_count,
               (select count(*) from criteria c
                  join subsections ss on ss.id = c.subsection_id
                  join sections s on s.id = ss.section_id
                 where s.framework_version_id = fv.id)                    as criterion_count,
               (select count(*) from evaluations e
                 where e.framework_version_id = fv.id)                    as evaluation_count
          from framework_versions fv
         order by fv.version_no desc
        """
    )


async def get_version_row(version_id: UUID) -> dict:
    row = await db.fetchrow(
        "select *, status::text as status from framework_versions where id = $1", version_id
    )
    if not row:
        raise NotFound(f"Framework version {version_id} does not exist.")
    return row


async def get_active_version_id() -> UUID:
    vid = await db.fetchval("select id from framework_versions where status = 'published'")
    if not vid:
        raise NotFound("No published framework version exists. Publish a draft first.")
    return vid


async def get_tree(version_id: UUID) -> dict:
    """Return the full nested Section -> Subsection -> Criterion tree.

    One flat query assembled in Python rather than three round trips or a
    recursive CTE. At 5/12/31 nodes the join is trivial, and the assembly code
    is far easier to read than nested jsonb aggregation.
    """
    version = await get_version_row(version_id)

    rows = await db.fetch(
        """
        select s.id as s_id, s.code as s_code, s.name as s_name, s.description as s_desc,
               s.weight as s_weight, s.display_order as s_order, s.is_enabled as s_enabled,
               ss.id as ss_id, ss.code as ss_code, ss.name as ss_name,
               ss.description as ss_desc, ss.weight as ss_weight,
               ss.display_order as ss_order, ss.is_enabled as ss_enabled,
               c.id as c_id, c.code as c_code, c.name as c_name, c.description as c_desc,
               c.weight as c_weight, c.scoring_type::text as c_scoring_type,
               c.max_score as c_max, c.min_score as c_min, c.guidance as c_guidance,
               c.examples as c_examples, c.is_critical as c_critical,
               c.allow_na as c_allow_na, c.display_order as c_order,
               c.is_enabled as c_enabled, c.created_at as c_created, c.updated_at as c_updated
          from sections s
          left join subsections ss on ss.section_id = s.id
          left join criteria c on c.subsection_id = ss.id
         where s.framework_version_id = $1
         order by s.display_order, ss.display_order, c.display_order
        """,
        version_id,
    )

    sections: dict[UUID, dict] = {}
    subsections: dict[UUID, dict] = {}

    for r in rows:
        sid = r["s_id"]
        if sid not in sections:
            sections[sid] = {
                "id": sid, "framework_version_id": version_id, "code": r["s_code"],
                "name": r["s_name"], "description": r["s_desc"],
                "weight": float(r["s_weight"]), "display_order": r["s_order"],
                "is_enabled": r["s_enabled"], "subsections": [],
            }

        ssid = r["ss_id"]
        if ssid and ssid not in subsections:
            subsections[ssid] = {
                "id": ssid, "section_id": sid, "code": r["ss_code"], "name": r["ss_name"],
                "description": r["ss_desc"], "weight": float(r["ss_weight"]),
                "display_order": r["ss_order"], "is_enabled": r["ss_enabled"],
                "criteria": [],
            }
            sections[sid]["subsections"].append(subsections[ssid])

        if r["c_id"]:
            subsections[ssid]["criteria"].append({
                "id": r["c_id"], "subsection_id": ssid, "code": r["c_code"],
                "name": r["c_name"], "description": r["c_desc"],
                "weight": float(r["c_weight"]), "scoring_type": r["c_scoring_type"],
                "max_score": float(r["c_max"]), "min_score": float(r["c_min"]),
                "guidance": r["c_guidance"], "examples": r["c_examples"] or [],
                "is_critical": r["c_critical"], "allow_na": r["c_allow_na"],
                "display_order": r["c_order"], "is_enabled": r["c_enabled"],
                "created_at": r["c_created"], "updated_at": r["c_updated"],
            })

    return {**version, "sections": list(sections.values())}


# ── Draft guard ─────────────────────────────────────────────────────────────

async def _assert_draft(version_id: UUID) -> None:
    """Reject writes to a non-draft version with an actionable message.

    The database trigger enforces this too. Checking here as well means the user
    gets a sentence they can act on instead of a raw SQLSTATE.
    """
    status = await db.fetchval(
        "select status::text from framework_versions where id = $1", version_id
    )
    if status is None:
        raise NotFound(f"Framework version {version_id} does not exist.")
    if status != "draft":
        raise Conflict(
            f"Framework version is '{status}' and cannot be edited. "
            f"Clone it to a draft first (POST /api/framework/draft).",
            details={"framework_version_id": str(version_id), "status": status},
        )


async def _version_of_section(section_id: UUID) -> UUID:
    vid = await db.fetchval("select framework_version_id from sections where id = $1", section_id)
    if not vid:
        raise NotFound(f"Section {section_id} does not exist.")
    return vid


async def _version_of_subsection(subsection_id: UUID) -> UUID:
    vid = await db.fetchval(
        """
        select s.framework_version_id from subsections ss
          join sections s on s.id = ss.section_id
         where ss.id = $1
        """,
        subsection_id,
    )
    if not vid:
        raise NotFound(f"Sub-section {subsection_id} does not exist.")
    return vid


async def _version_of_criterion(criterion_id: UUID) -> UUID:
    vid = await db.fetchval(
        """
        select s.framework_version_id from criteria c
          join subsections ss on ss.id = c.subsection_id
          join sections s on s.id = ss.section_id
         where c.id = $1
        """,
        criterion_id,
    )
    if not vid:
        raise NotFound(f"Criterion {criterion_id} does not exist.")
    return vid


def _build_patch(payload: dict, allowed: set[str], start_index: int = 1) -> tuple[str, list]:
    """Build a parameterised SET clause from a PATCH payload."""
    updates = {k: v for k, v in payload.items() if k in allowed and v is not None}
    if not updates:
        raise ValidationError("No updatable fields supplied.")

    clauses, args = [], []
    for i, (key, value) in enumerate(updates.items(), start=start_index):
        if key in _JSON_FIELDS:
            # Pass the Python object, not a JSON string: db.py registers a jsonb
            # codec whose encoder already calls json.dumps. Encoding here too
            # would store a JSON string containing JSON.
            clauses.append(f"{key} = ${i}::jsonb")
            args.append(value)
        else:
            clauses.append(f"{key} = ${i}")
            args.append(value)
    return ", ".join(clauses), args


# ── Section CRUD ────────────────────────────────────────────────────────────

async def create_section(data: dict) -> dict:
    await _assert_draft(data["framework_version_id"])
    return await db.fetchrow(
        """
        insert into sections (framework_version_id, code, name, description,
                              weight, display_order, is_enabled)
        values ($1, $2, $3, $4, $5, $6, $7)
        returning *
        """,
        data["framework_version_id"], data["code"], data["name"], data.get("description"),
        data["weight"], data["display_order"], data["is_enabled"],
    )


async def update_section(section_id: UUID, payload: dict) -> dict:
    await _assert_draft(await _version_of_section(section_id))
    set_clause, args = _build_patch(payload, _SECTION_FIELDS, start_index=2)
    return await db.fetchrow(
        f"update sections set {set_clause} where id = $1 returning *", section_id, *args
    )


async def delete_section(section_id: UUID) -> None:
    await _assert_draft(await _version_of_section(section_id))
    await db.execute("delete from sections where id = $1", section_id)


# ── Sub-section CRUD ────────────────────────────────────────────────────────

async def create_subsection(data: dict) -> dict:
    await _assert_draft(await _version_of_section(data["section_id"]))
    return await db.fetchrow(
        """
        insert into subsections (section_id, code, name, description,
                                 weight, display_order, is_enabled)
        values ($1, $2, $3, $4, $5, $6, $7)
        returning *
        """,
        data["section_id"], data["code"], data["name"], data.get("description"),
        data["weight"], data["display_order"], data["is_enabled"],
    )


async def update_subsection(subsection_id: UUID, payload: dict) -> dict:
    await _assert_draft(await _version_of_subsection(subsection_id))
    set_clause, args = _build_patch(payload, _SUBSECTION_FIELDS, start_index=2)
    return await db.fetchrow(
        f"update subsections set {set_clause} where id = $1 returning *", subsection_id, *args
    )


async def delete_subsection(subsection_id: UUID) -> None:
    await _assert_draft(await _version_of_subsection(subsection_id))
    await db.execute("delete from subsections where id = $1", subsection_id)


# ── Criterion CRUD ──────────────────────────────────────────────────────────

async def create_criterion(data: dict) -> dict:
    await _assert_draft(await _version_of_subsection(data["subsection_id"]))

    if data["max_score"] <= data["min_score"]:
        raise ValidationError("max_score must be greater than min_score.")

    return await db.fetchrow(
        """
        insert into criteria (subsection_id, code, name, description, weight,
                              scoring_type, max_score, min_score, guidance, examples,
                              is_critical, allow_na, display_order, is_enabled)
        values ($1, $2, $3, $4, $5, $6::scoring_type, $7, $8, $9, $10::jsonb,
                $11, $12, $13, $14)
        returning *
        """,
        data["subsection_id"], data["code"], data["name"], data.get("description"),
        data["weight"], data["scoring_type"], data["max_score"], data["min_score"],
        data.get("guidance"), data.get("examples") or [],
        data["is_critical"], data["allow_na"], data["display_order"], data["is_enabled"],
    )


async def update_criterion(criterion_id: UUID, payload: dict) -> dict:
    await _assert_draft(await _version_of_criterion(criterion_id))
    set_clause, args = _build_patch(payload, _CRITERION_FIELDS, start_index=2)
    # scoring_type needs an explicit cast; asyncpg sends it as text otherwise.
    set_clause = set_clause.replace("scoring_type = $", "scoring_type = $")
    row = await db.fetchrow(
        f"update criteria set {set_clause} where id = $1 returning *", criterion_id, *args
    )
    return row


async def delete_criterion(criterion_id: UUID) -> None:
    await _assert_draft(await _version_of_criterion(criterion_id))
    await db.execute("delete from criteria where id = $1", criterion_id)


async def reorder(level: str, items: list[dict]) -> int:
    """Bulk display_order update, for drag-and-drop in the admin panel.

    One statement using unnest() rather than N round trips — a drag operation
    can renumber every sibling at once.
    """
    table = {"sections": "sections", "subsections": "subsections", "criteria": "criteria"}[level]
    if not items:
        return 0

    resolver = {
        "sections": _version_of_section,
        "subsections": _version_of_subsection,
        "criteria": _version_of_criterion,
    }[level]
    await _assert_draft(await resolver(items[0]["id"]))

    ids = [i["id"] for i in items]
    orders = [i["display_order"] for i in items]
    result = await db.execute(
        f"""
        update {table} t
           set display_order = v.display_order
          from (select unnest($1::uuid[]) as id, unnest($2::int[]) as display_order) v
         where t.id = v.id
        """,
        ids, orders,
    )
    return int(result.split()[-1]) if result else 0


# ── Lifecycle ───────────────────────────────────────────────────────────────

async def validate_weights(version_id: UUID) -> dict:
    await get_version_row(version_id)
    issues = await db.fetch(
        "select level, node_path, node_id, issue, actual_sum from validate_framework_weights($1)",
        version_id,
    )
    return {
        "is_valid": len(issues) == 0,
        "issues": [{**i, "actual_sum": float(i["actual_sum"])} for i in issues],
    }


async def normalize_weights(version_id: UUID) -> dict:
    """Auto-balance: rescale enabled siblings to sum to 100 at every level."""
    await _assert_draft(version_id)
    await db.execute("select normalize_framework_weights($1)", version_id)
    return await get_tree(version_id)


async def clone_version(source_id: UUID, new_name: str | None, created_by: UUID | None) -> dict:
    await get_version_row(source_id)
    new_id = await db.fetchval(
        "select clone_framework_version($1, $2, $3)", source_id, new_name, created_by
    )
    log.info("cloned framework %s -> %s", source_id, new_id)
    return await get_tree(new_id)


async def ensure_draft(created_by: UUID | None) -> tuple[dict, bool]:
    """Return an editable draft, cloning the published version if needed.

    Returns (tree, was_created) so the UI can say "Editing existing draft v3"
    versus "Created draft v4 from published v3".
    """
    existing = await db.fetchval(
        "select id from framework_versions where status = 'draft' order by version_no desc limit 1"
    )
    if existing:
        return await get_tree(existing), False

    published = await get_active_version_id()
    return await clone_version(published, None, created_by), True


async def publish_version(version_id: UUID, published_by: UUID | None) -> dict:
    """Validate, archive the incumbent, promote the draft — one transaction.

    publish_framework_version() raises if the tree is unbalanced; that surfaces
    as a 409 with the specific problem, so the UI can point at the offending
    level instead of saying "publish failed".
    """
    await get_version_row(version_id)
    archived_id = await db.fetchval(
        "select publish_framework_version($1, $2)", version_id, published_by
    )
    log.info("published framework %s (archived %s)", version_id, archived_id)
    return {
        "published_version_id": version_id,
        "archived_version_id": archived_id,
        "message": (
            f"Published. Previous version archived."
            if archived_id
            else "Published as the first active framework version."
        ),
    }


async def reproject(version_id: UUID, only_current: bool = True) -> dict:
    """Apply a framework version across historical evaluations.

    The two returned counts are the whole point of the design: `recomputed`
    cost nothing (pure arithmetic over existing scores), while `queued` needs
    the scoring agent because those evaluations lack scores for criteria this
    version introduced.
    """
    await get_version_row(version_id)
    row = await db.fetchrow(
        """
        select evaluations_recomputed, evaluations_incomplete
          from reproject_evaluations_to_version($1, $2)
        """,
        version_id, only_current,
    )
    recomputed = row["evaluations_recomputed"] or 0
    queued = row["evaluations_incomplete"] or 0

    parts = [f"{recomputed} evaluation(s) recomputed instantly with no LLM calls"]
    if queued:
        parts.append(f"{queued} queued for re-scoring (new criteria require the scoring agent)")

    return {
        "framework_version_id": version_id,
        "recomputed_instantly": recomputed,
        "queued_for_rescoring": queued,
        "message": " · ".join(parts),
    }
