"""User model (MSSQL) — native auth with hashed password and role-based access."""
from __future__ import annotations

import enum
from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, Enum, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.mssql import MSSQLBase


class UserRole(str, enum.Enum):
    """Role-based access control roles."""
    ADMIN            = "admin"
    CUSTOMER         = "customer"
    RESTAURANT_OWNER = "restaurant_owner"


class User(MSSQLBase):
    """
    Application user — authentication handled natively via hashed password + JWT.
    Firebase Auth has been removed.
    """

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)

    email: Mapped[str] = mapped_column(
        String(255), unique=True, index=True, nullable=False
    )
    full_name: Mapped[Optional[str]] = mapped_column(String(255))
    phone: Mapped[Optional[str]] = mapped_column(String(32))
    avatar_url: Mapped[Optional[str]] = mapped_column(String(512))

    # bcrypt-hashed password — never store or expose plain text
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)

    # Role-based access
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, native_enum=False, length=32),
        default=UserRole.CUSTOMER,
        nullable=False,
        index=True,
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    addresses: Mapped[list["Address"]] = relationship(  # noqa: F821
        "Address",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    reviews: Mapped[list["Review"]] = relationship(  # noqa: F821
        "Review",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    restaurants: Mapped[list["Restaurant"]] = relationship(  # noqa: F821
        "Restaurant",
        back_populates="owner",
        cascade="all, delete-orphan",
    )
    orders: Mapped[list["Order"]] = relationship(  # noqa: F821
        "Order",
        back_populates="user",
        cascade="all, delete-orphan",
    )
