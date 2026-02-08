"""
Test script to check first 50 photos from Nopa for menu photos.
"""

import os
import sys
import requests
import base64
import anthropic
import json
from dotenv import load_dotenv

# Load environment variables
load_dotenv('backend/.env')

GOOGLE_API_KEY = os.getenv("GOOGLE_PLACES_API_KEY")
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
NOPA_PLACE_ID = "ChIJ_dQjyK-AhYARBc9DFlxcclg"

def get_place_photos(place_id, max_photos=50):
    """Get up to max_photos photo references from Google Places."""
    url = "https://maps.googleapis.com/maps/api/place/details/json"

    params = {
        "place_id": place_id,
        "fields": "photos",
        "key": GOOGLE_API_KEY
    }

    response = requests.get(url, params=params, timeout=10)
    response.raise_for_status()
    data = response.json()

    if data["status"] != "OK":
        print(f"Error: {data['status']}")
        return []

    photos = data.get("result", {}).get("photos", [])
    print(f"Google returned {len(photos)} total photos")

    # Return up to max_photos
    return photos[:max_photos]

def download_photo(photo_reference):
    """Download a photo from Google Places."""
    url = "https://maps.googleapis.com/maps/api/place/photo"

    params = {
        "photo_reference": photo_reference,
        "maxwidth": 1600,
        "key": GOOGLE_API_KEY
    }

    response = requests.get(url, params=params, timeout=30, allow_redirects=True)

    if response.status_code == 200:
        return response.content

    return None

def is_menu_photo(image_bytes):
    """Check if photo is a menu using Claude Vision."""
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

        response_text = message.content[0].text.strip()

        # Remove markdown code blocks if present
        if response_text.startswith("```"):
            lines = response_text.split("\n")
            lines = [l for l in lines if not l.startswith("```")]
            response_text = "\n".join(lines).strip()

        result = json.loads(response_text)
        return result

    except Exception as e:
        print(f"Error analyzing photo: {e}")
        return {"is_menu": False, "confidence": 0.0, "reason": f"Error: {str(e)}"}

def get_photo_url(photo_reference):
    """Get the public URL for a photo."""
    return f"https://maps.googleapis.com/maps/api/place/photo?photo_reference={photo_reference}&maxwidth=1600&key={GOOGLE_API_KEY}"

def main():
    print(f"Checking first 50 photos from Nopa (place_id: {NOPA_PLACE_ID})")
    print("=" * 80)

    # Get photos
    photos = get_place_photos(NOPA_PLACE_ID, max_photos=50)
    print(f"Will check {len(photos)} photos\n")

    menu_photos = []

    for i, photo in enumerate(photos, 1):
        photo_ref = photo["photo_reference"]
        print(f"[{i}/{len(photos)}] Downloading photo...")

        # Download
        photo_bytes = download_photo(photo_ref)
        if not photo_bytes:
            print(f"  ✗ Failed to download\n")
            continue

        # Check if menu
        print(f"  Analyzing with Claude Vision...")
        detection = is_menu_photo(photo_bytes)

        is_menu = detection["is_menu"]
        confidence = detection["confidence"]
        reason = detection["reason"]

        if is_menu:
            print(f"  ✓ MENU FOUND! Confidence: {confidence}")
            print(f"    Reason: {reason}")
            menu_photos.append({
                "position": i,
                "photo_reference": photo_ref,
                "url": get_photo_url(photo_ref),
                "confidence": confidence,
                "reason": reason
            })
        else:
            print(f"  ✗ Not a menu (confidence: {confidence})")
            print(f"    Reason: {reason}")

        print()

    # Summary
    print("=" * 80)
    print(f"RESULTS: Found {len(menu_photos)} menu photos out of {len(photos)} checked")
    print("=" * 80)

    if menu_photos:
        print("\nMENU PHOTO URLs:")
        for menu in menu_photos:
            print(f"\n  Position {menu['position']}:")
            print(f"  URL: {menu['url']}")
            print(f"  Confidence: {menu['confidence']}")
            print(f"  Reason: {menu['reason']}")
    else:
        print("\nNo menu photos found in the first 50 photos.")

if __name__ == "__main__":
    main()
