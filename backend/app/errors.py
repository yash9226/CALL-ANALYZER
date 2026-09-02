"""Domain exceptions and the handlers that turn them into clean HTTP responses.

The database raises meaningful errors of its own — the framework immutability
trigger and publish_framework_version() both raise with SQLSTATE 23514
(check_violation) carrying a human-readable message. Those are surfaced to the
client as 409 Conflict with the original text rather than being swallowed into a
generic 500, so the admin UI can show the user exactly what went wrong.
"""

import logging

import asyncpg
from fastapi import Request, status
from fastapi.responses import JSONResponse

log = logging.getLogger(__name__)


class AppError(Exception):
    """Base class for expected, client-facing failures."""

    status_code = status.HTTP_400_BAD_REQUEST
    code = "app_error"

    def __init__(self, message: str, *, details: dict | None = None):
        super().__init__(message)
        self.message = message
        self.details = details or {}


class NotFound(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "not_found"


class Conflict(AppError):
    """The request is well-formed but conflicts with current state.

    Used for: editing a published framework version, publishing an unbalanced
    tree, publishing a version that is not a draft.
    """

    status_code = status.HTTP_409_CONFLICT
    code = "conflict"


class ValidationError(AppError):
    status_code = 422  # Unprocessable Content (name differs across Starlette versions)
    code = "validation_error"


class Forbidden(AppError):
    status_code = status.HTTP_403_FORBIDDEN
    code = "forbidden"


def _body(code: str, message: str, details: dict | None = None) -> dict:
    return {"error": {"code": code, "message": message, "details": details or {}}}


async def app_error_handler(_: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code, content=_body(exc.code, exc.message, exc.details)
    )


async def postgres_error_handler(_: Request, exc: asyncpg.PostgresError) -> JSONResponse:
    """Translate database-enforced business rules into meaningful HTTP codes.

    check_violation is raised deliberately by our own triggers and functions, so
    it carries a message written for a human and is safe to pass through.
    """
    sqlstate = getattr(exc, "sqlstate", None)

    if sqlstate == "23514":  # check_violation — our immutability + publish guards
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content=_body("constraint_violation", str(exc).split("\n")[0]),
        )
    if sqlstate == "23505":  # unique_violation
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content=_body("duplicate", "A record with that identifier already exists."),
        )
    if sqlstate == "23503":  # foreign_key_violation
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content=_body("reference_violation", "Referenced record does not exist, or is still in use."),
        )
    if sqlstate == "P0001":  # raise_exception from plpgsql
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content=_body("rule_violation", str(exc).split("\n")[0]),
        )

    log.exception("unhandled database error (sqlstate=%s)", sqlstate)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=_body("database_error", "An unexpected database error occurred."),
    )
