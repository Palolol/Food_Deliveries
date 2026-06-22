"""Pydantic schemas shared across modules."""
from datetime import datetime
from typing import Generic, List, Optional, TypeVar

from pydantic import BaseModel, ConfigDict

T = TypeVar("T")


class ORMBase(BaseModel):
    """Base for ORM-derived response models."""

    model_config = ConfigDict(from_attributes=True, arbitrary_types_allowed=True)


class IDResponse(BaseModel):
    id: int


class MessageResponse(BaseModel):
    message: str


class PaginatedResponse(BaseModel, Generic[T]):
    """Generic paginated wrapper."""

    items: List[T]
    total: int
    page: int
    page_size: int


class HealthResponse(BaseModel):
    status: str
    environment: str
    mysql: bool
    mssql: bool
    firebase: bool
    timestamp: datetime
