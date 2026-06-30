"""Restaurant model (MSSQL — migrated from MySQL)."""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.mssql import MSSQLBase


class Restaurant(MSSQLBase):
    __tablename__ = "restaurants"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)

    # Owner references the local users table (no Firebase UID)
    owner_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    description: Mapped[Optional[str]] = mapped_column(Text)
    cuisine_type: Mapped[Optional[str]] = mapped_column(String(100), index=True)
    address: Mapped[Optional[str]] = mapped_column(String(500))
    city: Mapped[Optional[str]] = mapped_column(String(100), index=True)
    latitude: Mapped[Optional[float]] = mapped_column(Float)
    longitude: Mapped[Optional[float]] = mapped_column(Float)

    image_url: Mapped[Optional[str]] = mapped_column(String(512))
    phone: Mapped[Optional[str]] = mapped_column(String(32))
    rating: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_open: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    opening_time: Mapped[Optional[str]] = mapped_column(String(10))  # "HH:MM"
    closing_time: Mapped[Optional[str]] = mapped_column(String(10))  # "HH:MM"

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
    owner: Mapped["User"] = relationship(  # noqa: F821
        "User", back_populates="restaurants"
    )
    menu_items: Mapped[list["MenuItem"]] = relationship(  # noqa: F821
        "MenuItem",
        back_populates="restaurant",
        cascade="all, delete-orphan",
    )
    reviews: Mapped[list["Review"]] = relationship(  # noqa: F821
        "Review",
        back_populates="restaurant",
        cascade="all, delete-orphan",
    )
