"""
Restaurant discovery endpoints using Google Places API.
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

from db.session import get_db
from db.models import Restaurant, RestaurantMenuItem
from services.google_places_service import (
    GooglePlacesService,
    calculate_distance,
    get_cuisine_type
)
from services.vision_service import analyze_menu_image
from services.inference_service import load_protocol_triggers

router = APIRouter(prefix="/restaurants", tags=["Restaurants"])


# Request/Response Models
class RestaurantSearchResult(BaseModel):
    place_id: str
    name: str
    address: Optional[str]
    latitude: float
    longitude: float
    rating: Optional[float]
    user_ratings_total: Optional[int]
    price_level: Optional[int]  # 0-4 scale
    cuisine_type: Optional[str]
    photos_available: bool
    has_menu_data: bool  # Whether we've analyzed this restaurant


class RestaurantNearbyResult(BaseModel):
    place_id: str
    name: str
    vicinity: str
    distance_meters: int
    latitude: float
    longitude: float
    rating: Optional[float]
    price_level: Optional[int]
    cuisine_type: Optional[str]
    photos_available: bool
    is_open: Optional[bool]
    has_menu_data: bool
    safe_items_count: Optional[int] = 0
    last_analyzed: Optional[datetime]


class RestaurantDetailResponse(BaseModel):
    place_id: str
    name: str
    address: str
    latitude: float
    longitude: float
    rating: Optional[float]
    user_ratings_total: Optional[int]
    price_level: Optional[int]
    cuisine_type: Optional[str]
    website: Optional[str]
    phone: Optional[str]
    photos: List[dict]
    has_menu_data: bool
    menu_item_count: Optional[int]
    last_analyzed: Optional[datetime]


@router.get("/search", response_model=List[RestaurantSearchResult])
async def search_restaurants(
    query: str,
    location: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    Search for restaurants by name.

    - **query**: Restaurant name to search for
    - **location**: Optional location (city, address, etc.)

    Returns list of matching restaurants with analysis status.
    """
    # Search Google Places
    result = GooglePlacesService.text_search(query, location)

    if not result:
        return []

    # Check if we have menu data for this restaurant
    our_restaurant = db.query(Restaurant).filter(
        Restaurant.google_place_id == result["place_id"]
    ).first()

    return [{
        "place_id": result["place_id"],
        "name": result["name"],
        "address": result.get("address"),
        "latitude": result["latitude"],
        "longitude": result["longitude"],
        "rating": result.get("rating"),
        "user_ratings_total": result.get("user_ratings_total"),
        "price_level": result.get("price_level"),
        "cuisine_type": get_cuisine_type(result.get("types", [])),
        "photos_available": result.get("photos_available", False),
        "has_menu_data": our_restaurant is not None
    }]


@router.get("/nearby", response_model=List[RestaurantNearbyResult])
async def get_nearby_restaurants(
    latitude: float,
    longitude: float,
    radius_meters: int = Query(default=5000, le=50000),
    cuisine_type: Optional[str] = None,
    protocols: List[str] = Query(default=[]),
    db: Session = Depends(get_db)
):
    """
    Find restaurants near a location.

    - **latitude**: Latitude coordinate
    - **longitude**: Longitude coordinate
    - **radius_meters**: Search radius in meters (max 50000)
    - **cuisine_type**: Optional cuisine filter
    - **protocols**: Dietary protocols to check (for safety counts)

    Returns nearby restaurants with analysis status and safety info.
    """
    # Get restaurants from Google Places
    google_restaurants = GooglePlacesService.nearby_search(
        latitude, longitude, radius_meters, cuisine_type
    )

    if not google_restaurants:
        return []

    # Get place IDs
    place_ids = [r["place_id"] for r in google_restaurants]

    # Check which ones we have in our database
    our_restaurants = db.query(Restaurant).filter(
        Restaurant.google_place_id.in_(place_ids)
    ).all()

    # Create lookup map
    our_restaurants_map = {r.google_place_id: r for r in our_restaurants}

    # Combine Google data with our data
    results = []
    for g_rest in google_restaurants:
        place_id = g_rest["place_id"]

        # Calculate distance
        distance = int(calculate_distance(
            latitude, longitude,
            g_rest["latitude"], g_rest["longitude"]
        ))

        # Check if we have menu data
        our_rest = our_restaurants_map.get(place_id)
        has_menu_data = our_rest is not None
        safe_count = 0
        last_analyzed = None

        if our_rest and protocols:
            # Count safe items for user's protocols
            # TODO: Implement this query when we have menu item analysis
            safe_count = 0
            last_analyzed = our_rest.menu_last_scanned

        results.append({
            "place_id": place_id,
            "name": g_rest["name"],
            "vicinity": g_rest.get("vicinity", ""),
            "distance_meters": distance,
            "latitude": g_rest["latitude"],
            "longitude": g_rest["longitude"],
            "rating": g_rest.get("rating"),
            "price_level": g_rest.get("price_level"),
            "cuisine_type": get_cuisine_type(g_rest.get("types", [])),
            "photos_available": g_rest.get("photos_available", False),
            "is_open": g_rest.get("is_open"),
            "has_menu_data": has_menu_data,
            "safe_items_count": safe_count,
            "last_analyzed": last_analyzed
        })

    # Sort by distance
    results.sort(key=lambda x: x["distance_meters"])

    return results


