"""Menu routes (MySQL)."""
from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import Session

from app.core.security import FirebaseUser, get_current_user
from app.db.mysql import get_mysql_db
from app.models.mysql.menu import MenuItem
from app.models.mysql.restaurant import Restaurant
from app.models.mysql.user import User
from app.schemas.mysql import (
    MenuItemCreate,
    MenuItemOut,
    MenuItemUpdate,
)
from app.services.user_service import get_user_by_firebase_uid

router = APIRouter(prefix="/menu", tags=["Menu"])


def _require_owner(db: Session, user: User, restaurant_id: int) -> Restaurant:
    r = db.query(Restaurant).filter(Restaurant.id == restaurant_id).one_or_none()
    if not r:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    if r.owner_id != user.id and not user.is_admin:
        raise HTTPException(status_code=403, detail="Not allowed for this restaurant")
    return r


@router.get("/restaurant/{restaurant_id}", response_model=List[MenuItemOut])
def list_menu_items(
    restaurant_id: int,
    category: Optional[str] = Query(default=None),
    available_only: bool = Query(default=True),
    db: Session = Depends(get_mysql_db),
) -> List[MenuItemOut]:
    q = db.query(MenuItem).filter(MenuItem.restaurant_id == restaurant_id)
    if category:
        q = q.filter(MenuItem.category.ilike(f"%{category}%"))
    if available_only:
        q = q.filter(MenuItem.is_available.is_(True))
    items = q.order_by(MenuItem.category, MenuItem.name).all()
    return [MenuItemOut.model_validate(i) for i in items]


@router.get("/{menu_item_id}", response_model=MenuItemOut)
def get_menu_item(menu_item_id: int, db: Session = Depends(get_mysql_db)) -> MenuItemOut:
    item = db.query(MenuItem).filter(MenuItem.id == menu_item_id).one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found")
    return MenuItemOut.model_validate(item)


@router.post(
    "",
    response_model=MenuItemOut,
    status_code=status.HTTP_201_CREATED,
)
def create_menu_item(
    payload: MenuItemCreate,
    firebase_user: FirebaseUser = Depends(get_current_user),
    db: Session = Depends(get_mysql_db),
) -> MenuItemOut:
    user = get_user_by_firebase_uid(db, firebase_user.uid)
    if not user:
        raise HTTPException(status_code=400, detail="User not synced")
    _require_owner(db, user, payload.restaurant_id)
    item = MenuItem(**payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return MenuItemOut.model_validate(item)


@router.put("/{menu_item_id}", response_model=MenuItemOut)
def update_menu_item(
    menu_item_id: int,
    payload: MenuItemUpdate,
    firebase_user: FirebaseUser = Depends(get_current_user),
    db: Session = Depends(get_mysql_db),
) -> MenuItemOut:
    user = get_user_by_firebase_uid(db, firebase_user.uid)
    if not user:
        raise HTTPException(status_code=400, detail="User not synced")
    item = db.query(MenuItem).filter(MenuItem.id == menu_item_id).one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found")
    _require_owner(db, user, item.restaurant_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    db.commit()
    db.refresh(item)
    return MenuItemOut.model_validate(item)


@router.delete("/{menu_item_id}", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
def delete_menu_item(
    menu_item_id: int,
    firebase_user: FirebaseUser = Depends(get_current_user),
    db: Session = Depends(get_mysql_db),
) -> Response:
    user = get_user_by_firebase_uid(db, firebase_user.uid)
    if not user:
        raise HTTPException(status_code=400, detail="User not synced")
    item = db.query(MenuItem).filter(MenuItem.id == menu_item_id).one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found")
    _require_owner(db, user, item.restaurant_id)
    db.delete(item)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
