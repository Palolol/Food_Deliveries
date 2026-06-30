"""Auth routes — native JWT authentication (Firebase removed).

Endpoints:
  POST /auth/register   — self-registration (customer by default)
  POST /auth/login      — email+password → JWT
  GET  /auth/me         — current user info
  GET  /auth/users      — list all users (admin only)
  PATCH /auth/users/{id}/role — update user role (admin only)
"""
from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user, require_admin
from app.db.mssql import get_mssql_db
from app.models.mssql.user import User, UserRole
from app.schemas.auth import (
    LoginIn,
    RegisterIn,
    RegisterOut,
    RoleUpdate,
    TokenOut,
    UserOut,
)
from app.services.user_service import (
    authenticate_user,
    create_access_token,
    create_user,
    get_user_by_email,
    get_user_by_id,
)

router = APIRouter(prefix="/auth", tags=["Auth"])


# ── Register ──────────────────────────────────────────────────────────────────

@router.post(
    "/register",
    response_model=RegisterOut,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new account (customer by default)",
)
def register(
    payload: RegisterIn,
    db: Session = Depends(get_mssql_db),
) -> RegisterOut:
    if get_user_by_email(db, payload.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        )
    user = create_user(
        db,
        full_name=payload.full_name,
        email=payload.email,
        password=payload.password,
        phone=payload.phone,
        role=UserRole.CUSTOMER,  # always customer on self-registration
    )
    return RegisterOut.model_validate(user)


# ── Login ─────────────────────────────────────────────────────────────────────

@router.post(
    "/login",
    response_model=TokenOut,
    summary="Login and receive a JWT access token",
)
def login(
    payload: LoginIn,
    db: Session = Depends(get_mssql_db),
) -> TokenOut:
    user = authenticate_user(db, payload.email, payload.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = create_access_token(user)
    return TokenOut(
        access_token=token,
        token_type="bearer",
        user_id=user.id,
        full_name=user.full_name,
        email=user.email,
        role=user.role,
    )


# ── Current user ──────────────────────────────────────────────────────────────

@router.get(
    "/me",
    response_model=UserOut,
    summary="Get the current authenticated user",
)
def get_me(current_user: User = Depends(get_current_user)) -> UserOut:
    return UserOut.model_validate(current_user)


# ── Admin: user management ────────────────────────────────────────────────────

@router.get(
    "/users",
    response_model=List[UserOut],
    summary="List all users (admin only)",
)
def list_users(
    admin: User = Depends(require_admin),
    db: Session = Depends(get_mssql_db),
) -> List[UserOut]:
    users = db.query(User).order_by(User.id).all()
    return [UserOut.model_validate(u) for u in users]


@router.patch(
    "/users/{user_id}/role",
    response_model=UserOut,
    summary="Update a user's role (admin only)",
)
def update_user_role(
    user_id: int,
    payload: RoleUpdate,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_mssql_db),
) -> UserOut:
    user = get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.role = payload.role
    db.commit()
    db.refresh(user)
    return UserOut.model_validate(user)
