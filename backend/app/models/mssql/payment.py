"""Payment model (MSSQL).

firebase_uid replaced with user_id FK to the unified users table.
"""
from __future__ import annotations

import enum
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.mssql import MSSQLBase


class PaymentMethod(str, enum.Enum):
    CASH          = "cash"
    CREDIT_CARD   = "credit_card"
    DEBIT_CARD    = "debit_card"
    MOBILE_WALLET = "mobile_wallet"
    ONLINE        = "online"


class PaymentStatus(str, enum.Enum):
    PENDING    = "pending"
    AUTHORIZED = "authorized"
    PAID       = "paid"
    FAILED     = "failed"
    REFUNDED   = "refunded"
    CANCELLED  = "cancelled"


class Payment(MSSQLBase):
    __tablename__ = "payments"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)

    order_id: Mapped[int] = mapped_column(
        # NO ondelete CASCADE: `users -> orders (CASCADE) -> payments (CASCADE)`
        # would form a multi-cascade-path cycle that SQL Server forbids (error 1785).
        # Deletion is handled via the Order.payments relationship cascade or by
        # the explicit delete order in app/clear_db.py.
        ForeignKey("orders.id", ondelete="NO ACTION"),
        nullable=False,
        index=True,
    )

    # FK to users table (replaces firebase_uid)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    amount: Mapped[float] = mapped_column(Float, nullable=False)
    currency: Mapped[str] = mapped_column(String(10), default="USD", nullable=False)

    method: Mapped[PaymentMethod] = mapped_column(
        Enum(PaymentMethod, native_enum=False, length=32),
        nullable=False,
    )
    status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus, native_enum=False, length=32),
        default=PaymentStatus.PENDING,
        nullable=False,
        index=True,
    )

    transaction_id: Mapped[Optional[str]] = mapped_column(
        String(128), unique=True, index=True
    )
    gateway: Mapped[Optional[str]] = mapped_column(String(50))
    gateway_response: Mapped[Optional[str]] = mapped_column(String(2000))
    failure_reason: Mapped[Optional[str]] = mapped_column(String(500))

    paid_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    refunded_at: Mapped[Optional[datetime]] = mapped_column(DateTime)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    order: Mapped["Order"] = relationship("Order", back_populates="payments")  # noqa: F821
