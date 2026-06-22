"""Order and OrderItem models (MSSQL)."""
from __future__ import annotations

import enum
from datetime import datetime
from typing import Optional

from sqlalchemy import (
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.mssql import MSSQLBase


class OrderStatus(str, enum.Enum):
    """Lifecycle states for an order."""

    PENDING = "pending"
    CONFIRMED = "confirmed"
    PREPARING = "preparing"
    OUT_FOR_DELIVERY = "out_for_delivery"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"


class Order(MSSQLBase):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)

    # Orders belong to a Firebase-authenticated user. We store the UID directly
    # (not a FK to MySQL users) so financial data stays in this DB independently.
    firebase_uid: Mapped[str] = mapped_column(
        String(128), nullable=False, index=True
    )
    user_email: Mapped[Optional[str]] = mapped_column(String(255))

    restaurant_id: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    restaurant_name: Mapped[Optional[str]] = mapped_column(String(255))

    # Snapshot of the delivery address at order time
    delivery_address: Mapped[str] = mapped_column(String(500), nullable=False)
    delivery_city: Mapped[Optional[str]] = mapped_column(String(100))
    delivery_postal_code: Mapped[Optional[str]] = mapped_column(String(20))
    delivery_phone: Mapped[Optional[str]] = mapped_column(String(32))

    # Money columns
    subtotal: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    delivery_fee: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    tax: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    discount: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    total: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)

    status: Mapped[OrderStatus] = mapped_column(
        Enum(OrderStatus, native_enum=False, length=32),
        default=OrderStatus.PENDING,
        nullable=False,
        index=True,
    )

    notes: Mapped[Optional[str]] = mapped_column(Text)

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
    items: Mapped[list["OrderItem"]] = relationship(  # noqa: F821
        "OrderItem",
        back_populates="order",
        cascade="all, delete-orphan",
    )
    payments: Mapped[list["Payment"]] = relationship(  # noqa: F821
        "Payment",
        back_populates="order",
        cascade="all, delete-orphan",
    )


class OrderItem(MSSQLBase):
    __tablename__ = "order_items"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)

    order_id: Mapped[int] = mapped_column(
        ForeignKey("orders.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # Snapshot of menu item at order time
    menu_item_id: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    unit_price: Mapped[float] = mapped_column(Float, nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    line_total: Mapped[float] = mapped_column(Float, nullable=False)

    special_instructions: Mapped[Optional[str]] = mapped_column(Text)

    order: Mapped["Order"] = relationship("Order", back_populates="items")