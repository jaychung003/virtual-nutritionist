"""
Google Places API service for restaurant search and details.
"""

import os
import requests
from typing import Dict, List, Optional
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

GOOGLE_PLACES_API_KEY = os.getenv("GOOGLE_PLACES_API_KEY")
BASE_URL = "https://maps.googleapis.com/maps/api/place"


class GooglePlacesService:
    """Service for interacting with Google Places API"""

    @staticmethod
    def text_search(query: str, location: str = None) -> Optional[Dict]:
        """
        Search for a restaurant by name and optional location.

        Args:
            query: Restaurant name (e.g., "Nopa")
            location: Optional location string (e.g., "San Francisco")

        Returns:
            Dictionary with restaurant details or None if not found
        """
        url = f"{BASE_URL}/textsearch/json"

        search_query = f"{query} {location}" if location else query

        params = {
            "query": search_query,
            "type": "restaurant",
            "key": GOOGLE_PLACES_API_KEY
        }

        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()

            if data["status"] == "OK" and data.get("results"):
                # Return the first (best) match
                place = data["results"][0]
                return {
                    "place_id": place["place_id"],
                    "name": place["name"],
                    "address": place.get("formatted_address"),
                    "latitude": place["geometry"]["location"]["lat"],
                    "longitude": place["geometry"]["location"]["lng"],
                    "rating": place.get("rating"),
                    "user_ratings_total": place.get("user_ratings_total"),
                    "price_level": place.get("price_level"),
                    "types": place.get("types", []),
                    "business_status": place.get("business_status"),
                    "photos_available": len(place.get("photos", [])) > 0
                }

            logger.warning(f"No results found for query: {search_query}")
            return None

        except requests.exceptions.RequestException as e:
            logger.error(f"Error searching Google Places: {e}")
            return None
        except KeyError as e:
            logger.error(f"Unexpected response format: {e}")
            return None


    @staticmethod
    def nearby_search(
        latitude: float,
        longitude: float,
        radius_meters: int = 5000,
        cuisine_type: str = None,
        max_results: int = 60,
        rank_by_distance: bool = True
    ) -> List[Dict]:
        """
        Find restaurants near a location.

        Args:
            latitude: Latitude coordinate
            longitude: Longitude coordinate
            radius_meters: Search radius in meters (only used if rank_by_distance=False)
            cuisine_type: Optional cuisine filter (e.g., "italian", "mexican")
            max_results: Maximum number of results to return (default 60)
            rank_by_distance: If True, rank by distance (closest first). If False, rank by prominence.

        Returns:
            List of restaurant dictionaries sorted by distance
        """
        import time

        url = f"{BASE_URL}/nearbysearch/json"

        params = {
            "location": f"{latitude},{longitude}",
            "type": "restaurant",
            "key": GOOGLE_PLACES_API_KEY
        }

        # Google API: rankby=distance and radius are mutually exclusive
        if rank_by_distance:
            params["rankby"] = "distance"
            # When using rankby=distance, we'll filter by radius after getting results
        else:
            params["radius"] = min(radius_meters, 50000)  # Max 50km

        if cuisine_type:
            params["keyword"] = cuisine_type

        restaurants = []
        next_page_token = None
        pages_fetched = 0
        max_pages = 3  # Google allows up to 60 results (3 pages of 20)

        try:
            while pages_fetched < max_pages and len(restaurants) < max_results:
                # Add page token if we have one
                if next_page_token:
                    params["pagetoken"] = next_page_token
                    # Google requires a short delay before using page token
                    time.sleep(2)

                response = requests.get(url, params=params, timeout=10)
                response.raise_for_status()
                data = response.json()

                if data["status"] not in ["OK", "ZERO_RESULTS"]:
                    logger.warning(f"Nearby search returned status: {data['status']}")
                    break

                # Process results
                for place in data.get("results", []):
                    if len(restaurants) >= max_results:
                        break

                    restaurants.append({
                        "place_id": place["place_id"],
                        "name": place["name"],
                        "vicinity": place.get("vicinity"),  # Shorter address
                        "latitude": place["geometry"]["location"]["lat"],
                        "longitude": place["geometry"]["location"]["lng"],
                        "rating": place.get("rating"),
                        "user_ratings_total": place.get("user_ratings_total"),
                        "price_level": place.get("price_level"),
                        "types": place.get("types", []),
                        "business_status": place.get("business_status"),
                        "photos_available": len(place.get("photos", [])) > 0,
                        "is_open": place.get("opening_hours", {}).get("open_now")
                    })

                # Check for more pages
                next_page_token = data.get("next_page_token")
                pages_fetched += 1

                # Stop if no more pages
                if not next_page_token:
                    break

                # Remove pagetoken from params for next iteration
                if "pagetoken" in params:
                    del params["pagetoken"]

            # If we're ranking by distance, filter by radius after the fact
            if rank_by_distance and radius_meters:
                filtered = []
                for r in restaurants:
                    distance = calculate_distance(
                        latitude, longitude,
                        r["latitude"], r["longitude"]
                    )
                    # Only include restaurants within the specified radius
                    if distance <= radius_meters:
                        filtered.append(r)
                    # Stop early if we have enough results
                    if len(filtered) >= max_results:
                        break

                logger.info(f"Nearby search returned {len(filtered)} restaurants within {radius_meters}m (filtered from {len(restaurants)} total) across {pages_fetched} pages")
                return filtered

            logger.info(f"Nearby search returned {len(restaurants)} restaurants across {pages_fetched} pages")
            return restaurants

        except requests.exceptions.RequestException as e:
            logger.error(f"Error in nearby search: {e}")
            return restaurants  # Return what we have so far


    @staticmethod
    def get_place_details(place_id: str) -> Optional[Dict]:
        """
        Get detailed information about a restaurant.

        Args:
            place_id: Google Place ID

        Returns:
            Dictionary with detailed restaurant info or None
        """
        url = f"{BASE_URL}/details/json"

        # Request only fields we need to minimize cost
        fields = [
            "place_id",
            "name",
            "formatted_address",
            "geometry",
            "rating",
            "user_ratings_total",
            "price_level",
            "types",
            "website",
            "formatted_phone_number",
            "opening_hours",
            "photos",
            "business_status"
        ]

        params = {
            "place_id": place_id,
            "fields": ",".join(fields),
            "key": GOOGLE_PLACES_API_KEY
        }

        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()

            if data["status"] != "OK":
                logger.warning(f"Place details returned status: {data['status']}")
                return None

            result = data["result"]

            # Extract photos references
            photos = []
            for photo in result.get("photos", [])[:10]:  # Max 10 photos
                photos.append({
                    "photo_reference": photo["photo_reference"],
                    "width": photo["width"],
                    "height": photo["height"],
                    "html_attributions": photo.get("html_attributions", [])
                })

            return {
                "place_id": result["place_id"],
                "name": result["name"],
                "address": result.get("formatted_address"),
                "latitude": result["geometry"]["location"]["lat"],
                "longitude": result["geometry"]["location"]["lng"],
                "rating": result.get("rating"),
                "user_ratings_total": result.get("user_ratings_total"),
                "price_level": result.get("price_level"),
                "types": result.get("types", []),
                "website": result.get("website"),
                "phone": result.get("formatted_phone_number"),
                "opening_hours": result.get("opening_hours"),
                "photos": photos,
                "business_status": result.get("business_status")
            }

        except requests.exceptions.RequestException as e:
            logger.error(f"Error getting place details: {e}")
            return None


    @staticmethod
    def get_photo_url(photo_reference: str, max_width: int = 1600) -> str:
        """
        Get URL to download a place photo.

        Args:
            photo_reference: Photo reference from place details
            max_width: Maximum width in pixels (max 1600)

        Returns:
            URL to fetch the photo
        """
        url = f"{BASE_URL}/photo"

        params = {
            "photo_reference": photo_reference,
            "maxwidth": min(max_width, 1600),
            "key": GOOGLE_PLACES_API_KEY
        }

        # Return the URL - caller will fetch it
        return f"{url}?{'&'.join([f'{k}={v}' for k, v in params.items()])}"


    @staticmethod
    def download_photo(photo_reference: str, max_width: int = 1600) -> Optional[bytes]:
        """
        Download a place photo.

        Args:
            photo_reference: Photo reference from place details
            max_width: Maximum width in pixels (max 1600)

        Returns:
            Photo bytes or None if error
        """
        url = GooglePlacesService.get_photo_url(photo_reference, max_width)

        try:
            response = requests.get(url, timeout=30, allow_redirects=True)
            response.raise_for_status()

            if response.status_code == 200:
                return response.content

            return None

        except requests.exceptions.RequestException as e:
            logger.error(f"Error downloading photo: {e}")
            return None


