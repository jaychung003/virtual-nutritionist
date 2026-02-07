"""
Service for downloading and analyzing menu photos from Google Places.
"""

import base64
import logging
from typing import List, Dict, Optional, Tuple
import anthropic
import os

from services.google_places_service import GooglePlacesService

logger = logging.getLogger(__name__)

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")


class MenuPhotoService:
    """Service for identifying and analyzing menu photos from Google Places."""

    @staticmethod
    async def is_menu_photo(image_bytes: bytes) -> Dict:
        """
        Use Claude Vision to determine if a photo is a menu.

        Args:
            image_bytes: Image data as bytes

        Returns:
            Dictionary with is_menu (bool), confidence (float), and reason (str)
        """
        try:
            image_base64 = base64.b64encode(image_bytes).decode('utf-8')

            client = anthropic.Anthropic(api_key=ANTHROPIC_API_KEY)

            message = client.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=300,
                messages=[{
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": image_base64
                            }
                        },
                        {
                            "type": "text",
                            "text": """Is this a restaurant menu? Respond with JSON only:

{
  "is_menu": true/false,
  "confidence": 0.0-1.0,
  "reason": "brief explanation"
}

A menu shows food/drink items with names and usually prices.
Photos of prepared dishes, restaurant interiors, exteriors, or people are NOT menus.
Menu boards, printed menus, digital menus, and chalkboard menus ARE menus."""
                        }
                    ]
                }]
            )

            # Parse JSON response
            import json
            response_text = message.content[0].text.strip()

            # Remove markdown code blocks if present
            if response_text.startswith("```"):
                lines = response_text.split("\n")
                lines = [l for l in lines if not l.startswith("```")]
                response_text = "\n".join(lines).strip()

            result = json.loads(response_text)

            logger.info(f"Menu detection: is_menu={result['is_menu']}, confidence={result['confidence']}")

            return result

        except Exception as e:
            logger.error(f"Error detecting menu in photo: {e}")
            return {
                "is_menu": False,
                "confidence": 0.0,
                "reason": f"Error: {str(e)}"
            }


    @staticmethod
    async def download_and_filter_menu_photos(
        place_id: str,
        max_photos: int = 10,
        min_confidence: float = 0.7,
        return_debug_info: bool = False
    ) -> Tuple[List[Tuple[bytes, Dict]], Optional[Dict]]:
        """
        Download photos from Google Places and filter for menu photos.

        Args:
            place_id: Google Place ID
            max_photos: Maximum number of photos to check
            min_confidence: Minimum confidence threshold for menu detection
            return_debug_info: If True, return debug information

        Returns:
            Tuple of (menu_photos_list, debug_info_dict)
            - menu_photos_list: List of tuples: (photo_bytes, detection_result)
            - debug_info_dict: Debug information (only if return_debug_info=True)
        """
        logger.info(f"Downloading photos for place_id: {place_id}")

        # Get place details with photos
        details = GooglePlacesService.get_place_details(place_id)

        if not details or not details.get("photos"):
            logger.warning(f"No photos found for place_id: {place_id}")
            debug_info = {
                "total_photos_on_google": 0,
                "photos_checked": 0,
                "photo_check_results": [],
                "menu_photos_found": 0,
                "error": "No photos returned from Google Places API"
            } if return_debug_info else None
            return ([], debug_info)

        menu_photos = []
        photos_checked = 0
        photo_check_results = [] if return_debug_info else None

        for photo in details["photos"][:max_photos]:
            photos_checked += 1
            logger.info(f"Checking photo {photos_checked}/{min(len(details['photos']), max_photos)}")

            # Download photo
            photo_bytes = GooglePlacesService.download_photo(
                photo["photo_reference"],
                max_width=1600
            )

            if not photo_bytes:
                logger.warning(f"Failed to download photo: {photo['photo_reference']}")
                if return_debug_info:
                    photo_check_results.append({
                        "photo_number": photos_checked,
                        "photo_reference": photo["photo_reference"],
                        "download_success": False,
                        "error": "Failed to download photo"
                    })
                continue

            # Check if it's a menu
            detection = await MenuPhotoService.is_menu_photo(photo_bytes)

            if return_debug_info:
                photo_check_results.append({
                    "photo_number": photos_checked,
                    "photo_reference": photo["photo_reference"],
                    "download_success": True,
                    "is_menu": detection["is_menu"],
                    "confidence": detection["confidence"],
                    "reason": detection["reason"],
                    "accepted": detection["is_menu"] and detection["confidence"] >= min_confidence
                })

            if detection["is_menu"] and detection["confidence"] >= min_confidence:
                logger.info(f"✓ Menu found! Confidence: {detection['confidence']}")
                menu_photos.append((photo_bytes, detection))

                # Stop after finding 2-3 menu photos (usually enough)
                if len(menu_photos) >= 3:
                    logger.info("Found 3 menu photos, stopping search")
                    break
            else:
                logger.info(f"✗ Not a menu. Reason: {detection['reason']}")

        logger.info(f"Found {len(menu_photos)} menu photos out of {photos_checked} checked")

        debug_info = None
        if return_debug_info:
            debug_info = {
                "total_photos_on_google": len(details.get("photos", [])),
                "photos_checked": photos_checked,
                "photo_check_results": photo_check_results,
                "menu_photos_found": len(menu_photos),
                "min_confidence_threshold": min_confidence
            }

        return (menu_photos, debug_info)


    @staticmethod
    def deduplicate_menu_items(items: List[Dict]) -> List[Dict]:
        """
        Remove duplicate menu items (same item from multiple photos).

        Args:
            items: List of menu item dictionaries

        Returns:
            Deduplicated list of menu items
        """
        seen_items = {}

        for item in items:
            # Use lowercase name as key for deduplication
            key = item["name"].lower().strip()

            if key not in seen_items:
                seen_items[key] = item
            else:
                # Keep the item with more detailed information
                existing = seen_items[key]
                if len(item.get("notes", "")) > len(existing.get("notes", "")):
                    seen_items[key] = item

        return list(seen_items.values())
