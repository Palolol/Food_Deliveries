"""User-related business logic."""
from __future__ import annotations

from typing import Optional

from sqlalchemy.orm import Session

from app.models.mysql.user import User


def get_user_by_firebase_uid(db: Session, firebase_uid: str) -> Optional[User]:
    """Return a user by Firebase UID, or None if not synced yet."""
    return db.query(User).filter(User.firebase_uid == firebase_uid).first()


def get_or_create_user(
    db: Session,
    firebase_uid: str,
    email: Optional[str] = None,
    full_name: Optional[str] = None,
    phone: Optional[str] = None,
    avatar_url: Optional[str] = None,
) -> User:
    """
    Find a user by Firebase UID, creating a new record if missing.

    This is the only sanctioned way to obtain a `User` row from a Firebase
    identity. All identity flows through this function.
    """
    user = get_user_by_firebase_uid(db, firebase_uid)
    if user:
        return user

    user = User(
        firebase_uid=firebase_uid,
        email=email,
        full_name=full_name,
        phone=phone,
        avatar_url=avatar_url,
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
