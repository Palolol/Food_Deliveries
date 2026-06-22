"""Auth routes: verify Firebase token + sync user to MySQL.

NOTE: This backend does NOT implement login or register.
Flutter handles authentication directly via Firebase Auth and sends the
resulting ID token in the Authorization: Bearer header.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.security import FirebaseUser, get_current_user
from app.db.mysql import get_mysql_db
from app.schemas.auth import AuthMeOut, SyncUserIn, UserOut
from app.services.user_service import get_or_create_user, get_user_by_firebase_uid

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.get(
    "/me",
    response_model=AuthMeOut,
    summary="Get the current authenticated user",
)
def get_me(
    firebase_user: FirebaseUser = Depends(get_current_user),
    db: Session = Depends(get_mysql_db),
) -> AuthMeOut:
    """
    Returns the Firebase identity and the local DB user record.
    The DB record may be None if the user has never called /auth/sync-user.
    """
    user = get_user_by_firebase_uid(db, firebase_user.uid)
    return AuthMeOut(
        firebase_uid=firebase_user.uid,
        email=firebase_user.email,
        email_verified=firebase_user.is_email_verified,
        user=UserOut.model_validate(user) if user else None,
    )


@router.post(
    "/sync-user",
    response_model=UserOut,
    status_code=status.HTTP_201_CREATED,
    summary="Create or update the local user record for a Firebase user",
)
def sync_user(
    payload: SyncUserIn,
    firebase_user: FirebaseUser = Depends(get_current_user),
    db: Session = Depends(get_mysql_db),
) -> UserOut:
    """
    Idempotent: creates the local User row on first call, updates it on
    subsequent calls. Email is taken from the verified token, not the body.
    """
    user = get_or_create_user(
        db,
        firebase_uid=firebase_user.uid,
        email=firebase_user.email,
        full_name=payload.full_name,
        phone=payload.phone,
        avatar_url=payload.avatar_url,
    )

    # Update mutable fields if provided
    updated = False
    if payload.full_name is not None and payload.full_name != user.full_name:
        user.full_name = payload.full_name
        updated = True
    if payload.phone is not None and payload.phone != user.phone:
        user.phone = payload.phone
        updated = True
    if payload.avatar_url is not None and payload.avatar_url != user.avatar_url:
        user.avatar_url = payload.avatar_url
        updated = True

    if updated:
        db.commit()
        db.refresh(user)

    return UserOut.model_validate(user)
