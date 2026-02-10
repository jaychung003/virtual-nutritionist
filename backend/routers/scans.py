"""Scan history endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

from db.session import get_db
from db.models import User, ScanHistory
from auth.dependencies import get_current_user

router = APIRouter(prefix="/scans", tags=["Scan History"])


# Response Models
class ScanItem(BaseModel):
    id: str
    protocols_used: List[str]
    restaurant_name: Optional[str]
    item_count: int
    scanned_at: str


class ScanListResponse(BaseModel):
    scans: List[ScanItem]
    total: int
    page: int
    page_size: int


class ScanDetailResponse(BaseModel):
    id: str
    protocols_used: List[str]
    menu_items: List[dict]  # Full menu items with analysis
    restaurant_name: Optional[str]
    image_data: Optional[str]  # Base64 encoded image
    scanned_at: str


@router.get("", response_model=ScanListResponse)
async def list_scans(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    List user's scan history.

    Returns paginated list of scans, most recent first.
    Requires authentication.
    """
    # Get total count
    total = db.query(ScanHistory).filter(
        ScanHistory.user_id == current_user.id
    ).count()

    # Get paginated scans
    scans = db.query(ScanHistory).filter(
        ScanHistory.user_id == current_user.id
    ).order_by(
        ScanHistory.scanned_at.desc()
    ).offset(
        (page - 1) * page_size
    ).limit(
        page_size
    ).all()

    # Format response
    scan_items = []
    for scan in scans:
        scan_items.append(ScanItem(
            id=str(scan.id),
            protocols_used=scan.protocols_used,
            restaurant_name=scan.restaurant_name,
            item_count=len(scan.menu_items) if scan.menu_items else 0,
            scanned_at=scan.scanned_at.isoformat()
        ))

    return ScanListResponse(
        scans=scan_items,
        total=total,
        page=page,
        page_size=page_size
    )


@router.get("/{scan_id}", response_model=ScanDetailResponse)
async def get_scan(
    scan_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get details of a specific scan.

    Requires authentication and ownership of the scan.
    """
    # Find scan and verify ownership
    scan = db.query(ScanHistory).filter(
        ScanHistory.id == scan_id,
        ScanHistory.user_id == current_user.id
    ).first()

    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan not found"
        )

    return ScanDetailResponse(
        id=str(scan.id),
        protocols_used=scan.protocols_used,
        menu_items=scan.menu_items or [],
        restaurant_name=scan.restaurant_name,
        image_data=scan.image_data,
        scanned_at=scan.scanned_at.isoformat()
    )


@router.delete("/{scan_id}")
async def delete_scan(
    scan_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Delete a scan from history.

    Requires authentication and ownership of the scan.
    """
    # Find scan and verify ownership
    scan = db.query(ScanHistory).filter(
        ScanHistory.id == scan_id,
        ScanHistory.user_id == current_user.id
    ).first()

    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan not found"
        )

    db.delete(scan)
    db.commit()

    return {"message": "Scan deleted successfully"}
