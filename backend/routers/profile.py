"""Profile and preferences endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List

from db.session import get_db
from db.models import User, UserPreference
from auth.dependencies import get_current_user

router = APIRouter(prefix="/profile", tags=["Profile"])


# Request/Response Models
class UpdatePreferencesRequest(BaseModel):
    selected_protocols: List[str]


class PreferencesResponse(BaseModel):
    selected_protocols: List[str]
    updated_at: str


class ProfileResponse(BaseModel):
    id: str
    email: str
    created_at: str
    preferences: PreferencesResponse


@router.get("", response_model=ProfileResponse)
async def get_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get current user's profile and dietary preferences.

    Requires authentication.
    """
    # Get or create user preferences
    preferences = db.query(UserPreference).filter(
        UserPreference.user_id == current_user.id
    ).first()

    if not preferences:
        # Create default preferences if not exists
        preferences = UserPreference(
            user_id=current_user.id,
            selected_protocols=[]
        )
        db.add(preferences)
        db.commit()
        db.refresh(preferences)

    return ProfileResponse(
        id=str(current_user.id),
        email=current_user.email,
        created_at=current_user.created_at.isoformat(),
        preferences=PreferencesResponse(
            selected_protocols=preferences.selected_protocols or [],
            updated_at=preferences.updated_at.isoformat()
        )
    )


@router.put("/preferences", response_model=PreferencesResponse)
async def update_preferences(
    request: UpdatePreferencesRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update user's dietary preferences.

    - **selected_protocols**: List of protocol IDs to enable

    Requires authentication. Syncs preferences across all devices.
    """
    # Validate protocol IDs (basic validation - could be more strict)
    valid_protocols = [
        "low_fodmap", "gluten_free", "dairy_free", "nut_free",
        "soy_free", "egg_free", "shellfish_free", "fish_free",
        "pork_free", "red_meat_free", "vegan", "vegetarian",
        "paleo", "keto", "low_histamine"
    ]

    for protocol in request.selected_protocols:
        if protocol not in valid_protocols:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid protocol: {protocol}"
            )

    # Get or create preferences
    preferences = db.query(UserPreference).filter(
        UserPreference.user_id == current_user.id
    ).first()

    if preferences:
        # Update existing preferences
        preferences.selected_protocols = request.selected_protocols
    else:
        # Create new preferences
        preferences = UserPreference(
            user_id=current_user.id,
            selected_protocols=request.selected_protocols
        )
        db.add(preferences)

    db.commit()
    db.refresh(preferences)

    return PreferencesResponse(
        selected_protocols=preferences.selected_protocols,
        updated_at=preferences.updated_at.isoformat()
    )
