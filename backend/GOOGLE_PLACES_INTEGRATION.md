# Google Places API Integration

## Overview

The Virtual Nutritionist backend now integrates with Google Places API to enable restaurant discovery **before** users visit. This shifts the app from a "point-of-decision" tool to a "pre-decision" tool.

## Features

✅ **Search restaurants by name** - Find specific restaurants and check if we have menu data
✅ **Find nearby restaurants** - Discover restaurants near user's location
✅ **Get restaurant details** - View photos, ratings, hours, contact info
✅ **Check menu availability** - See which restaurants have analyzable menu photos

## Setup

### 1. Get Google Places API Key

Follow instructions in `GOOGLE_SETUP.md` to:
1. Create Google Cloud project
2. Enable Places API
3. Create and restrict API key
4. Add to `.env` file

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Test Integration

```bash
cd backend
python test_google_places.py
```

Expected output:
```
🧪 Testing Google Places API Integration
==========================================================

📍 Test 1: Search for 'Nopa San Francisco'
----------------------------------------------------------
✅ Search successful!
   Name: Nopa
   Place ID: ChIJ...
   ...

✅ All tests passed!
```

## API Endpoints

### 1. Search Restaurants

**GET** `/restaurants/search`

Search for restaurants by name.

**Query Parameters:**
- `query` (required): Restaurant name
- `location` (optional): City, address, or region

**Example:**
```bash
curl "http://localhost:8000/restaurants/search?query=Nopa&location=San Francisco"
```

**Response:**
```json
[
  {
    "place_id": "ChIJ...",
    "name": "Nopa",
    "address": "560 Divisadero St, San Francisco, CA",
    "latitude": 37.7749,
    "longitude": -122.4375,
    "rating": 4.5,
    "user_ratings_total": 2847,
    "price_level": 2,
    "cuisine_type": "American",
    "photos_available": true,
    "has_menu_data": false
  }
]
```

---

### 2. Find Nearby Restaurants

**GET** `/restaurants/nearby`

Find restaurants near a location.

**Query Parameters:**
- `latitude` (required): Latitude coordinate
- `longitude` (required): Longitude coordinate
- `radius_meters` (optional): Search radius in meters (default: 5000, max: 50000)
- `cuisine_type` (optional): Filter by cuisine (e.g., "italian", "mexican")
- `protocols` (optional): List of dietary protocols to check

**Example:**
```bash
curl "http://localhost:8000/restaurants/nearby?latitude=37.7749&longitude=-122.4194&radius_meters=1000"
```

**Response:**
```json
[
  {
    "place_id": "ChIJ...",
    "name": "Nopa",
    "vicinity": "560 Divisadero St",
    "distance_meters": 450,
    "latitude": 37.7749,
    "longitude": -122.4375,
    "rating": 4.5,
    "price_level": 2,
    "cuisine_type": "American",
    "photos_available": true,
    "is_open": true,
    "has_menu_data": false,
    "safe_items_count": 0,
    "last_analyzed": null
  }
]
```

---

### 3. Get Restaurant Details

**GET** `/restaurants/{place_id}/details`

Get detailed information about a restaurant.

**Path Parameters:**
- `place_id`: Google Place ID

**Example:**
```bash
curl "http://localhost:8000/restaurants/ChIJ.../details"
```

**Response:**
```json
{
  "place_id": "ChIJ...",
  "name": "Nopa",
  "address": "560 Divisadero St, San Francisco, CA 94117",
  "latitude": 37.7749,
  "longitude": -122.4375,
  "rating": 4.5,
  "user_ratings_total": 2847,
  "price_level": 2,
  "cuisine_type": "American",
  "website": "https://www.nopasf.com",
  "phone": "+1 415-864-8643",
  "photos": [
    {
      "photo_reference": "ATplDJa...",
      "width": 4032,
      "height": 3024,
      "html_attributions": ["<a href='...'>User Name</a>"]
    }
  ],
  "has_menu_data": false,
  "menu_item_count": 0,
  "last_analyzed": null
}
```

---

### 4. Get Photo URL

**GET** `/restaurants/{place_id}/photos/{photo_reference}`

Get URL to download a restaurant photo.

**Path Parameters:**
- `place_id`: Google Place ID
- `photo_reference`: Photo reference from details endpoint