@router.get("/{place_id}/details", response_model=RestaurantDetailResponse)
async def get_restaurant_details(
    place_id: str,
    db: Session = Depends(get_db)
):
    """
    Get detailed information about a restaurant.

    - **place_id**: Google Place ID

    Returns restaurant details including photos and menu status.
    """
    # Get details from Google Places
    details = GooglePlacesService.get_place_details(place_id)

    if not details:
        raise HTTPException(
            status_code=404,
            detail="Restaurant not found"
        )

    # Check our database
    our_restaurant = db.query(Restaurant).filter(
        Restaurant.google_place_id == place_id
    ).first()

    has_menu_data = our_restaurant is not None
    menu_item_count = 0
    last_analyzed = None

    if our_restaurant:
        menu_item_count = db.query(RestaurantMenuItem).filter(
            RestaurantMenuItem.restaurant_id == our_restaurant.id
        ).count()
        last_analyzed = our_restaurant.menu_last_scanned

    return {
        "place_id": details["place_id"],
        "name": details["name"],
        "address": details.get("address", ""),
        "latitude": details["latitude"],
        "longitude": details["longitude"],
        "rating": details.get("rating"),
        "user_ratings_total": details.get("user_ratings_total"),
        "price_level": details.get("price_level"),
        "cuisine_type": get_cuisine_type(details.get("types", [])),
        "website": details.get("website"),
        "phone": details.get("phone"),
        "photos": details.get("photos", []),
        "has_menu_data": has_menu_data,
        "menu_item_count": menu_item_count,
        "last_analyzed": last_analyzed
    }


@router.get("/{place_id}/photos/{photo_reference}")
async def get_restaurant_photo(
    place_id: str,
    photo_reference: str,
    max_width: int = Query(default=800, le=1600)
):
    """
    Get URL to download a restaurant photo.

    - **place_id**: Google Place ID (for reference)
    - **photo_reference**: Photo reference from details endpoint
    - **max_width**: Maximum width in pixels (max 1600)

    Returns photo URL.
    """
    url = GooglePlacesService.get_photo_url(photo_reference, max_width)

    return {
        "photo_url": url,
        "max_width": max_width
    }


class AnalyzeMenuRequest(BaseModel):
    image: str  # base64 encoded image
    protocols: List[str]


@router.get("/{place_id}/menu")
async def get_restaurant_menu(
    place_id: str,
    protocols: List[str] = Query(default=[], description="Filter by dietary protocols"),
    db: Session = Depends(get_db)
):
    """
    Get cached menu analysis for a restaurant.

    Returns the most recent community-contributed menu analysis.
    This allows users to see what menu items are safe BEFORE visiting the restaurant.

    - **place_id**: Google Place ID
    - **protocols**: Optional filter by protocols (returns all items if empty)

    Returns cached menu analysis or 404 if no analysis exists.
    """
    from datetime import datetime as dt

    # Check if we have menu data for this restaurant
    restaurant = db.query(Restaurant).filter(
        Restaurant.google_place_id == place_id
    ).first()

    if not restaurant or not restaurant.menu_last_scanned:
        raise HTTPException(
            status_code=404,
            detail="No menu analysis available for this restaurant. Be the first to scan!"
        )

    # Get active menu items
    menu_items = db.query(RestaurantMenuItem).filter(
        RestaurantMenuItem.restaurant_id == restaurant.id,
        RestaurantMenuItem.is_active == True
    ).all()

    # Calculate freshness
    days_since_scan = (dt.utcnow() - restaurant.menu_last_scanned.replace(tzinfo=None)).days

    if days_since_scan < 7:
        freshness = "fresh"
    elif days_since_scan < 30:
        freshness = "recent"
    else:
        freshness = "stale"

    return {
        "restaurant": {
            "place_id": place_id,
            "name": restaurant.name,
            "address": restaurant.address,
            "cuisine_type": restaurant.cuisine_type
        },
        "menu_items": [
            {
                "name": item.name,
                "description": item.description,
                "price": item.price,
                "category": item.category
            }
            for item in menu_items
        ],
        "metadata": {
            "last_analyzed": restaurant.menu_last_scanned,
            "days_since_scan": days_since_scan,
            "freshness": freshness,
            "total_scans": int(restaurant.total_scans or "1"),
            "item_count": len(menu_items)
        },
        "message": f"Menu analyzed {days_since_scan} days ago by the community. {'Fresh data!' if freshness == 'fresh' else 'Consider re-scanning if menu has changed.' if freshness == 'stale' else 'Fairly recent data.'}"
    }


