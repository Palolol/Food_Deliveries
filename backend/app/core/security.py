"""Firebase token verification dependency for FastAPI routes."""
from __future__ import annotations

from typing import Optional

from fastapi import Depends, Header, HTTPException, status
from firebase_admin import auth as fb_auth

from app.core.firebase import verify_firebase_token


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


class FirebaseUser:
    """Decoded Firebase identity attached to the request."""

    def __init__(self, uid: str, email: Optional[str], claims: dict) -> None:
        self.uid = uid
        self.email = email
        self.claims = claims

    @property
    def is_email_verified(self) -> bool:
        return bool(self.claims.get("email_verified", False))

    def __repr__(self) -> str:  # pragma: no cover
        return f"FirebaseUser(uid={self.uid!r}, email={self.email!r})"


def get_current_user(
    authorization: Optional[str] = Header(default=None),
) -> FirebaseUser:
    """
    FastAPI dependency that verifies the Firebase ID token and returns the user.

    Usage:
        @router.get("/me")
        def me(user: FirebaseUser = Depends(get_current_user)):
            return {"uid": user.uid, "email": user.email}
    """
    token = _extract_bearer_token(authorization)
    try:
        claims = verify_firebase_token(token)
    except fb_auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase ID token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except fb_auth.RevokedIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase ID token has been revoked",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except fb_auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Firebase ID token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token verification failed: {exc}",
            headers={"WWW-Authenticate": "Bearer"},
        )

    uid = claims.get("uid") or claims.get("user_id") or claims.get("sub")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase token missing 'uid'/'sub' claim",
        )
    return FirebaseUser(uid=uid, email=claims.get("email"), claims=claims)
