# IBD Menu Scanner

A mobile app that helps IBD (Inflammatory Bowel Disease) patients identify safe menu items at restaurants by photographing menus and analyzing them against dietary protocols.

## Problem Statement

"As an IBD patient, I want to photograph a restaurant menu and see which items likely contain my personal trigger ingredients, so I can make safer choices and avoid accidental flares."

## Features

- **Photo-based menu scanning**: Take a photo of any restaurant menu
- **Multi-protocol support**: Choose from Low-FODMAP, SCD, or Low-Residue diets
- **AI-powered ingredient inference**: Uses Claude Vision to identify likely ingredients
- **Conservative safety ratings**: Items rated as Safe, Caution, or Avoid
- **Clear explanations**: Each item includes notes about potential triggers

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   iOS App       │────▶│  FastAPI        │────▶│  Claude Vision  │
│   (SwiftUI)     │◀────│  Backend        │◀────│  API            │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Project Structure

```
Virtual Nutritionist/
├── ios/
│   └── MenuScanner/
│       ├── App/
│       │   └── MenuScannerApp.swift
│       ├── Views/
│       │   ├── ContentView.swift
│       │   ├── CameraView.swift
│       │   ├── ResultsView.swift
│       │   └── ProfileView.swift
│       ├── Models/
│       │   ├── MenuItem.swift
│       │   ├── UserProfile.swift
│       │   └── DietaryProtocol.swift
│       ├── Services/
│       │   ├── APIService.swift
│       │   └── CameraService.swift
│       └── Info.plist
├── backend/
│   ├── main.py
│   ├── requirements.txt
│   ├── .env
│   ├── services/
│   │   ├── vision_service.py
│   │   └── inference_service.py
│   └── data/
│       ├── fodmap_triggers.json
│       ├── scd_triggers.json
│       └── low_residue_triggers.json
└── README.md
```

## Setup Instructions

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Create a `.env` file with your Anthropic API key:
   ```
   ANTHROPIC_API_KEY=your_api_key_here
   ```

5. Run the server:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

The API will be available at `http://localhost:8000`

### iOS App Setup

1. Open Xcode and create a new iOS App project named "MenuScanner"

2. Copy the Swift files from `ios/MenuScanner/` into your Xcode project

3. Add the Info.plist settings for camera and photo library permissions

4. Update the `baseURL` in `APIService.swift` if needed:
   - For simulator: `http://localhost:8000`
   - For physical device: Use your computer's local IP address

5. Build and run on a device or simulator

## API Endpoints

### Health Check
```
GET /
```

### Get Protocols
```
GET /protocols
```
Returns available dietary protocols.

### Analyze Menu
```
POST /analyze-menu
Content-Type: application/json

{
  "image": "base64_encoded_image",
  "protocols": ["low_fodmap", "scd"]
}
```

Response:
```json
{
  "menu_items": [
    {
      "name": "Grilled Salmon",
      "safety": "safe",
      "triggers": [],
      "notes": "Plain grilled fish is generally safe; ask about seasonings"
    }
  ]
}
```

## Supported Dietary Protocols

### Low-FODMAP
Avoids fermentable carbohydrates including:
- Garlic and onion
- Wheat and gluten-containing grains
- Lactose-containing dairy
- Certain fruits (apples, pears, mangoes)
- Legumes

### Specific Carbohydrate Diet (SCD)
Eliminates:
- All grains (wheat, rice, corn, oats)
- Potatoes and starchy vegetables
- Most dairy products
- Refined sugars (only honey is allowed)
- Processed foods

### Low-Residue Diet
Limits high-fiber foods:
- Whole grains
- Raw vegetables
- Nuts and seeds
- Legumes
- Fruit skins

## Safety Note

This app provides **conservative estimates** based on typical restaurant preparation methods. When uncertain, items are flagged as "Caution" rather than "Safe." Always:

- Verify ingredients with restaurant staff
- Ask about preparation methods
- Inform servers of your dietary restrictions

## Technology Stack

- **iOS**: Swift, SwiftUI, iOS 16+
- **Backend**: Python, FastAPI
- **AI**: Anthropic Claude Vision API
- **Data**: JSON protocol definitions

## License

MIT License
