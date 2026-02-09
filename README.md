# Virtual Nutritionist

A mobile app that helps people with dietary restrictions identify safe menu items at restaurants by photographing menus and analyzing them against personalized dietary protocols using AI.

## Problem Statement

"As someone with dietary restrictions, I want to photograph a restaurant menu and see which items likely contain my trigger ingredients, so I can make safer choices and avoid adverse reactions."

## Features

### Core Features
- **📸 Photo-based Menu Scanning**: Take a photo of any restaurant menu with your camera
- **🤖 AI-Powered Analysis**: Uses Claude Vision API to identify likely ingredients and preparation methods
- **⚖️ Conservative Safety Ratings**: Items rated as Safe, Caution, or Avoid
- **📝 Clear Explanations**: Each item includes trigger ingredients and preparation notes
- **🗂️ Multi-Protocol Support**: Choose from 15+ dietary protocols simultaneously

### User Features
- **👤 User Accounts**: Secure authentication with email/password
- **🔖 Bookmarks**: Save your favorite safe menu items for quick reference
- **📜 Scan History**: Review all your past menu scans
- **🌍 Restaurant Discovery**: Search and browse nearby restaurants (Google Places integration)
- **🤝 Community Contributions**: Link your scans to restaurants to help other users
- **🔍 Explore Tab**: Discover restaurants that already have menu data (feature-flagged)

### Safety & Legal
- **⚠️ AI Disclaimers**: Prominent warnings about AI inference limitations
- **🛡️ Legal Protection**: Onboarding popup requiring user acknowledgment
- **✅ Verification Reminders**: Encourages users to confirm with restaurant staff

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   iOS App       │────▶│  FastAPI        │────▶│  Claude Vision  │
│   (SwiftUI)     │◀────│  Backend        │◀────│  API            │
│                 │     │  + PostgreSQL   │     └─────────────────┘
│                 │     │  + JWT Auth     │
│                 │     │                 │     ┌─────────────────┐
│                 │     │                 │────▶│ Google Places   │
│                 │     │                 │◀────│ API             │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Key Components
- **iOS App**: SwiftUI-based native iOS app with camera integration
- **FastAPI Backend**: RESTful API handling authentication, menu analysis, and data management
- **PostgreSQL Database**: Stores users, scans, bookmarks, restaurants, and cached menus
- **Claude Vision API**: AI-powered menu OCR and ingredient inference
- **Google Places API**: Restaurant search, details, and photos

## Project Structure

```
Virtual Nutritionist/
├── Virtual Nutritionist iOS/
│   └── Virtual Nutritionist iOS/
│       ├── App/
│       │   ├── MenuScannerApp.swift
│       │   └── FeatureFlags.swift
│       ├── Views/
│       │   ├── ContentView.swift
│       │   ├── CameraView.swift
│       │   ├── ResultsView.swift
│       │   ├── ProfileView.swift
│       │   ├── OnboardingDisclaimerView.swift
│       │   ├── RestaurantSearchSheet.swift
│       │   ├── Auth/
│       │   │   ├── AuthContainerView.swift
│       │   │   ├── LoginView.swift
│       │   │   └── SignupView.swift
│       │   ├── Explore/
│       │   │   ├── ExploreView.swift
│       │   │   └── RestaurantDetailView.swift
│       │   ├── Bookmarks/
│       │   │   └── BookmarksView.swift
│       │   └── History/
│       │       └── ScanHistoryView.swift
│       ├── Models/
│       │   ├── MenuItem.swift
│       │   ├── UserProfile.swift
│       │   ├── DietaryProtocol.swift
│       │   ├── User.swift
│       │   ├── Restaurant.swift
│       │   └── Bookmark.swift
│       ├── Services/
│       │   ├── APIService.swift
│       │   ├── AuthService.swift
│       │   └── LocationService.swift
│       └── ViewModels/
│           └── AuthViewModel.swift
├── backend/
│   ├── main.py
│   ├── requirements.txt
│   ├── .env
│   ├── models/
│   │   ├── user.py
│   │   ├── restaurant.py
│   │   ├── scan.py
│   │   └── bookmark.py
│   ├── services/
│   │   ├── vision_service.py
│   │   ├── inference_service.py
│   │   ├── auth_service.py
│   │   └── google_places_service.py
│   ├── data/
│   │   └── [15+ protocol trigger JSON files]
│   └── alembic/
│       └── versions/
└── README.md
```

