"""
Inference service for loading and managing dietary protocol triggers.
"""

import json
import os
from typing import Dict, List, Set

# Path to protocol data files
DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data")


def load_protocol_triggers(protocols: List[str]) -> Dict[str, any]:
    """
    Load trigger data for the specified dietary protocols.
    
    Args:
        protocols: List of protocol IDs (e.g., ["low_fodmap", "scd"])
        
    Returns:
        Dictionary containing combined trigger information
    """
    protocol_files = {
        "low_fodmap": "fodmap_triggers.json",
        "scd": "scd_triggers.json",
        "low_residue": "low_residue_triggers.json"
    }
    
    combined_triggers = {
        "protocols": [],
        "all_triggers": set(),
        "common_restaurant_triggers": set(),
        "safe_alternatives": set(),
        "detailed_triggers": {}
    }
    
    for protocol in protocols:
        if protocol not in protocol_files:
            continue
            
        file_path = os.path.join(DATA_DIR, protocol_files[protocol])
        
        try:
            with open(file_path, "r") as f:
                data = json.load(f)
                
            combined_triggers["protocols"].append({
                "id": data.get("protocol_id"),
                "name": data.get("protocol_name"),
                "description": data.get("description")
            })
            
            # Extract all triggers from categories
            categories = data.get("high_fodmap_categories") or \
                        data.get("illegal_categories") or \
                        data.get("high_residue_categories", {})
            
            for category_name, category_data in categories.items():
                triggers = category_data.get("triggers", [])
                combined_triggers["all_triggers"].update(triggers)
                
                # Store detailed trigger info
                if protocol not in combined_triggers["detailed_triggers"]:
                    combined_triggers["detailed_triggers"][protocol] = {}
                combined_triggers["detailed_triggers"][protocol][category_name] = {
                    "description": category_data.get("description"),
                    "triggers": triggers
                }
            
            # Add common restaurant triggers
            restaurant_triggers = data.get("common_restaurant_triggers", [])
            combined_triggers["common_restaurant_triggers"].update(restaurant_triggers)
            
            # Add safe alternatives
            safe = data.get("safe_alternatives", [])
            combined_triggers["safe_alternatives"].update(safe)
            
        except FileNotFoundError:
            print(f"Warning: Protocol file not found: {file_path}")
        except json.JSONDecodeError:
            print(f"Warning: Invalid JSON in protocol file: {file_path}")
    
    # Convert sets to lists for JSON serialization
    combined_triggers["all_triggers"] = list(combined_triggers["all_triggers"])
    combined_triggers["common_restaurant_triggers"] = list(combined_triggers["common_restaurant_triggers"])
    combined_triggers["safe_alternatives"] = list(combined_triggers["safe_alternatives"])
    
    return combined_triggers


def format_triggers_for_prompt(triggers: Dict) -> str:
    """
    Format trigger data into a string for the Claude prompt.
    
    Args:
        triggers: Combined trigger dictionary
        
    Returns:
        Formatted string describing triggers
    """
    lines = ["DIETARY RESTRICTIONS TO CHECK:"]
    lines.append("")
    
    for protocol_info in triggers.get("protocols", []):
        lines.append(f"Protocol: {protocol_info['name']}")
        lines.append(f"Description: {protocol_info['description']}")
        lines.append("")
    
    lines.append("COMMON RESTAURANT TRIGGERS TO FLAG:")
    for trigger in sorted(triggers.get("common_restaurant_triggers", [])):
        lines.append(f"  - {trigger}")
    lines.append("")
    
    lines.append("ALL TRIGGER INGREDIENTS:")
    for trigger in sorted(triggers.get("all_triggers", [])):
        lines.append(f"  - {trigger}")
    lines.append("")
    
    lines.append("GENERALLY SAFE ALTERNATIVES:")
    for safe in sorted(triggers.get("safe_alternatives", [])):
        lines.append(f"  - {safe}")
    
    return "\n".join(lines)
