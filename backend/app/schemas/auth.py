"""Auth-related Pydantic schemas — native JWT auth (Firebase removed)."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field

from app.models.mssql.user import UserRole
from app.schemas.common import ORMBase


# ── Register ──────────────────────────────────────────────────────────────────

class RegisterIn(BaseModel):
    """Payload for POST /auth/register."""
    full_name: str = Field(..., min_length=1, max_length=255)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)
    phone: Optional[str] = Field(default=None, max_length=32)
    # Only allow customer self-registration; admin assigns higher roles
    role: UserRole = UserRole.CUSTOMER


class RegisterOut(ORMBase):
    id: int
    email: str
    full_name: Optional[str] = None
    phone: Optional[str] = None
    role: UserRole
    is_active: bool
    created_at: datetime


# ── Login ─────────────────────────────────────────────────────────────────────

class LoginIn(BaseModel):
    """Payload for POST /auth/login."""
    email: EmailStr
    password: str = Field(..., min_length=1)


class TokenOut(BaseModel):
    """Returned on successful login."""
    access_token: str
    token_type: str = "bearer"
    user_id: int
    full_name: Optional[str] = None
    email: str
    role: UserRole


# ── Current user ─────────────────────────────────────────────────────────────

class UserOut(ORMBase):
    id: int
    email: str
    full_name: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    role: UserRole
    is_active: bool
    created_at: datetime
    updated_at: datetime


# ── Admin: update role ────────────────────────────────────────────────────────

class RoleUpdate(BaseModel):
    role: UserRole