## Setup Instructions

### Backend Setup

1. **Install PostgreSQL** (if not already installed):
   ```bash
   brew install postgresql@14  # macOS
   # or download from postgresql.org
   ```

2. **Create a database**:
   ```bash
   createdb virtual_nutritionist
   ```

3. **Navigate to the backend directory**:
   ```bash
   cd backend
   ```

4. **Create a virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

5. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

6. **Create a `.env` file** with the following variables:
   ```env
   # Required
   ANTHROPIC_API_KEY=your_anthropic_api_key_here
   GOOGLE_PLACES_API_KEY=your_google_places_api_key_here
   DATABASE_URL=postgresql://user:password@localhost/virtual_nutritionist
   SECRET_KEY=your_jwt_secret_key_here

   # Optional
   DEBUG=true
   ```

7. **Run database migrations**:
   ```bash
   alembic upgrade head
   ```

8. **Run the server**:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

The API will be available at `http://localhost:8000`

#### API Documentation
Once running, visit:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### iOS App Setup

1. Open Xcode and create a new iOS App project named "MenuScanner"

2. Copy the Swift files from `ios/MenuScanner/` into your Xcode project

3. Add the Info.plist settings for camera and photo library permissions

4. Update the `baseURL` in `APIService.swift` if needed:
   - For simulator: `http://localhost:8000`
   - For physical device: Use your computer's local IP address

5. Build and run on a device or simulator

## API Endpoints

### Health & Info
- `GET /` - Health check
- `GET /protocols` - Get all available dietary protocols

### Authentication
- `POST /auth/signup` - Create new user account
- `POST /auth/login` - Login and get JWT token
- `GET /auth/me` - Get current user profile (requires auth)

### Menu Analysis
- `POST /analyze-menu` - Analyze menu photo (anonymous)
  ```json
  {
    "image": "base64_encoded_image",
    "protocols": ["low_fodmap", "scd"]
  }
  ```

- `POST /analyze-restaurant-menu/{place_id}` - Analyze and link to restaurant (requires auth)
  ```json
  {
    "image": "base64_encoded_image",
    "protocols": ["low_fodmap", "scd"]
  }
  ```

### Restaurants
- `GET /restaurants/search` - Search nearby restaurants (Google Places)
  - Query params: `query`, `latitude`, `longitude`
- `GET /restaurants/{place_id}` - Get restaurant details
- `GET /restaurants/{place_id}/menu` - Get cached menu analysis
- `GET /restaurants/{place_id}/photo` - Get restaurant photo (proxied from Google)

### User Data (requires authentication)
- `GET /scans` - Get user's scan history
- `GET /bookmarks` - Get user's bookmarked items
- `POST /bookmarks` - Create new bookmark
- `DELETE /bookmarks/{bookmark_id}` - Delete bookmark

### Response Example
```json
{
  "menu_items": [
    {
      "name": "Grilled Salmon",
      "safety": "safe",
      "triggers": [],
      "notes": "Plain grilled fish is generally safe; ask about seasonings"
    },
    {
      "name": "Caesar Salad",
      "safety": "avoid",
      "triggers": ["dairy (parmesan)", "garlic", "wheat (croutons)"],
      "notes": "Traditional Caesar contains multiple high-FODMAP ingredients"
    }
  ]
}
```

## Supported Dietary Protocols

The app supports **15+ dietary protocols** that can be used simultaneously. Users can select multiple protocols to analyze menus against all their restrictions at once.

### Core Protocols
- **Low-FODMAP**: Avoids fermentable carbohydrates (garlic, onion, wheat, lactose, legumes)
- **Specific Carbohydrate Diet (SCD)**: Eliminates all grains, starchy vegetables, and refined sugars
- **Low-Residue**: Limits high-fiber foods (whole grains, raw vegetables, nuts, seeds)

### Allergen Protocols
- **Gluten-Free**: Avoids wheat, barley, rye, and cross-contamination
- **Dairy-Free**: Eliminates all milk products and lactose
- **Nut-Free**: Avoids tree nuts and peanuts
- **Shellfish-Free**: Eliminates all shellfish
- **Soy-Free**: Avoids soy products and derivatives
- **Egg-Free**: Eliminates eggs and egg-containing products

