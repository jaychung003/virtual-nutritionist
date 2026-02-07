# Google Places API Setup

## 1. Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable billing (required for Places API)

## 2. Enable APIs

Enable these APIs in your project:
- **Places API** (New)
- **Places API (Legacy)** - We'll use this for better pricing
- **Geocoding API** (optional, for address lookup)

Navigate to: APIs & Services → Library → Search for "Places API"

## 3. Create API Key

1. Go to: APIs & Services → Credentials
2. Click "Create Credentials" → "API Key"
3. Copy the API key
4. **Restrict the API key:**
   - Application restrictions: None (or HTTP referrers for production)
   - API restrictions: Select "Restrict key"
     - Check: Places API, Geocoding API
5. Save restrictions

## 4. Add to Environment Variables

Add to your `.env` file:
```
GOOGLE_PLACES_API_KEY=your_api_key_here
```

Add to Render environment variables:
- Key: `GOOGLE_PLACES_API_KEY`
- Value: Your API key

## 5. Pricing

- **Text Search**: $32 per 1,000 requests
- **Nearby Search**: $32 per 1,000 requests
- **Place Details**: $17 per 1,000 requests (Basic), $32 (Contact/Atmosphere)
- **Place Photos**: $7 per 1,000 requests

**Optimization tips:**
- Cache results for 24 hours minimum
- Use Basic fields only for Place Details
- Request only needed fields to reduce cost

More info: https://mapsplatform.google.com/pricing/
