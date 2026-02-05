"""
IBD Menu Scanner - FastAPI Backend
Analyzes restaurant menu photos to identify trigger ingredients for IBD patients.
"""

import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from dotenv import load_dotenv

from services.vision_service import analyze_menu_image
from services.inference_service import load_protocol_triggers

load_dotenv()

app = FastAPI(
    title="IBD Menu Scanner API",
    description="Analyzes restaurant menus for IBD dietary triggers",
    version="1.0.0"
)

# CORS middleware for iOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class AnalyzeMenuRequest(BaseModel):
    """Request model for menu analysis."""
    image: str  # Base64 encoded image
    protocols: List[str]  # e.g., ["low_fodmap", "scd"]


class MenuItemResult(BaseModel):
    """Result for a single menu item."""
    name: str
    safety: str  # "safe", "caution", "avoid"
    triggers: List[str]
    notes: str


class AnalyzeMenuResponse(BaseModel):
    """Response model for menu analysis."""
    menu_items: List[MenuItemResult]


@app.get("/")
async def root():
    """Health check endpoint."""
    return {"status": "healthy", "service": "IBD Menu Scanner API"}


@app.get("/protocols")
async def get_protocols():
    """Get available dietary protocols."""
    return {
        "protocols": [
            {
                "id": "low_fodmap",
                "name": "Low-FODMAP",
                "description": "Avoids fermentable carbohydrates that can trigger IBS/IBD symptoms"
            },
            {
                "id": "scd",
                "name": "Specific Carbohydrate Diet (SCD)",
                "description": "Eliminates complex carbohydrates and most dairy"
            },
            {
                "id": "low_residue",
                "name": "Low-Residue Diet",
                "description": "Limits high-fiber foods to reduce bowel movements"
            }
        ]
    }


@app.post("/analyze-menu", response_model=AnalyzeMenuResponse)
async def analyze_menu(request: AnalyzeMenuRequest):
    """
    Analyze a menu image and identify trigger ingredients.
    
    Args:
        request: Contains base64 image and list of dietary protocols
        
    Returns:
        List of menu items with safety ratings and identified triggers
    """
    # Validate protocols
    valid_protocols = {"low_fodmap", "scd", "low_residue"}
    for protocol in request.protocols:
        if protocol not in valid_protocols:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid protocol: {protocol}. Valid options: {valid_protocols}"
            )
    
    if not request.protocols:
        raise HTTPException(
            status_code=400,
            detail="At least one protocol must be specified"
        )
    
    # Load trigger data for selected protocols
    triggers = load_protocol_triggers(request.protocols)
    
    # Analyze the menu image
    try:
        menu_items = await analyze_menu_image(request.image, request.protocols, triggers)
        return AnalyzeMenuResponse(menu_items=menu_items)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error analyzing menu: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
