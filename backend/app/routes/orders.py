"""Order routes (MSSQL)."""
from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import Session, selectinload

from app.core.security import FirebaseUser, get_current_user
from app.db.mssql import get_mssql_db
from app.db.mysql import get_mysql_db
from app.models.mssql.order import Order, OrderStatus
from app.schemas.mssql import OrderCreate, OrderOut, OrderStatusUpdate
from app.services.order_service import create_order_with_payment

router = APIRouter(prefix="/orders", tags=["Orders"])


@router.post(
    "",
    response_model=OrderOut,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new order (end-to-end: menu lookup + order + payment)",
)
def create_order(
    payload: OrderCreate,
    firebase_user: FirebaseUser = Depends(get_current_user),
    mssql_db: Session = Depends(get_mssql_db),
    mysql_db: Session = Depends(get_mysql_db),
) -> OrderOut:
    """
    Canonical end-to-end order flow:

    1. Firebase token already verified by the dependency.
    2. Fetch menu items from MySQL.
    3. Create order + initial payment in MSSQL atomically.
    4. Return full order with items and payment info.
    """
    order, _payment = create_order_with_payment(
        mssql_db=mssql_db,
        mysql_db=mysql_db,
        firebase_uid=firebase_user.uid,
        user_email=firebase_user.email,
        payload=payload,
    )
    # Reload with items eagerly loaded
    order = (
        mssql_db.query(Order)
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
    firebase_user: FirebaseUser = Depends(get_current_user),
    mssql_db: Session = Depends(get_mssql_db),
) -> List[OrderOut]:
    q = mssql_db.query(Order).filter(Order.firebase_uid == firebase_user.uid)
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
    summary="Get a single order (owner-only)",
)
def get_order(
    order_id: int,
    firebase_user: FirebaseUser = Depends(get_current_user),
    mssql_db: Session = Depends(get_mssql_db),
) -> OrderOut:
    order = (
        mssql_db.query(Order)
        .options(selectinload(Order.items))
        .filter(Order.id == order_id)
        .one_or_none()
    )
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.firebase_uid != firebase_user.uid:
        # Don't leak existence to non-owners
        raise HTTPException(status_code=403, detail="Not allowed to view this order")
    return OrderOut.model_validate(order)


@router.patch(
    "/{order_id}/status",
    response_model=OrderOut,
    summary="Update an order's status (e.g. CONFIRMED, OUT_FOR_DELIVERY)",
)
def update_order_status(
    order_id: int,
    payload: OrderStatusUpdate,
    firebase_user: FirebaseUser = Depends(get_current_user),
    mssql_db: Session = Depends(get_mssql_db),
) -> OrderOut:
    order = mssql_db.query(Order).filter(Order.id == order_id).one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.firebase_uid != firebase_user.uid:
        raise HTTPException(status_code=403, detail="Not allowed to modify this order")
    order.status = payload.status
    if payload.notes is not None:
        order.notes = payload.notes
    mssql_db.commit()
    mssql_db.refresh(order)
    order = (
        mssql_db.query(Order)
        .options(selectinload(Order.items))
        .filter(Order.id == order_id)
        .one()
    )
    return OrderOut.model_validate(order)


@router.delete(
    "/{order_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    summary="Cancel an order (only when still PENDING)",
)
def cancel_order(
    order_id: int,
    firebase_user: FirebaseUser = Depends(get_current_user),
    mssql_db: Session = Depends(get_mssql_db),
) -> Response:
    order = mssql_db.query(Order).filter(Order.id == order_id).one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.firebase_uid != firebase_user.uid:
        raise HTTPException(status_code=403, detail="Not allowed to cancel this order")
    if order.status not in (OrderStatus.PENDING, OrderStatus.CONFIRMED):
        raise HTTPException(
            status_code=400,
            detail=f"Order in status '{order.status.value}' cannot be cancelled",
        )
    order.status = OrderStatus.CANCELLED
    mssql_db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
