"""Restaurant routes (MSSQL — migrated from MySQL)."""
from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.core.security import get_current_user, require_admin, require_restaurant_owner
from app.db.mssql import get_mssql_db
from app.models.mssql.restaurant import Restaurant
from app.models.mssql.user import User, UserRole
from app.schemas.mysql import (
    RestaurantCreate,
    RestaurantOut,
    RestaurantUpdate,
)

router = APIRouter(prefix="/restaurants", tags=["Restaurants"])


# ---------- Public (read) ----------
@router.get("", response_model=List[RestaurantOut], summary="List restaurants")
def list_restaurants(
    search: Optional[str] = Query(default=None, description="Search by name/cuisine/city"),
    city: Optional[str] = Query(default=None),
    cuisine_type: Optional[str] = Query(default=None),
    is_open: Optional[bool] = Query(default=None),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_mssql_db),
) -> List[RestaurantOut]:
    q = db.query(Restaurant).filter(Restaurant.is_active.is_(True))
    if search:
        like = f"%{search}%"
        q = q.filter(
            or_(
                Restaurant.name.ilike(like),
                Restaurant.cuisine_type.ilike(like),
                Restaurant.city.ilike(like),
            )
        )
    if city:
        q = q.filter(Restaurant.city.ilike(f"%{city}%"))
    if cuisine_type:
        q = q.filter(Restaurant.cuisine_type.ilike(f"%{cuisine_type}%"))
    if is_open is not None:
        q = q.filter(Restaurant.is_open.is_(is_open))
    q = q.order_by(Restaurant.rating.desc(), Restaurant.id.asc())
    items = q.offset(skip).limit(limit).all()
    return [RestaurantOut.model_validate(r) for r in items]


@router.get("/{restaurant_id}", response_model=RestaurantOut)
def get_restaurant(restaurant_id: int, db: Session = Depends(get_mssql_db)) -> RestaurantOut:
    r = db.query(Restaurant).filter(Restaurant.id == restaurant_id).one_or_none()
    if not r:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    return RestaurantOut.model_validate(r)


# ---------- Authenticated (write) ----------
@router.post(
    "",
    response_model=RestaurantOut,
    status_code=status.HTTP_201_CREATED,
    summary="Create a restaurant (restaurant_owner or admin)",
)
def create_restaurant(
    payload: RestaurantCreate,
    current_user: User = Depends(require_restaurant_owner),
    db: Session = Depends(get_mssql_db),
) -> RestaurantOut:
    r = Restaurant(owner_id=current_user.id, **payload.model_dump())
    db.add(r)
    db.commit()
    db.refresh(r)
    return RestaurantOut.model_validate(r)


@router.put("/{restaurant_id}", response_model=RestaurantOut)
def update_restaurant(
    restaurant_id: int,
    payload: RestaurantUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> RestaurantOut:
    r = db.query(Restaurant).filter(Restaurant.id == restaurant_id).one_or_none()
    if not r:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    if r.owner_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Not allowed to modify this restaurant")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(r, field, value)
    db.commit()
    db.refresh(r)
    return RestaurantOut.model_validate(r)


@router.delete("/{restaurant_id}", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
def delete_restaurant(
    restaurant_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> Response:
    r = db.query(Restaurant).filter(Restaurant.id == restaurant_id).one_or_none()
    if not r:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    if r.owner_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Not allowed to delete this restaurant")
    db.delete(r)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
