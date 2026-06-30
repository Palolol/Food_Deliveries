"""Review routes (MSSQL — migrated from MySQL)."""
from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.mssql import get_mssql_db
from app.models.mssql.restaurant import Restaurant
from app.models.mssql.review import Review
from app.models.mssql.user import User
from app.schemas.mysql import ReviewCreate, ReviewOut, ReviewUpdate

router = APIRouter(prefix="/reviews", tags=["Reviews"])


@router.get("/restaurant/{restaurant_id}", response_model=List[ReviewOut])
def list_restaurant_reviews(
    restaurant_id: int,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_mssql_db),
) -> List[ReviewOut]:
    items = (
        db.query(Review)
        .filter(Review.restaurant_id == restaurant_id)
        .order_by(Review.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return [ReviewOut.model_validate(r) for r in items]


@router.get("/restaurant/{restaurant_id}/rating")
def restaurant_rating(restaurant_id: int, db: Session = Depends(get_mssql_db)) -> dict:
    avg, count = (
        db.query(func.avg(Review.rating), func.count(Review.id))
        .filter(Review.restaurant_id == restaurant_id)
        .one()
    )
    return {
        "restaurant_id": restaurant_id,
        "average": float(avg or 0.0),
        "count": int(count or 0),
    }


@router.post("", response_model=ReviewOut, status_code=status.HTTP_201_CREATED)
def create_review(
    payload: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> ReviewOut:
    if not db.query(Restaurant).filter(Restaurant.id == payload.restaurant_id).first():
        raise HTTPException(status_code=404, detail="Restaurant not found")
    review = Review(
        user_id=current_user.id,
        restaurant_id=payload.restaurant_id,
        rating=payload.rating,
        comment=payload.comment,
    )
    db.add(review)
    db.commit()
    db.refresh(review)

    # Recompute average rating on the restaurant
    avg = (
        db.query(func.avg(Review.rating))
        .filter(Review.restaurant_id == payload.restaurant_id)
        .scalar()
        or 0.0
    )
    r = db.query(Restaurant).filter(Restaurant.id == payload.restaurant_id).one()
    r.rating = float(avg)
    db.commit()
    return ReviewOut.model_validate(review)


@router.put("/{review_id}", response_model=ReviewOut)
def update_review(
    review_id: int,
    payload: ReviewUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> ReviewOut:
    review = (
        db.query(Review)
        .filter(Review.id == review_id, Review.user_id == current_user.id)
        .one_or_none()
    )
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(review, field, value)
    db.commit()
    db.refresh(review)
    return ReviewOut.model_validate(review)


@router.delete("/{review_id}", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
def delete_review(
    review_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_mssql_db),
) -> Response:
    review = (
        db.query(Review)
        .filter(Review.id == review_id, Review.user_id == current_user.id)
        .one_or_none()
    )
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    db.delete(review)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
