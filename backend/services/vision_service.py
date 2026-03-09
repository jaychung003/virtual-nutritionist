"""
Vision service for analyzing menu images using Claude Vision API.
"""

import os
import json
import anthropic
from typing import Dict, List

from services.inference_service import format_triggers_for_prompt


def _detect_media_type(image_base64: str) -> str:
    """Detect image media type from base64 prefix."""
    if image_base64.startswith("/9j/"):
        return "image/jpeg"
    elif image_base64.startswith("iVBOR"):
        return "image/png"
    elif image_base64.startswith("R0lGOD"):
        return "image/gif"
    elif image_base64.startswith("UklGR"):
        return "image/webp"
    return "image/jpeg"


async def analyze_menu_images(
    images_base64: List[str],
    protocols: List[str],
    triggers: Dict
) -> List[Dict]:
    """
    Analyze one or more menu images using Claude Vision API.

    Args:
        images_base64: List of base64 encoded image data
        protocols: List of dietary protocols to check against
        triggers: Combined trigger data from protocols

    Returns:
        List of menu items with safety ratings
    """
    client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

    # Format triggers for the prompt
    trigger_context = format_triggers_for_prompt(triggers)

    image_count = len(images_base64)
    plural = "images" if image_count > 1 else "image"

    # Build the analysis prompt
    system_prompt = """You are a dietary analysis assistant helping IBD (Inflammatory Bowel Disease) patients identify safe menu items at restaurants.

Your task is to:
1. Extract all menu items from the provided menu {plural}
2. For each item, infer the likely ingredients based on common restaurant preparation methods
3. Check each item against the user's dietary restrictions
4. Provide a safety rating and explanation
5. If multiple images are provided, they may show different pages of the same menu. Deduplicate any items that appear in more than one photo.

IMPORTANT GUIDELINES:
- Be CONSERVATIVE in your assessments. When uncertain, flag as "caution" rather than "safe"
- Consider hidden ingredients (e.g., garlic and onion are common in most restaurant sauces)
- Note that breaded items contain wheat/flour
- Cream-based sauces contain dairy
- Many dressings contain garlic, onion, or honey
- Always recommend asking the server about preparation methods for uncertain items

SAFETY RATINGS:
- "safe": Item appears to contain no trigger ingredients based on typical preparation
- "caution": Item may contain trigger ingredients or preparation is uncertain
- "avoid": Item clearly contains one or more trigger ingredients

You must respond with valid JSON only, no additional text.""".format(plural=plural)

    user_prompt = f"""Analyze {"these" if image_count > 1 else "this"} restaurant menu {plural} for a patient following these dietary protocols: {', '.join(protocols)}

{trigger_context}

Extract each menu item and provide analysis in this exact JSON format:
{{
  "menu_items": [
    {{
      "name": "Item Name",
      "safety": "safe|caution|avoid",
      "triggers": ["list", "of", "trigger", "ingredients", "found"],
      "notes": "Explanation of the assessment and any recommendations"
    }}
  ]
}}

If you cannot read the menu or extract items, return:
{{
  "menu_items": [],
  "error": "Description of the issue"
}}

Analyze the menu now:"""

    # Build content blocks: all images first, then the text prompt
    content_blocks = []
    for img_b64 in images_base64:
        media_type = _detect_media_type(img_b64)
        content_blocks.append({
            "type": "image",
            "source": {
                "type": "base64",
                "media_type": media_type,
                "data": img_b64
            }
        })
    content_blocks.append({
        "type": "text",
        "text": user_prompt
    })

    # Call Claude Vision API
    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=8192,
        messages=[
            {
                "role": "user",
                "content": content_blocks
            }
        ],
        system=system_prompt
    )

    # Parse the response
    response_text = message.content[0].text

    # Clean up response if needed (remove markdown code blocks if present)
    if response_text.startswith("```"):
        lines = response_text.split("\n")
        # Remove first and last lines (```json and ```)
        lines = [l for l in lines if not l.startswith("```")]
        response_text = "\n".join(lines)

    try:
        result = json.loads(response_text)
        return result.get("menu_items", [])
    except json.JSONDecodeError as e:
        # If parsing fails, return an error item
        return [{
            "name": "Error parsing menu",
            "safety": "caution",
            "triggers": [],
            "notes": f"Could not parse menu analysis. Please try again with a clearer image. Error: {str(e)}"
        }]


async def analyze_menu_image(
    image_base64: str,
    protocols: List[str],
    triggers: Dict
) -> List[Dict]:
    """Backward-compatible wrapper for single image analysis."""
    return await analyze_menu_images([image_base64], protocols, triggers)
