"""Schemas for the MySQL module (users, restaurants, menus, reviews, addresses)."""
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.common import ORMBase


# ---------- User update ----------
class UserUpdate(BaseModel):
    full_name: Optional[str] = Field(default=None, max_length=255)
    phone: Optional[str] = Field(default=None, max_length=32)
    avatar_url: Optional[str] = Field(default=None, max_length=512)


# ---------- Restaurant ----------
class RestaurantBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    cuisine_type: Optional[str] = Field(default=None, max_length=100)
    address: Optional[str] = Field(default=None, max_length=500)
    city: Optional[str] = Field(default=None, max_length=100)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    image_url: Optional[str] = Field(default=None, max_length=512)
    phone: Optional[str] = Field(default=None, max_length=32)
    is_active: bool = True
    is_open: bool = True
    opening_time: Optional[str] = Field(default=None, max_length=10)
    closing_time: Optional[str] = Field(default=None, max_length=10)


class RestaurantCreate(RestaurantBase):
    pass


class RestaurantUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=255)
    description: Optional[str] = None
    cuisine_type: Optional[str] = Field(default=None, max_length=100)
    address: Optional[str] = Field(default=None, max_length=500)
    city: Optional[str] = Field(default=None, max_length=100)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    image_url: Optional[str] = Field(default=None, max_length=512)
    phone: Optional[str] = Field(default=None, max_length=32)
    is_active: Optional[bool] = None
    is_open: Optional[bool] = None
    opening_time: Optional[str] = Field(default=None, max_length=10)
    closing_time: Optional[str] = Field(default=None, max_length=10)


class RestaurantOut(RestaurantBase, ORMBase):
    id: int
    owner_id: int
    rating: float
    created_at: datetime
    updated_at: datetime


# ---------- Menu Item ----------
class MenuItemBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    category: Optional[str] = Field(default=None, max_length=100)
    price: float = Field(..., ge=0)
    discount_price: Optional[float] = Field(default=None, ge=0)
    image_url: Optional[str] = Field(default=None, max_length=512)
    is_available: bool = True
    is_vegetarian: bool = False
    is_vegan: bool = False
    is_gluten_free: bool = False
    preparation_time_minutes: Optional[int] = Field(default=None, ge=0)
    calories: Optional[int] = Field(default=None, ge=0)


class MenuItemCreate(MenuItemBase):
    restaurant_id: int


class MenuItemUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=255)
    description: Optional[str] = None
    category: Optional[str] = Field(default=None, max_length=100)
    price: Optional[float] = Field(default=None, ge=0)
    discount_price: Optional[float] = Field(default=None, ge=0)
    image_url: Optional[str] = Field(default=None, max_length=512)
    is_available: Optional[bool] = None
    is_vegetarian: Optional[bool] = None
    is_vegan: Optional[bool] = None
    is_gluten_free: Optional[bool] = None
    preparation_time_minutes: Optional[int] = Field(default=None, ge=0)
    calories: Optional[int] = Field(default=None, ge=0)


class MenuItemOut(MenuItemBase, ORMBase):
    id: int
    restaurant_id: int
    created_at: datetime
    updated_at: datetime


# ---------- Review ----------
class ReviewBase(BaseModel):
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None


class ReviewCreate(ReviewBase):
    restaurant_id: int


class ReviewUpdate(BaseModel):
    rating: Optional[int] = Field(default=None, ge=1, le=5)
    comment: Optional[str] = None


class ReviewOut(ReviewBase, ORMBase):
    id: int
    user_id: int
    restaurant_id: int
    created_at: datetime
    updated_at: datetime


# ---------- Address ----------
class AddressBase(BaseModel):
    label: Optional[str] = Field(default=None, max_length=50)
    street: str = Field(..., min_length=1, max_length=255)
    city: str = Field(..., min_length=1, max_length=100)
    state: Optional[str] = Field(default=None, max_length=100)
    postal_code: Optional[str] = Field(default=None, max_length=20)
    country: str = Field(default="USA", max_length=100)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_default: bool = False


class AddressCreate(AddressBase):
    pass


class AddressUpdate(BaseModel):
    label: Optional[str] = Field(default=None, max_length=50)
    street: Optional[str] = Field(default=None, min_length=1, max_length=255)
    city: Optional[str] = Field(default=None, min_length=1, max_length=100)
    state: Optional[str] = Field(default=None, max_length=100)
    postal_code: Optional[str] = Field(default=None, max_length=20)
    country: Optional[str] = Field(default=None, max_length=100)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_default: Optional[bool] = None


class AddressOut(AddressBase, ORMBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime
