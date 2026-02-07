"""
Test script for Google Places API integration.

Usage:
    python test_google_places.py

Make sure GOOGLE_PLACES_API_KEY is set in your .env file first.
"""

import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Check if API key is set
if not os.getenv("GOOGLE_PLACES_API_KEY"):
    print("❌ ERROR: GOOGLE_PLACES_API_KEY not found in .env file")
    print("\nPlease:")
    print("1. Get API key from https://console.cloud.google.com/")
    print("2. Add to backend/.env file:")
    print("   GOOGLE_PLACES_API_KEY=your_api_key_here")
    sys.exit(1)

from services.google_places_service import GooglePlacesService, calculate_distance

print("🧪 Testing Google Places API Integration\n")
print("=" * 60)

# Test 1: Text Search
print("\n📍 Test 1: Search for 'Nopa San Francisco'")
print("-" * 60)

result = GooglePlacesService.text_search("Nopa", "San Francisco")

if result:
    print("✅ Search successful!")
    print(f"   Name: {result['name']}")
    print(f"   Place ID: {result['place_id']}")
    print(f"   Address: {result.get('address', 'N/A')}")
    print(f"   Rating: {result.get('rating', 'N/A')} ({result.get('user_ratings_total', 0)} reviews)")
    print(f"   Price Level: {'$' * result.get('price_level', 0) if result.get('price_level') else 'N/A'}")
    print(f"   Photos Available: {result.get('photos_available', False)}")

    test_place_id = result['place_id']
else:
    print("❌ Search failed")
    sys.exit(1)

# Test 2: Nearby Search
print("\n📍 Test 2: Find restaurants near Nopa")
print("-" * 60)

# Use Nopa's location
lat = result['latitude']
lng = result['longitude']

nearby = GooglePlacesService.nearby_search(lat, lng, radius_meters=1000)

if nearby:
    print(f"✅ Found {len(nearby)} restaurants within 1km")

    for i, restaurant in enumerate(nearby[:5], 1):
        distance = calculate_distance(lat, lng, restaurant['latitude'], restaurant['longitude'])
        print(f"\n   {i}. {restaurant['name']}")
        print(f"      Distance: {int(distance)}m")
        print(f"      Address: {restaurant.get('vicinity', 'N/A')}")
        print(f"      Rating: {restaurant.get('rating', 'N/A')}")
        print(f"      Photos: {'Yes' if restaurant.get('photos_available') else 'No'}")
else:
    print("❌ Nearby search failed")

# Test 3: Place Details
print("\n📍 Test 3: Get detailed info for Nopa")
print("-" * 60)

details = GooglePlacesService.get_place_details(test_place_id)

if details:
    print("✅ Details retrieved successfully!")
    print(f"   Name: {details['name']}")
    print(f"   Address: {details.get('address', 'N/A')}")
    print(f"   Phone: {details.get('phone', 'N/A')}")
    print(f"   Website: {details.get('website', 'N/A')}")
    print(f"   Rating: {details.get('rating', 'N/A')} ({details.get('user_ratings_total', 0)} reviews)")
    print(f"   Number of photos: {len(details.get('photos', []))}")

    # Test 4: Photo URL
    if details.get('photos'):
        print("\n📍 Test 4: Get photo URL")
        print("-" * 60)

        photo_ref = details['photos'][0]['photo_reference']
        photo_url = GooglePlacesService.get_photo_url(photo_ref, max_width=400)

        print("✅ Photo URL generated!")
        print(f"   URL: {photo_url[:80]}...")
        print(f"   Dimensions: {details['photos'][0]['width']}x{details['photos'][0]['height']}")
    else:
        print("\n⚠️  Test 4: Skipped (no photos available)")
else:
    print("❌ Details fetch failed")

# Summary
print("\n" + "=" * 60)
print("✅ All tests passed!")
print("\nYou can now use the Google Places integration endpoints:")
print("   GET  /restaurants/search?query=Nopa&location=San Francisco")
print("   GET  /restaurants/nearby?latitude=37.7749&longitude=-122.4194")
print("   GET  /restaurants/{place_id}/details")
print("\nTo test via API:")
print("   1. Start backend: uvicorn main:app --reload")
print("   2. Visit: http://localhost:8000/docs")
print("   3. Try the /restaurants endpoints")
print("=" * 60)