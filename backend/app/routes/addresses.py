"""Address routes (MySQL)."""
from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session

from app.core.security import FirebaseUser, get_current_user
from app.db.mysql import get_mysql_db
from app.models.mysql.address import Address
from app.models.mysql.user import User
from app.schemas.mysql import (
    AddressCreate,
    AddressOut,
    AddressUpdate,
)
from app.services.user_service import get_user_by_firebase_uid

router = APIRouter(prefix="/addresses", tags=["Addresses"])


def _require_user(db: Session, firebase_user: FirebaseUser) -> User:
    user = get_user_by_firebase_uid(db, firebase_user.uid)
    if not user:
        raise HTTPException(
            status_code=400,
            detail="User not synced. Call /auth/sync-user first.",
        )
    return user


@router.get("", response_model=List[AddressOut])
def list_my_addresses(
    firebase_user: FirebaseUser = Depends(get_current_user),
    db: Session = Depends(get_mysql_db),
) -> List[AddressOut]:
    user = _require_user(db, firebase_user)
    items = (
        db.query(Address)
        .filter(Address.user_id == user.id)
        .order_by(Address.is_default.desc(), Address.id.desc())
        .all()
    )
    return [AddressOut.model_validate(a) for a in items]


@router.post(
    "",
    response_model=AddressOut,
    status_code=status.HTTP_201_CREATED,
)
def create_address(
    payload: AddressCreate,
    firebase_user: FirebaseUser = Depends(get_current_user),
    db: Session = Depends(get_mysql_db),
) -> AddressOut:
    user = _require_user(db, firebase_user)
    if payload.is_default:
        db.query(Address).filter(
            Address.user_id == user.id, Address.is_default.is_(True)
        ).update({Address.is_default: False})
    addr = Address(user_id=user.id, **payload.model_dump())
    db.add(addr)
    db.commit()
    db.refresh(addr)
    return AddressOut.model_validate(addr)


@router.put("/{address_id}", response_model=AddressOut)
def update_address(
    address_id: int,
    payload: AddressUpdate,
    firebase_user: FirebaseUser = Depends(get_current_user),
    db: Session = Depends(get_mysql_db),
) -> AddressOut:
    user = _require_user(db, firebase_user)
    addr = (
        db.query(Address)
        .filter(Address.id == address_id, Address.user_id == user.id)
        .one_or_none()
    )
    if not addr:
        raise HTTPException(status_code=404, detail="Address not found")
    data = payload.model_dump(exclude_unset=True)
    if data.get("is_default"):
        db.query(Address).filter(
            Address.user_id == user.id,
            Address.id != address_id,
            Address.is_default.is_(True),
        ).update({Address.is_default: False})
    for field, value in data.items():
        setattr(addr, field, value)
    db.commit()
    db.refresh(addr)
    return AddressOut.model_validate(addr)


@router.delete("/{address_id}", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
def delete_address(
    address_id: int,
    firebase_user: FirebaseUser = Depends(get_current_user),
    db: Session = Depends(get_mysql_db),
) -> Response:
    user = _require_user(db, firebase_user)
    addr = (
        db.query(Address)
        .filter(Address.id == address_id, Address.user_id == user.id)
        .one_or_none()
    )
    if not addr:
        raise HTTPException(status_code=404, detail="Address not found")
    db.delete(addr)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
