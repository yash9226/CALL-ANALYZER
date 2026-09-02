"""Authentication and role gates.

Supabase Auth issues HS256 JWTs to the React client. The backend verifies them
with the project's JWT secret, then loads the caller's `profiles` row to get
their role and team.

The backend connects as the database owner and therefore BYPASSES RLS. That is
deliberate — the pipeline has to write scores for every team — but it means
authorisation here is not decorative. `require_admin` and the team scoping in
the call service are the real access control for API traffic; the RLS policies
in migration 0010 guard the separate path where the browser talks to Supabase
directly.
"""

import logging
from dataclasses import dataclass
from typing import Annotated

import jwt
from fastapi import Depends, Header, status

from app import db
from app.config import get_settings
from app.errors import AppError, Forbidden

log = logging.getLogger(__name__)


class Unauthorized(AppError):
    status_code = status.HTTP_401_UNAUTHORIZED
    code = "unauthorized"


@dataclass(frozen=True)
class CurrentUser:
    id: str | None
    email: str
    role: str          # 'admin' | 'manager' | 'agent'
    team_id: str | None
    full_name: str

    @property
    def is_admin(self) -> bool:
        return self.role == "admin"

    @property
    def is_manager(self) -> bool:
        return self.role == "manager"


# The identity used when AUTH_DEV_BYPASS is on. Not a real profiles row, so it
# has no id — anything that needs to attribute a write (published_by,
# uploaded_by) stores NULL rather than a fabricated uuid.
DEV_USER = CurrentUser(
    id=None,
    email="dev@localhost",
    role="admin",
    team_id=None,
    full_name="Local Dev (auth bypass)",
)


async def get_current_user(
    authorization: Annotated[str | None, Header()] = None,
) -> CurrentUser:
    settings = get_settings()

    if not authorization or not authorization.lower().startswith("bearer "):
        if settings.auth_dev_bypass:
            return DEV_USER
        raise Unauthorized("Missing bearer token.")

    token = authorization.split(" ", 1)[1].strip()

    try:
        claims = jwt.decode(
            token,
            settings.supabase_jwt_secret,
            algorithms=["HS256"],
            # Supabase stamps this audience on user tokens; checking it stops a
            # token minted for another Supabase service being replayed here.
            audience="authenticated",
        )
    except jwt.ExpiredSignatureError:
        raise Unauthorized("Token has expired.")
    except jwt.InvalidTokenError as exc:
        raise Unauthorized(f"Invalid token: {exc}")

    user_id = claims.get("sub")
    if not user_id:
        raise Unauthorized("Token carries no subject claim.")

    profile = await db.fetchrow(
        """
        select p.id::text, p.email, p.role::text as role,
               p.team_id::text as team_id, p.full_name
          from profiles p
         where p.id = $1::uuid
        """,
        user_id,
    )
    if not profile:
        # The auth user exists but handle_new_user() never created a profile.
        # Failing loudly beats silently granting a default role.
        raise Unauthorized("No profile exists for this account. Contact an administrator.")

    return CurrentUser(**profile)


CurrentUserDep = Annotated[CurrentUser, Depends(get_current_user)]


async def require_admin(user: CurrentUserDep) -> CurrentUser:
    """Gate for every framework-mutating endpoint.

    The rubric defines how every agent in the company is judged, so authorship
    is admin-only. Managers read it; they do not write it.
    """
    if not user.is_admin:
        raise Forbidden("This action requires an administrator account.")
    return user


AdminDep = Annotated[CurrentUser, Depends(require_admin)]
