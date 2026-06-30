"""User-related business logic — native auth with bcrypt + JWT."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.mssql.user import User, UserRole

# bcrypt password hasher
_pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ── Password helpers ─────────────────────────────────────────────────────────

def hash_password(plain: str) -> str:
    """Return a bcrypt hash of *plain*."""
    return _pwd_ctx.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    """Return True if *plain* matches *hashed*."""
    return _pwd_ctx.verify(plain, hashed)


# ── JWT helpers ───────────────────────────────────────────────────────────────

def create_access_token(user: User) -> str:
    """Create a signed JWT containing the user id, email, and role."""
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.access_token_expire_minutes
    )
    payload = {
        "sub": str(user.id),
        "email": user.email,
        "role": user.role.value,
        "exp": expire,
    }
    return jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)


# ── User CRUD ─────────────────────────────────────────────────────────────────

def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
    return db.query(User).filter(User.id == user_id).first()


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return db.query(User).filter(User.email == email.lower().strip()).first()


def create_user(
    db: Session,
    *,
    full_name: str,
    email: str,
    password: str,
    phone: Optional[str] = None,
    role: UserRole = UserRole.CUSTOMER,
) -> User:
    """Create a new user with a hashed password."""
    user = User(
        email=email.lower().strip(),
        full_name=full_name.strip(),
        phone=phone,
        password_hash=hash_password(password),
        role=role,
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_user(db: Session, email: str, password: str) -> Optional[User]:
    """Return user if credentials are valid, else None."""
    user = get_user_by_email(db, email)
    if not user or not user.is_active:
        return None
    if not verify_password(password, user.password_hash):
        return None
    return user


# ── Legacy helpers (kept for backward compat) ─────────────────────────────────

def get_user_by_firebase_uid(db: Session, firebase_uid: str) -> Optional[User]:
    """Stub — Firebase removed. This alias is no longer meaningful."""
    return None


def get_or_create_user(db: Session, **kwargs) -> Optional[User]:
    """Stub — Firebase removed. Use create_user() instead."""
    return None
