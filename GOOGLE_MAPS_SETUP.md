# Google Maps SDK Setup Instructions

## Completed ✅

The following has been implemented in the `feature/google-maps-integration` branch:

1. ✅ Info.plist configured with GMSApiKey placeholder and location permissions
2. ✅ Google Maps SDK initialization in MenuScannerApp.swift
3. ✅ ExploreViewModel extended with ViewMode enum and map properties
4. ✅ RestaurantMapView component created (UIViewRepresentable wrapper)
5. ✅ RestaurantInfoCard overlay for selected pins
6. ✅ ExploreView updated with segmented control (List/Map toggle)

## Manual Steps Required

### Step 1: Add Google Maps SDK via Swift Package Manager

1. Open `Virtual Nutritionist iOS.xcodeproj` in Xcode
2. Go to **File → Add Package Dependencies**
3. Enter package URL: `https://github.com/googlemaps/ios-maps-sdk`
4. Select version: **"Up to Next Major Version"** from `8.0.0`
5. Add both packages to target:
   - ✅ GoogleMaps
   - ✅ GoogleMapsBase
6. Build the project to verify (⌘+B)

### Step 2: Create iOS API Key in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select the same project used for the backend API
3. Navigate to **APIs & Services → Credentials**
4. Click **+ CREATE CREDENTIALS → API key**
5. Note the API key (you'll need it for Step 3)
6. Click **Edit API key** to configure restrictions:

   **Application restrictions:**
   - Select: **iOS apps**
   - Add bundle identifier: `com.dietwatch.ios` (verify actual bundle ID in Xcode)

   **API restrictions:**
   - Select: **Restrict key**
   - Enable ONLY: **Maps SDK for iOS**
   - DO NOT enable: Places API, Directions API, Geocoding API

7. Click **Save**

**Security Note:** This iOS key is separate from your backend API key. The backend continues to handle all Places API calls (search, nearby, details) for security and cost control.

### Step 3: Add API Key to Info.plist

1. Open `Virtual-Nutritionist-iOS-Info.plist` in Xcode
2. Find the `GMSApiKey` entry
3. Replace `YOUR_IOS_MAPS_API_KEY_HERE` with your actual API key from Step 2
4. Save the file

**Important:** Verify the key is in Info.plist, not .env or code. iOS apps bundle Info.plist into the app, and Google Maps SDK reads from it at runtime.

### Step 4: Build and Test

1. Build the project (⌘+B) - should compile without errors
2. Run in simulator (⌘+R)
3. Navigate to **Explore** tab
4. Tap **"Use My Location"**
5. Once restaurants load, tap **"Map"** in the segmented control
6. Verify:
   - ✅ Map displays centered on user location
   - ✅ Restaurant pins show up with correct positions
   - ✅ Pin colors reflect menu freshness (green/yellow/red/gray)
   - ✅ Tapping pin shows info card at bottom
   - ✅ "View Details" opens RestaurantDetailView
   - ✅ Toggle between List/Map works smoothly

### Troubleshooting

**Build Error: "No such module 'GoogleMaps'"**
- Verify SPM package was added correctly
- Try: Product → Clean Build Folder (⌘+Shift+K)
- Restart Xcode

**Map shows blank/gray tiles:**
- API key not set correctly in Info.plist
- API key restrictions too strict (verify bundle ID matches)
- Check Xcode console for API key errors

**Location not working:**
- Check Info.plist has `NSLocationWhenInUseUsageDescription`
- Simulator: Debug → Location → Custom Location
- Device: Settings → Privacy → Location Services → Diet Watch

**Markers not showing:**
- Check restaurant data has valid latitude/longitude
- Verify `restaurants` array is not empty
- Check console for marker creation errors

## Next Steps

Once testing is complete:

1. Push feature branch to remote:
   ```bash
   git push -u origin feature/google-maps-integration
   ```

2. Open PR to merge into main
3. Test on TestFlight before releasing to App Store

## Future Enhancements

- Marker clustering for 50+ restaurants
- "Get Directions" integration
- Custom map styles (night mode)
- Street View preview
- Heatmap overlay for safe restaurant density