### Specialized Diets
- **Vegan**: Plant-based, excludes all animal products
- **Vegetarian**: Excludes meat and fish
- **Paleo**: Focuses on whole foods, excludes grains and processed foods
- **Keto**: Low-carb, high-fat diet
- **Histamine-Free**: Avoids histamine-rich foods
- **AIP (Autoimmune Protocol)**: Eliminates inflammatory foods

Each protocol includes comprehensive trigger ingredient lists based on clinical guidelines and research.

## Safety & Legal Disclaimers

### AI Analysis Limitations
This app uses **AI to infer ingredients** in menu items based on typical recipes and preparation methods. The analysis:
- May not be 100% accurate
- Cannot detect cross-contamination
- May miss hidden ingredients or substitutions
- Should be considered estimates, not definitive ingredient lists

### Conservative Approach
When uncertain, items are automatically flagged as **"Caution"** rather than "Safe" to err on the side of safety.

### User Responsibilities
**Always verify with restaurant staff before consuming** any menu item, especially if you have:
- Severe allergies (anaphylaxis risk)
- Celiac disease
- Strict medical dietary requirements

### Legal Protection
The app includes:
- **Onboarding disclaimer popup**: Requires user acknowledgment before first use
- **Results page warnings**: Prominent banner on every analysis
- **No liability clause**: Users accept responsibility for their food choices

### Best Practices
- ✅ Use the app as a **screening tool** to identify potentially safe options
- ✅ Always **confirm with restaurant staff** before ordering
- ✅ Inform servers about your **specific dietary restrictions**
- ✅ Ask about **preparation methods** and cross-contamination
- ❌ Do not rely solely on the app for life-threatening allergies

## Technology Stack

### Frontend
- **Platform**: iOS 16+
- **Language**: Swift
- **Framework**: SwiftUI
- **Architecture**: MVVM pattern
- **Features**: Camera integration, Location services, Feature flags

### Backend
- **Language**: Python 3.11+
- **Framework**: FastAPI
- **Database**: PostgreSQL with SQLAlchemy ORM
- **Migrations**: Alembic
- **Authentication**: JWT (JSON Web Tokens)
- **Password Hashing**: bcrypt

### APIs & Services
- **AI/ML**: Anthropic Claude 4.6 Vision API
- **Maps**: Google Places API (search, details, photos)
- **Image Processing**: Base64 encoding/decoding

### Data Management
- **Protocol Definitions**: JSON files with trigger ingredients
- **Caching**: Restaurant menu data cached in PostgreSQL
- **User Data**: Scans, bookmarks, and preferences stored securely

### Development Tools
- **Version Control**: Git + GitHub
- **iOS Development**: Xcode
- **API Testing**: FastAPI Swagger UI
- **Database Tools**: PostgreSQL CLI, pgAdmin

## Feature Flags

The app uses feature flags to enable/disable experimental features:

```swift
// FeatureFlags.swift
struct FeatureFlags {
    static let exploreEnabled = false  // Restaurant discovery and exploration
}
```

### Available Flags
- `exploreEnabled`: Enables the Explore tab and community menu contributions

## Recent Updates

### v2.0 (Current)
- ✅ User authentication and accounts
- ✅ Bookmark and scan history features
- ✅ Restaurant discovery via Google Places
- ✅ Community-contributed menu analysis
- ✅ 15+ dietary protocols (expanded from 3)
- ✅ Legal disclaimers and AI accuracy warnings
- ✅ Feature flag system for experimental features

### v1.0 (Initial Release)
- Basic menu scanning
- 3 dietary protocols (Low-FODMAP, SCD, Low-Residue)
- AI-powered ingredient inference
- Safety ratings (Safe, Caution, Avoid)

## Future Roadmap

- 🔄 Recipe suggestions for safe menu item modifications
- 🔄 Social features (share safe restaurants with friends)
- 🔄 Nutritional information estimation
- 🔄 Multi-language menu support
- 🔄 Android app
- 🔄 Export scan history to PDF/CSV
- 🔄 Integration with restaurant reservation systems

## Contributing

This is a personal project, but contributions are welcome! Areas of interest:
- Additional dietary protocol definitions
- Improved AI prompts for ingredient inference
- UI/UX enhancements
- Bug fixes and performance improvements

## Acknowledgments

- Built with [Anthropic Claude](https://www.anthropic.com/claude) Vision API
- Restaurant data from [Google Places API](https://developers.google.com/maps/documentation/places)
- Inspired by the IBD and food allergy communities
