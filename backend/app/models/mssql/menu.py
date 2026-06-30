"""MenuItem model (MSSQL — migrated from MySQL)."""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.mssql import MSSQLBase


class MenuItem(MSSQLBase):
    __tablename__ = "menu_items"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)

    restaurant_id: Mapped[int] = mapped_column(
        ForeignKey("restaurants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    description: Mapped[Optional[str]] = mapped_column(Text)
    category: Mapped[Optional[str]] = mapped_column(String(100), index=True)
    price: Mapped[float] = mapped_column(Float, nullable=False)
    discount_price: Mapped[Optional[float]] = mapped_column(Float)

    image_url: Mapped[Optional[str]] = mapped_column(String(512))

    is_available: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_vegetarian: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_vegan: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_gluten_free: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    preparation_time_minutes: Mapped[Optional[int]] = mapped_column(Integer)
    calories: Mapped[Optional[int]] = mapped_column(Integer)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    restaurant: Mapped["Restaurant"] = relationship(  # noqa: F821
        "Restaurant", back_populates="menu_items"
    )
