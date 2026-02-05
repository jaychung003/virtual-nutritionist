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
        )
    ]
}
