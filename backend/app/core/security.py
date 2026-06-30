"""JWT authentication dependency for FastAPI routes.

Replaces Firebase token verification with pure JWT (python-jose).
Provides role-based access control: admin, customer, restaurant_owner.
"""
from __future__ import annotations

from typing import Optional

from fastapi import Depends, Header, HTTPException, status
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.mssql import get_mssql_db
from app.models.mssql.user import User, UserRole


# ── Token helpers ────────────────────────────────────────────────────────────

def _extract_bearer_token(authorization: Optional[str]) -> str:
    """Pull the token from an `Authorization: Bearer <token>` header."""
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Authorization header. Expected 'Bearer <token>'",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return parts[1]


def decode_token(token: str) -> dict:
    """Decode and validate a JWT. Raises HTTPException on failure."""
    try:
        payload = jwt.decode(
            token,
            settings.secret_key,
            algorithms=[settings.algorithm],
        )
        return payload
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid or expired token: {exc}",
            headers={"WWW-Authenticate": "Bearer"},
        )


# ── Current-user dependency ──────────────────────────────────────────────────

def get_current_user(
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_mssql_db),
) -> User:
    """
    FastAPI dependency that verifies the JWT and returns the User ORM object.

    Usage:
        @router.get("/me")
        def me(user: User = Depends(get_current_user)):
            return {"id": user.id, "email": user.email, "role": user.role}
    """
    token = _extract_bearer_token(authorization)
    payload = decode_token(token)

    user_id: Optional[int] = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing 'sub' (user id) claim",
        )

    user = db.query(User).filter(User.id == int(user_id), User.is_active.is_(True)).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive",
        )
    return user


# ── Role-gated dependencies ──────────────────────────────────────────────────

def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Allow only admin users."""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    return current_user


def require_restaurant_owner(current_user: User = Depends(get_current_user)) -> User:
    """Allow restaurant owners and admins."""
    if current_user.role not in (UserRole.RESTAURANT_OWNER, UserRole.ADMIN):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Restaurant owner or admin access required",
        )
    return current_user


def require_customer(current_user: User = Depends(get_current_user)) -> User:
    """Allow customers and admins."""
    if current_user.role not in (UserRole.CUSTOMER, UserRole.ADMIN):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Customer or admin access required",
        )
    return current_user
