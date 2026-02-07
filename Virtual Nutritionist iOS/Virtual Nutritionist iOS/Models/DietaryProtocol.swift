import Foundation

/// Represents a dietary protocol that users can select
struct DietaryProtocol: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    
    static let allProtocols: [DietaryProtocol] = [
        DietaryProtocol(
            id: "low_fodmap",
            name: "Low-FODMAP",
            description: "Avoids fermentable carbohydrates that can trigger IBS/IBD symptoms. Restricts garlic, onion, wheat, lactose, and certain fruits/vegetables.",
            icon: "leaf"
        ),
        DietaryProtocol(
            id: "scd",
            name: "Specific Carbohydrate Diet (SCD)",
            description: "Eliminates complex carbohydrates, grains, and most processed foods. Allows honey as the only sweetener.",
            icon: "carrot"
        ),
        DietaryProtocol(
            id: "low_residue",
            name: "Low-Residue Diet",
            description: "Limits high-fiber foods to reduce stool volume and bowel movements. Avoids raw vegetables, whole grains, nuts, and seeds.",
            icon: "circle.grid.2x1"
        ),
        DietaryProtocol(
            id: "gluten_free",
            name: "Gluten-Free",
            description: "Avoids gluten proteins found in wheat, barley, and rye. Essential for celiac disease management.",
            icon: "stop.circle"
        ),
        DietaryProtocol(
            id: "dairy_free",
            name: "Dairy-Free",
            description: "Avoids all milk and dairy products. For lactose intolerance or milk allergy.",
            icon: "drop.circle"
        ),
        DietaryProtocol(
            id: "nut_free",
            name: "Nut-Free",
            description: "Avoids all tree nuts. Critical for life-threatening allergies and anaphylaxis prevention.",
            icon: "exclamationmark.triangle"
        ),
        DietaryProtocol(
            id: "peanut_free",
            name: "Peanut-Free",
            description: "Avoids peanuts and peanut products. For severe peanut allergies.",
            icon: "exclamationmark.shield"
        ),
        DietaryProtocol(
            id: "soy_free",
            name: "Soy-Free",
            description: "Avoids soy and soy derivatives. For soy allergy or hormone sensitivity.",
            icon: "circle.slash"
        ),
        DietaryProtocol(
            id: "egg_free",
            name: "Egg-Free",
            description: "Avoids eggs and egg-derived ingredients. For egg allergy or vegan diet.",
            icon: "circle.dotted"
        ),
        DietaryProtocol(
            id: "shellfish_free",
            name: "Shellfish-Free",
            description: "Avoids all shellfish. Critical for life-threatening shellfish allergy.",
            icon: "exclamationmark.octagon"
        ),
        DietaryProtocol(
            id: "fish_free",
            name: "Fish-Free",
            description: "Avoids all fish and fish products. For fish allergy or dietary preference.",
            icon: "waveform.path"
        ),
        DietaryProtocol(
            id: "pork_free",
            name: "Pork-Free",
            description: "Avoids pork and pork products. For religious dietary laws or personal preference.",
            icon: "minus.circle"
        ),
        DietaryProtocol(
            id: "red_meat_free",
            name: "Red Meat-Free",
            description: "Avoids beef, pork, lamb, and other red meats. For health or environmental reasons.",
            icon: "heart.circle"
        ),
        DietaryProtocol(
            id: "vegan",
            name: "Vegan",
            description: "Avoids all animal products and derivatives including meat, dairy, eggs, and honey.",
            icon: "leaf.circle"
        ),
        DietaryProtocol(
            id: "vegetarian",
            name: "Vegetarian",
            description: "Avoids meat, poultry, and seafood. Allows dairy and eggs.",
            icon: "plant"
        ),
        DietaryProtocol(
            id: "paleo",
            name: "Paleo",
            description: "Avoids grains, legumes, dairy, and processed foods. Focuses on whole foods.",
            icon: "flame"
        ),
        DietaryProtocol(
            id: "keto",
            name: "Keto (Low-Carb)",
            description: "Very low carbohydrate, high fat diet. Limits carbs to 20-50g per day.",
            icon: "bolt.circle"
        ),
        DietaryProtocol(
            id: "low_histamine",
            name: "Low-Histamine",
            description: "Avoids high-histamine and histamine-releasing foods. For histamine intolerance.",
            icon: "gauge"
        )
    ]
}
