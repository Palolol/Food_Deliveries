"""Schemas for orders and payments (MSSQL)."""
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field

from app.models.mssql.order import OrderStatus
from app.models.mssql.payment import PaymentMethod, PaymentStatus
from app.schemas.common import ORMBase


# ---------- Order creation (from Flutter) ----------
class OrderItemCreate(BaseModel):
    menu_item_id: int
    quantity: int = Field(..., ge=1, le=100)
    special_instructions: Optional[str] = Field(default=None, max_length=500)


class OrderCreate(BaseModel):
    restaurant_id: int
    items: List[OrderItemCreate] = Field(..., min_length=1)
    delivery_address: str = Field(..., min_length=1, max_length=500)
    delivery_city: Optional[str] = Field(default=None, max_length=100)
    delivery_postal_code: Optional[str] = Field(default=None, max_length=20)
    delivery_phone: Optional[str] = Field(default=None, max_length=32)
    notes: Optional[str] = Field(default=None, max_length=1000)
    payment_method: PaymentMethod = PaymentMethod.ONLINE
    delivery_fee: float = Field(default=2.99, ge=0)
    tax_rate: float = Field(default=0.08, ge=0, le=1)  # 8% default
    discount: float = Field(default=0.0, ge=0)


class OrderItemOut(ORMBase):
    id: int
    menu_item_id: int
    name: str
    unit_price: float
    quantity: int
    line_total: float
    special_instructions: Optional[str] = None


class OrderOut(ORMBase):
    id: int
    user_id: int
    user_email: Optional[str] = None
    restaurant_id: Optional[int] = None
    restaurant_name: Optional[str] = None
    delivery_address: str
    delivery_city: Optional[str] = None
    delivery_postal_code: Optional[str] = None
    delivery_phone: Optional[str] = None
    subtotal: float
    delivery_fee: float
    tax: float
    discount: float
    total: float
    status: OrderStatus
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    items: List[OrderItemOut] = []


class OrderStatusUpdate(BaseModel):
    status: OrderStatus
    notes: Optional[str] = Field(default=None, max_length=500)


# ---------- Payment ----------
class PaymentCreate(BaseModel):
    order_id: int
    method: PaymentMethod
    amount: float = Field(..., ge=0)
    currency: str = Field(default="USD", max_length=10)
    transaction_id: Optional[str] = Field(default=None, max_length=128)
    gateway: Optional[str] = Field(default=None, max_length=50)
    gateway_response: Optional[str] = Field(default=None, max_length=2000)


class PaymentUpdate(BaseModel):
    status: PaymentStatus
    transaction_id: Optional[str] = Field(default=None, max_length=128)
    failure_reason: Optional[str] = Field(default=None, max_length=500)
    gateway_response: Optional[str] = Field(default=None, max_length=2000)


class PaymentOut(ORMBase):
    id: int
    order_id: int
    user_id: int
    amount: float
    currency: str
    method: PaymentMethod
    status: PaymentStatus
    transaction_id: Optional[str] = None
    gateway: Optional[str] = None
    failure_reason: Optional[str] = None
    paid_at: Optional[datetime] = None
    refunded_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
