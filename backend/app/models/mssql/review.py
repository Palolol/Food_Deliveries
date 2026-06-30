"""Review model (MSSQL — migrated from MySQL)."""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.mssql import MSSQLBase


class Review(MSSQLBase):
    __tablename__ = "reviews"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    # NOTE: NO ondelete CASCADE here.
    # `users -> restaurants (CASCADE) -> reviews (CASCADE)` would create a
    # multi-cascade-path cycle that SQL Server forbids (error 1785).
    # The ORM `cascade="all, delete-orphan"` on Restaurant.reviews handles
    # deletion when a restaurant is removed through a Session. For raw SQL
    # or TRUNCATE, delete restaurants first (see app/clear_db.py order).
    restaurant_id: Mapped[int] = mapped_column(
        ForeignKey("restaurants.id", ondelete="NO ACTION"),
        nullable=False,
        index=True,
    )

    rating: Mapped[int] = mapped_column(Integer, nullable=False)  # 1..5
    comment: Mapped[Optional[str]] = mapped_column(Text)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="reviews")  # noqa: F821
    restaurant: Mapped["Restaurant"] = relationship(  # noqa: F821
        "Restaurant", back_populates="reviews"
    )
