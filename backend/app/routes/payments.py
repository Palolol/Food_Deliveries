"""Payment routes (MSSQL — JWT auth, user_id replaces firebase_uid)."""
from __future__ import annotations

from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.mssql import get_mssql_db
from app.models.mssql.order import Order
from app.models.mssql.payment import Payment, PaymentStatus
from app.models.mssql.user import User, UserRole
from app.schemas.mssql import PaymentCreate, PaymentOut, PaymentUpdate
from app.utils.helpers import generate_transaction_id

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post(
    "",
    response_model=PaymentOut,
    status_code=status.HTTP_201_CREATED,
    summary="Create a payment record for an order",
)
def create_payment(
    payload: PaymentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> PaymentOut:
    order = db.query(Order).filter(Order.id == payload.order_id).one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not allowed to pay for this order")
    if abs(payload.amount - order.total) > 0.01:
        raise HTTPException(
            status_code=400,
            detail=f"Payment amount {payload.amount} does not match order total {order.total}",
        )
    payment = Payment(
        order_id=order.id,
        user_id=current_user.id,
        amount=payload.amount,
        currency=payload.currency,
        method=payload.method,
        status=PaymentStatus.PENDING,
        transaction_id=payload.transaction_id or generate_transaction_id(),
        gateway=payload.gateway,
        gateway_response=payload.gateway_response,
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)
    return PaymentOut.model_validate(payment)


@router.get(
    "/me",
    response_model=List[PaymentOut],
    summary="Payment history for the current user",
)
def list_my_payments(
    status_filter: Optional[PaymentStatus] = Query(default=None, alias="status"),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=200),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> List[PaymentOut]:
    q = db.query(Payment).filter(Payment.user_id == current_user.id)
    if status_filter:
        q = q.filter(Payment.status == status_filter)
    items = (
        q.order_by(Payment.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return [PaymentOut.model_validate(p) for p in items]


@router.get(
    "/order/{order_id}",
    response_model=List[PaymentOut],
    summary="All payments for a specific order (owner or admin)",
)
def list_order_payments(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> List[PaymentOut]:
    order = db.query(Order).filter(Order.id == order_id).one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.user_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Not allowed")
    items = (
        db.query(Payment)
        .filter(Payment.order_id == order_id)
        .order_by(Payment.created_at.desc())
        .all()
    )
    return [PaymentOut.model_validate(p) for p in items]


@router.get("/{payment_id}", response_model=PaymentOut)
def get_payment(
    payment_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> PaymentOut:
    p = db.query(Payment).filter(Payment.id == payment_id).one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="Payment not found")
    if p.user_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Not allowed")
    return PaymentOut.model_validate(p)


@router.patch(
    "/{payment_id}",
    response_model=PaymentOut,
    summary="Update a payment (mark as PAID / REFUNDED / FAILED)",
)
def update_payment(
    payment_id: int,
    payload: PaymentUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> PaymentOut:
    p = db.query(Payment).filter(Payment.id == payment_id).one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="Payment not found")
    if p.user_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Not allowed")

    p.status = payload.status
    if payload.transaction_id is not None:
        p.transaction_id = payload.transaction_id
    if payload.failure_reason is not None:
        p.failure_reason = payload.failure_reason
    if payload.gateway_response is not None:
        p.gateway_response = payload.gateway_response

    now = datetime.now(timezone.utc)
    if payload.status == PaymentStatus.PAID and p.paid_at is None:
        p.paid_at = now
    if payload.status == PaymentStatus.REFUNDED and p.refunded_at is None:
        p.refunded_at = now

    db.commit()
    db.refresh(p)
    return PaymentOut.model_validate(p)
