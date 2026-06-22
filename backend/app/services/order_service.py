"""Order-creation business logic.

Spans MySQL (menu lookup) and MSSQL (orders + payments).
This is the canonical end-to-end flow described in the project spec:

    1. Verify Firebase token (done by the dependency in the route)
    2. Get Firebase UID
    3. Fetch menu from MySQL
    4. Create order in MSSQL
    5. Create payment record in MSSQL
    6. Return response to Flutter
"""
from __future__ import annotations

from typing import List

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.mssql.order import Order, OrderItem, OrderStatus
from app.models.mssql.payment import Payment, PaymentMethod, PaymentStatus
from app.models.mysql.menu import MenuItem
from app.models.mysql.restaurant import Restaurant
from app.schemas.mssql import OrderCreate
from app.utils.helpers import generate_transaction_id


def _calculate_totals(
    items: List[OrderItem], delivery_fee: float, tax_rate: float, discount: float
) -> tuple[float, float, float, float]:
    subtotal = sum(item.line_total for item in items)
    tax = round(subtotal * tax_rate, 2)
    total = max(0.0, round(subtotal + tax + delivery_fee - discount, 2))
    return subtotal, tax, total, discount


def create_order_with_payment(
    *,
    mssql_db: Session,
    mysql_db: Session,
    firebase_uid: str,
    user_email: str | None,
    payload: OrderCreate,
) -> tuple[Order, Payment]:
    """
    Create an order and its initial payment record.

    The MSSQL transaction is committed atomically: if anything fails,
    the order AND payment are rolled back together.
    """
    # ---- 1. Verify restaurant exists (MySQL) ----
    restaurant: Restaurant | None = (
        mysql_db.query(Restaurant)
        .filter(Restaurant.id == payload.restaurant_id)
        .one_or_none()
    )
    if not restaurant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Restaurant {payload.restaurant_id} not found",
        )
    if not restaurant.is_active or not restaurant.is_open:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Restaurant is currently closed",
        )

    # ---- 2. Resolve and price each menu item (MySQL) ----
    menu_ids = [i.menu_item_id for i in payload.items]
    menu_items: list[MenuItem] = (
        mysql_db.query(MenuItem).filter(MenuItem.id.in_(menu_ids)).all()
    )
    menu_by_id = {m.id: m for m in menu_items}

    if len(menu_by_id) != len(set(menu_ids)):
        missing = set(menu_ids) - set(menu_by_id.keys())
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Menu items not found: {sorted(missing)}",
        )

    for m in menu_items:
        if m.restaurant_id != restaurant.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Menu item {m.id} does not belong to restaurant {restaurant.id}",
            )
        if not m.is_available:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Menu item '{m.name}' is currently unavailable",
            )

    # Build order items snapshot
    order_items: list[OrderItem] = []
    for spec in payload.items:
        menu = menu_by_id[spec.menu_item_id]
        unit_price = menu.discount_price if menu.discount_price else menu.price
        line_total = round(unit_price * spec.quantity, 2)
        order_items.append(
            OrderItem(
                menu_item_id=menu.id,
                name=menu.name,
                unit_price=unit_price,
                quantity=spec.quantity,
                line_total=line_total,
                special_instructions=spec.special_instructions,
            )
        )

    # ---- 3. Create the order (MSSQL) ----
    order = Order(
        firebase_uid=firebase_uid,
        user_email=user_email,
        restaurant_id=restaurant.id,
        restaurant_name=restaurant.name,
        delivery_address=payload.delivery_address,
        delivery_city=payload.delivery_city,
        delivery_postal_code=payload.delivery_postal_code,
        delivery_phone=payload.delivery_phone,
        notes=payload.notes,
        status=OrderStatus.PENDING,
        delivery_fee=payload.delivery_fee,
        discount=payload.discount,
        tax=0.0,
        subtotal=0.0,
        total=0.0,
        items=order_items,
    )

    subtotal, tax, total, _ = _calculate_totals(
        order_items, payload.delivery_fee, payload.tax_rate, payload.discount
    )
    order.subtotal = subtotal
    order.tax = tax
    order.total = total

    # ---- 4. Initial payment record (MSSQL) ----
    initial_payment_status = (
        PaymentStatus.PAID
        if payload.payment_method == PaymentMethod.CASH
        else PaymentStatus.PENDING
    )
    payment = Payment(
        order=order,
        firebase_uid=firebase_uid,
        amount=total,
        currency="USD",
        method=payload.payment_method,
        status=initial_payment_status,
        transaction_id=generate_transaction_id() if initial_payment_status == PaymentStatus.PAID else None,
    )

    try:
        mssql_db.add(order)
        mssql_db.add(payment)
        mssql_db.commit()
    except Exception as exc:  # noqa: BLE001
        mssql_db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create order: {exc}",
        ) from exc

    mssql_db.refresh(order)
    mssql_db.refresh(payment)
    return order, payment
