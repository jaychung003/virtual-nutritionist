import Foundation

/// Represents a single menu item with its dietary analysis
struct MenuItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let safety: SafetyRating
    let triggers: [String]
    let notes: String
    
    init(id: UUID = UUID(), name: String, safety: SafetyRating, triggers: [String], notes: String) {
        self.id = id
        self.name = name
        self.safety = safety
        self.triggers = triggers
        self.notes = notes
    }
    
    enum CodingKeys: String, CodingKey {
        case name, safety, triggers, notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.safety = try container.decode(SafetyRating.self, forKey: .safety)
        self.triggers = try container.decode([String].self, forKey: .triggers)
        self.notes = try container.decode(String.self, forKey: .notes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(safety, forKey: .safety)
        try container.encode(triggers, forKey: .triggers)
        try container.encode(notes, forKey: .notes)
    }
}

/// Safety rating for a menu item
enum SafetyRating: String, Codable {
    case safe
    case caution
    case avoid
    
    var displayName: String {
        switch self {
        case .safe: return "Safe"
        case .caution: return "Caution"
        case .avoid: return "Avoid"
        }
    }
    
    var emoji: String {
        switch self {
        case .safe: return "✅"
        case .caution: return "⚠️"
        case .avoid: return "❌"
        }
    }
}
