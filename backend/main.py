"""
IBD Menu Scanner - FastAPI Backend
Analyzes restaurant menu photos to identify trigger ingredients for IBD patients.
"""

import os
from fastapi import FastAPI, HTTPException, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from dotenv import load_dotenv
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from sqlalchemy.orm import Session

from services.vision_service import analyze_menu_image
from services.inference_service import load_protocol_triggers
from db.session import get_db
from db.models import User, ScanHistory
from auth.dependencies import get_optional_user
from routers import auth, profile, scans, bookmarks

load_dotenv()

limiter = Limiter(key_func=get_remote_address)

app = FastAPI(
    title="IBD Menu Scanner API",
    description="Analyzes restaurant menus for IBD dietary triggers",
    version="2.0.0"
)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS middleware for iOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth.router)
app.include_router(profile.router)
app.include_router(scans.router)
app.include_router(bookmarks.router)


class AnalyzeMenuRequest(BaseModel):
    """Request model for menu analysis."""
    image: str  # Base64 encoded image
    protocols: List[str]  # e.g., ["low_fodmap", "scd"]


class MenuItemResult(BaseModel):
    """Result for a single menu item."""
    name: str
    safety: str  # "safe", "caution", "avoid"
    triggers: List[str]
    notes: str


class AnalyzeMenuResponse(BaseModel):
    """Response model for menu analysis."""
    menu_items: List[MenuItemResult]


@app.get("/")
@limiter.limit("60/minute")
async def root(request: Request):
    """Health check endpoint."""
    return {"status": "healthy", "service": "IBD Menu Scanner API"}


@app.get("/protocols")
@limiter.limit("60/minute")
async def get_protocols(request: Request):
    """Get available dietary protocols."""
    return {
        "protocols": [
            {
                "id": "low_fodmap",
                "name": "Low-FODMAP",
                "description": "Avoids fermentable carbohydrates that can trigger IBS/IBD symptoms"
            },
            {
                "id": "scd",
                "name": "Specific Carbohydrate Diet (SCD)",
                "description": "Eliminates complex carbohydrates and most dairy"
            },
            {
                "id": "low_residue",
                "name": "Low-Residue Diet",
                "description": "Limits high-fiber foods to reduce bowel movements"
            }
        ]
    }


def get_rate_limit_for_user(current_user: Optional[User]) -> str:
    """Get rate limit based on authentication status."""
    if current_user:
        return "30/minute"  # Authenticated users get higher limit
    return "20/minute"  # Guest users get standard limit


@app.post("/analyze-menu", response_model=AnalyzeMenuResponse)
async def analyze_menu(
    req: Request,
    request: AnalyzeMenuRequest,
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db)
):
    """
    Analyze a menu image and identify trigger ingredients.
    Rate limited to 30 requests/min for authenticated users, 20/min for guests.

    Args:
        req: FastAPI request (for rate limit key)
        request: Contains base64 image and list of dietary protocols
        current_user: Optional authenticated user (for saving history)
        db: Database session

    Returns:
        List of menu items with safety ratings and identified triggers
    """
    # Apply dynamic rate limiting based on authentication
    rate_limit = get_rate_limit_for_user(current_user)
    limiter.limit(rate_limit)(analyze_menu)

    # Validate protocols
    valid_protocols = {"low_fodmap", "scd", "low_residue"}
    for protocol in request.protocols:
        if protocol not in valid_protocols:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid protocol: {protocol}. Valid options: {valid_protocols}"
            )

    if not request.protocols:
        raise HTTPException(
            status_code=400,
            detail="At least one protocol must be specified"
        )

    # Load trigger data for selected protocols
    triggers = load_protocol_triggers(request.protocols)

    # Analyze the menu image
    try:
        menu_items = await analyze_menu_image(request.image, request.protocols, triggers)

        # Save to scan history if user is authenticated
        if current_user:
            scan_record = ScanHistory(
                user_id=current_user.id,
                protocols_used=request.protocols,
                menu_items=[item.dict() for item in menu_items],
                restaurant_name=None  # Could be extracted from image or added to request
            )
            db.add(scan_record)
            db.commit()

        return AnalyzeMenuResponse(menu_items=menu_items)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error analyzing menu: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
