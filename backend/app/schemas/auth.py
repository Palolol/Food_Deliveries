"""Auth-related Pydantic schemas."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field

from app.schemas.common import ORMBase


class SyncUserIn(BaseModel):
    """Payload for /auth/sync-user — comes from the Flutter client after login."""

    full_name: Optional[str] = Field(default=None, max_length=255)
    phone: Optional[str] = Field(default=None, max_length=32)
    avatar_url: Optional[str] = Field(default=None, max_length=512)


class UserOut(ORMBase):
    id: int
    firebase_uid: str
    email: Optional[str] = None
    full_name: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    is_active: bool
    is_admin: bool
    created_at: datetime
    updated_at: datetime


class AuthMeOut(BaseModel):
    """Combined response: Firebase identity + DB record (if any)."""

    firebase_uid: str
    email: Optional[str] = None
    email_verified: bool = False
    user: Optional[UserOut] = None
