"""Address routes (MSSQL — migrated from MySQL)."""
from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.mssql import get_mssql_db
from app.models.mssql.address import Address
from app.models.mssql.user import User
from app.schemas.mysql import AddressCreate, AddressOut, AddressUpdate

router = APIRouter(prefix="/addresses", tags=["Addresses"])


@router.get("", response_model=List[AddressOut])
def list_my_addresses(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> List[AddressOut]:
    items = (
        db.query(Address)
        .filter(Address.user_id == current_user.id)
        .order_by(Address.is_default.desc(), Address.id.desc())
        .all()
    )
    return [AddressOut.model_validate(a) for a in items]


@router.post("", response_model=AddressOut, status_code=status.HTTP_201_CREATED)
def create_address(
    payload: AddressCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> AddressOut:
    if payload.is_default:
        db.query(Address).filter(
            Address.user_id == current_user.id, Address.is_default.is_(True)
        ).update({Address.is_default: False})
    addr = Address(user_id=current_user.id, **payload.model_dump())
    db.add(addr)
    db.commit()
    db.refresh(addr)
    return AddressOut.model_validate(addr)


@router.put("/{address_id}", response_model=AddressOut)
def update_address(
    address_id: int,
    payload: AddressUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> AddressOut:
    addr = (
        db.query(Address)
        .filter(Address.id == address_id, Address.user_id == current_user.id)
        .one_or_none()
    )
    if not addr:
        raise HTTPException(status_code=404, detail="Address not found")
    data = payload.model_dump(exclude_unset=True)
    if data.get("is_default"):
        db.query(Address).filter(
            Address.user_id == current_user.id,
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
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> Response:
    addr = (
        db.query(Address)
        .filter(Address.id == address_id, Address.user_id == current_user.id)
        .one_or_none()
    )
    if not addr:
        raise HTTPException(status_code=404, detail="Address not found")
    db.delete(addr)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