@router.post("/{place_id}/analyze")
async def analyze_restaurant_menu(
    place_id: str,
    request: AnalyzeMenuRequest,
    db: Session = Depends(get_db)
):
    """
    Analyze restaurant menu from user-uploaded photo.

    This is a community-contributed endpoint where users upload menu photos
    they took at restaurants. The analysis is saved to help future users.

    This endpoint:
    1. Accepts a user-uploaded menu photo
    2. Analyzes menu items for dietary triggers
    3. Saves results to database (shared with all users)
    4. Returns analysis

    - **place_id**: Google Place ID
    - **image**: Base64 encoded menu photo
    - **protocols**: List of dietary protocols (e.g., ["gluten_free", "vegan"])

    Returns menu analysis with safe/caution/avoid ratings.
    """
    from datetime import datetime as dt
    import uuid

    # Validate protocols
    valid_protocols = {
        "low_fodmap", "scd", "low_residue", "gluten_free", "dairy_free",
        "nut_free", "peanut_free", "soy_free", "egg_free", "shellfish_free",
        "fish_free", "pork_free", "red_meat_free", "vegan", "vegetarian",
        "paleo", "keto", "low_histamine"
    }

    for protocol in request.protocols:
        if protocol not in valid_protocols:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid protocol: {protocol}. Valid options: {sorted(valid_protocols)}"
            )

    # Get restaurant details from Google (for name, address, etc.)
    details = GooglePlacesService.get_place_details(place_id)
    if not details:
        raise HTTPException(status_code=404, detail="Restaurant not found on Google Places")

    # Validate image is provided
    if not request.image:
        raise HTTPException(
            status_code=400,
            detail="Menu image is required"
        )

    # Load protocol triggers
    triggers = load_protocol_triggers(request.protocols)

    # Analyze the user-provided menu photo
    menu_items = await analyze_menu_image(request.image, request.protocols, triggers)

    # Save to database (community-contributed)
    existing = db.query(Restaurant).filter(
        Restaurant.google_place_id == place_id
    ).first()

    if not existing:
        # Create new restaurant
        restaurant = Restaurant(
            id=uuid.uuid4(),
            google_place_id=place_id,
            name=details["name"],
            address=details.get("address"),
            latitude=str(details.get("latitude", "")),
            longitude=str(details.get("longitude", "")),
            cuisine_type=get_cuisine_type(details.get("types", [])),
            price_level="$" * details.get("price_level", 0) if details.get("price_level") else None,
            phone=details.get("phone"),
            website=details.get("website"),
            menu_last_scanned=dt.utcnow(),
            total_scans="1"
        )
        db.add(restaurant)
    else:
        # Update existing - new contribution
        restaurant = existing
        restaurant.name = details["name"]  # Update in case name changed
        restaurant.address = details.get("address")
        restaurant.menu_last_scanned = dt.utcnow()
        restaurant.total_scans = str(int(restaurant.total_scans or "0") + 1)

        # Deactivate old menu items (replace with new scan)
        db.query(RestaurantMenuItem).filter(
            RestaurantMenuItem.restaurant_id == restaurant.id
        ).update({"is_active": False})

    db.commit()
    db.refresh(restaurant)

    # Save menu items from this scan
    for item in menu_items:
        menu_item = RestaurantMenuItem(
            id=uuid.uuid4(),
            restaurant_id=restaurant.id,
            name=item["name"],
            description=item.get("notes", ""),
            price=None,  # Could extract from menu in future
            category=None,  # Could categorize in future
            is_active=True
        )
        db.add(menu_item)

    db.commit()

    return {
        "restaurant": {
            "place_id": place_id,
            "name": details["name"],
            "address": details.get("address")
        },
        "menu_items": menu_items,
        "total_items": len(menu_items),
        "analyzed_at": dt.utcnow().isoformat(),
        "message": "Analysis saved! Other users can now see this restaurant has menu data."
    }
