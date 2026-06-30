"""Schemas for the admin / maintenance endpoints."""
from __future__ import annotations

from typing import Dict, Literal, Optional

from pydantic import BaseModel, Field


ClearMode = Literal["delete", "truncate", "recreate"]


class ClearDBRequest(BaseModel):
    """Payload for POST /admin/clear-db."""
    mode: ClearMode = Field(
        default="delete",
        description=(
            "`delete` = ORM DELETE (CASCADE). "
            "`truncate` = TRUNCATE all tables (faster, resets identity). "
            "`recreate` = DROP + re-create every table (nuclear)."
        ),
    )
    confirm: bool = Field(
        default=False,
        description="Must be `true` to actually wipe the database.",
    )
    preserve_admin: bool = Field(
        default=True,
        description=(
            "If true (default), re-insert the calling admin's user row after the "
            "wipe so the JWT keeps working. Ignored for `recreate` mode when "
            "preserving is impossible, but the admin row is still re-inserted "
            "after the schema is rebuilt."
        ),
    )
    new_password: Optional[str] = Field(
        default=None,
        min_length=6,
        max_length=128,
        description=(
            "If provided AND `preserve_admin=true`, reset the admin's password "
            "to this value after the wipe. Useful when you don't remember the "
            "current one."
        ),
    )


class ClearDBResponse(BaseModel):
    """Response from POST /admin/clear-db."""
    status: str
    mode: str
    database: str
    environment: str
    rows_before: Dict[str, int]
    rows_after: Dict[str, int]
    admin_preserved: bool
    admin_email: Optional[str] = None
    admin_id: Optional[int] = None
    new_password_set: bool = False
