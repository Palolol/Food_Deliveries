"""Order routes (MSSQL — single database, JWT auth)."""
from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import Session, selectinload

from app.core.security import get_current_user, require_admin
from app.db.mssql import get_mssql_db
from app.models.mssql.order import Order, OrderStatus
from app.models.mssql.user import User, UserRole
from app.schemas.mssql import OrderCreate, OrderOut, OrderStatusUpdate
from app.services.order_service import create_order_with_payment

router = APIRouter(prefix="/orders", tags=["Orders"])


@router.post(
    "",
    response_model=OrderOut,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new order",
)
def create_order(
    payload: OrderCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> OrderOut:
    order, _payment = create_order_with_payment(
        db=db,
        current_user=current_user,
        payload=payload,
    )
    # Reload with items eagerly loaded
    order = (
        db.query(Order)
        .options(selectinload(Order.items))
        .filter(Order.id == order.id)
        .one()
    )
    return OrderOut.model_validate(order)


@router.get(
    "/me",
    response_model=List[OrderOut],
    summary="List the current user's orders",
)
def list_my_orders(
    status_filter: Optional[OrderStatus] = Query(default=None, alias="status"),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=200),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> List[OrderOut]:
    q = db.query(Order).filter(Order.user_id == current_user.id)
    if status_filter:
        q = q.filter(Order.status == status_filter)
    orders = (
        q.options(selectinload(Order.items))
        .order_by(Order.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return [OrderOut.model_validate(o) for o in orders]


@router.get(
    "/{order_id}",
    response_model=OrderOut,
    summary="Get a single order (owner or admin)",
)
def get_order(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> OrderOut:
    order = (
        db.query(Order)
        .options(selectinload(Order.items))
        .filter(Order.id == order_id)
        .one_or_none()
    )
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.user_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Not allowed to view this order")
    return OrderOut.model_validate(order)


@router.patch(
    "/{order_id}/status",
    response_model=OrderOut,
    summary="Update an order's status",
)
def update_order_status(
    order_id: int,
    payload: OrderStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> OrderOut:
    order = db.query(Order).filter(Order.id == order_id).one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    # Only owner or admin can update status
    if order.user_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Not allowed to modify this order")
    order.status = payload.status
    if payload.notes is not None:
        order.notes = payload.notes
    db.commit()
    db.refresh(order)
    order = (
        db.query(Order)
        .options(selectinload(Order.items))
        .filter(Order.id == order_id)
        .one()
    )
    return OrderOut.model_validate(order)


@router.delete(
    "/{order_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    summary="Cancel an order (only when PENDING or CONFIRMED)",
)
def cancel_order(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> Response:
    order = db.query(Order).filter(Order.id == order_id).one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.user_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Not allowed to cancel this order")
    if order.status not in (OrderStatus.PENDING, OrderStatus.CONFIRMED):
        raise HTTPException(
            status_code=400,
            detail=f"Order in status '{order.status.value}' cannot be cancelled",
        )
    order.status = OrderStatus.CANCELLED
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