def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate distance between two points using Haversine formula.

    Returns:
        Distance in meters
    """
    from math import radians, sin, cos, sqrt, atan2

    R = 6371000  # Earth's radius in meters

    lat1_rad = radians(lat1)
    lat2_rad = radians(lat2)
    delta_lat = radians(lat2 - lat1)
    delta_lon = radians(lon2 - lon1)

    a = sin(delta_lat / 2) ** 2 + cos(lat1_rad) * cos(lat2_rad) * sin(delta_lon / 2) ** 2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))

    distance = R * c
    return distance


def get_cuisine_type(types: List[str]) -> Optional[str]:
    """
    Extract cuisine type from Google Places types.

    Args:
        types: List of place types from Google

    Returns:
        Human-readable cuisine type or None
    """
    cuisine_mapping = {
        "italian_restaurant": "Italian",
        "mexican_restaurant": "Mexican",
        "chinese_restaurant": "Chinese",
        "japanese_restaurant": "Japanese",
        "thai_restaurant": "Thai",
        "indian_restaurant": "Indian",
        "french_restaurant": "French",
        "american_restaurant": "American",
        "mediterranean_restaurant": "Mediterranean",
        "greek_restaurant": "Greek",
        "korean_restaurant": "Korean",
        "vietnamese_restaurant": "Vietnamese",
        "spanish_restaurant": "Spanish",
        "middle_eastern_restaurant": "Middle Eastern",
        "seafood_restaurant": "Seafood",
        "steak_house": "Steakhouse",
        "sushi_restaurant": "Sushi",
        "pizza_restaurant": "Pizza",
        "fast_food_restaurant": "Fast Food",
        "cafe": "Cafe",
        "bakery": "Bakery",
        "bar": "Bar & Grill"
    }

    for place_type in types:
        if place_type in cuisine_mapping:
            return cuisine_mapping[place_type]

    # Default fallback
    return "Restaurant"
