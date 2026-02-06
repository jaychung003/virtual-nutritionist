"""Bookmark endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional

from db.session import get_db
from db.models import User, Bookmark
from auth.dependencies import get_current_user

router = APIRouter(prefix="/bookmarks", tags=["Bookmarks"])


# Request/Response Models
class CreateBookmarkRequest(BaseModel):
    menu_item_name: str
    safety_rating: str
    triggers: List[str]
    notes: Optional[str] = None
    restaurant_name: Optional[str] = None


class BookmarkResponse(BaseModel):
    id: str
    menu_item_name: str
    safety_rating: str
    triggers: List[str]
    notes: Optional[str]
    restaurant_name: Optional[str]
    created_at: str


class BookmarkListResponse(BaseModel):
    bookmarks: List[BookmarkResponse]
    total: int


@router.post("", response_model=BookmarkResponse, status_code=status.HTTP_201_CREATED)
async def create_bookmark(
    request: CreateBookmarkRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Add a menu item to bookmarks.

    - **menu_item_name**: Name of the menu item
    - **safety_rating**: "safe", "caution", or "avoid"
    - **triggers**: List of dietary triggers found
    - **notes**: Optional personal notes
    - **restaurant_name**: Optional restaurant name

    Requires authentication.
    """
    # Validate safety rating
    valid_ratings = ["safe", "caution", "avoid"]
    if request.safety_rating not in valid_ratings:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid safety_rating. Must be one of: {', '.join(valid_ratings)}"
        )

    # Create bookmark
    bookmark = Bookmark(
        user_id=current_user.id,
        menu_item_name=request.menu_item_name,
        safety_rating=request.safety_rating,
        triggers=request.triggers,
        notes=request.notes,
        restaurant_name=request.restaurant_name
    )
    db.add(bookmark)
    db.commit()
    db.refresh(bookmark)

    return BookmarkResponse(
        id=str(bookmark.id),
        menu_item_name=bookmark.menu_item_name,
        safety_rating=bookmark.safety_rating,
        triggers=bookmark.triggers,
        notes=bookmark.notes,
        restaurant_name=bookmark.restaurant_name,
        created_at=bookmark.created_at.isoformat()
    )


@router.get("", response_model=BookmarkListResponse)
async def list_bookmarks(
    safety_rating: Optional[str] = Query(None, description="Filter by safety rating"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    List user's bookmarked menu items.

    Optional filter by safety_rating.
    Requires authentication.
    """
    # Build query
    query = db.query(Bookmark).filter(Bookmark.user_id == current_user.id)

    # Apply safety rating filter if provided
    if safety_rating:
        valid_ratings = ["safe", "caution", "avoid"]
        if safety_rating not in valid_ratings:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid safety_rating. Must be one of: {', '.join(valid_ratings)}"
            )
        query = query.filter(Bookmark.safety_rating == safety_rating)

    # Order by most recent first
    bookmarks = query.order_by(Bookmark.created_at.desc()).all()

    # Format response
    bookmark_items = []
    for bookmark in bookmarks:
        bookmark_items.append(BookmarkResponse(
            id=str(bookmark.id),
            menu_item_name=bookmark.menu_item_name,
            safety_rating=bookmark.safety_rating,
            triggers=bookmark.triggers,
            notes=bookmark.notes,
            restaurant_name=bookmark.restaurant_name,
            created_at=bookmark.created_at.isoformat()
        ))

    return BookmarkListResponse(
        bookmarks=bookmark_items,
        total=len(bookmark_items)
    )


@router.delete("/{bookmark_id}")
async def delete_bookmark(
    bookmark_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Delete a bookmark.

    Requires authentication and ownership of the bookmark.
    """
    # Find bookmark and verify ownership
    bookmark = db.query(Bookmark).filter(
        Bookmark.id == bookmark_id,
        Bookmark.user_id == current_user.id
    ).first()

    if not bookmark:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Bookmark not found"
        )

    db.delete(bookmark)
    db.commit()

    return {"message": "Bookmark deleted successfully"}