**Query Parameters:**
- `max_width` (optional): Maximum width in pixels (default: 800, max: 1600)

**Example:**
```bash
curl "http://localhost:8000/restaurants/ChIJ.../photos/ATplDJa...?max_width=400"
```

**Response:**
```json
{
  "photo_url": "https://maps.googleapis.com/maps/api/place/photo?photo_reference=ATplDJa...&maxwidth=400&key=...",
  "max_width": 400
}
```

## Cost Optimization

### API Pricing (per 1,000 requests)
- Text Search: $32
- Nearby Search: $32
- Place Details (Basic): $17
- Place Photos: $7

### Optimization Strategies

1. **Caching**
   - Cache search results for 24 hours
   - Cache place details for 7 days
   - Only re-fetch if user explicitly requests update

2. **Field Selection**
   - Request only needed fields in Place Details
   - Currently using Basic fields only ($17 vs $32)

3. **Batch Operations**
   - Nearby search returns multiple restaurants in one request
   - More efficient than individual searches

4. **User-Driven Analysis**
   - Only analyze menus when user expresses interest
   - Don't pre-analyze all restaurants

### Cost Example

**1,000 active users, 5 searches each per month:**
- 5,000 nearby searches: 5 × $32 = $160
- 2,500 detail views: 2.5 × $17 = $42.50
- 500 photo views: 0.5 × $7 = $3.50

**Total: ~$206/month** (with 80% cache hit rate)

## Data Flow

### Pre-Decision User Journey

```
User opens app
    ↓
GET /restaurants/nearby (Google Places)
    ↓
Shows list with "has_menu_data" flag
    ↓
User taps restaurant
    ↓
GET /restaurants/{place_id}/details
    ↓
If has_menu_data: Show cached analysis
If no data + has photos: Offer "Analyze menu" button
If no photos: Prompt user to scan in person
```

### Menu Analysis Flow (Next Phase)

```
User taps "Analyze menu"
    ↓
Download Google Place photos
    ↓
Use Claude Vision to identify menu photos
    ↓
Analyze menu photos (existing analyze_menu_image)
    ↓
Save to database (Restaurant + MenuItem tables)
    ↓
Cache for all users
```

## Next Steps

### Phase 2: On-Demand Menu Analysis
- [ ] Implement `/restaurants/{place_id}/analyze` endpoint
- [ ] Download and filter menu photos from Google
- [ ] Use Claude Vision to identify which photos are menus
- [ ] Analyze menus and save to database
- [ ] Return analysis to user

### Phase 3: iOS Integration
- [ ] Create `RestaurantService.swift`
- [ ] Build "Discover" tab with nearby restaurants
- [ ] Add restaurant detail view
- [ ] Implement "Analyze menu" button
- [ ] Show safe/caution/avoid breakdown

## Testing

### Manual Testing via Swagger UI

1. Start backend:
```bash
uvicorn main:app --reload
```

2. Open Swagger UI:
```
http://localhost:8000/docs
```

3. Try endpoints under "Restaurants" section

### Automated Testing

Run test script:
```bash
python test_google_places.py
```

### Testing with Real Data

```python
# Search for a restaurant
import requests

response = requests.get(
    "http://localhost:8000/restaurants/search",
    params={"query": "Nopa", "location": "San Francisco"}
)

print(response.json())

# Find nearby restaurants
response = requests.get(
    "http://localhost:8000/restaurants/nearby",
    params={
        "latitude": 37.7749,
        "longitude": -122.4194,
        "radius_meters": 2000
    }
)

for restaurant in response.json():
    print(f"{restaurant['name']} - {restaurant['distance_meters']}m away")
```

## Troubleshooting

### "GOOGLE_PLACES_API_KEY not found"
- Add API key to `backend/.env` file
- Restart the backend server

### "API key not valid"
- Check API key in Google Cloud Console
- Ensure Places API is enabled
- Check API restrictions match your usage

### "This API project is not authorized"
- Enable billing on Google Cloud project
- Places API requires billing enabled

### "ZERO_RESULTS"
- Try broader search terms
- Check location coordinates are correct
- Verify restaurant exists on Google Maps

## Resources

- [Google Places API Documentation](https://developers.google.com/maps/documentation/places/web-service/overview)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Places API Pricing](https://mapsplatform.google.com/pricing/)
