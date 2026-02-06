//
//  Bookmark.swift
//  Virtual Nutritionist iOS
//
//  Models for bookmarked menu items.
//

import Foundation

struct BookmarkResponse: Codable, Identifiable {
    let id: String
    let menuItemName: String
    let safetyRating: String
    let triggers: [String]
    let notes: String?
    let restaurantName: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case menuItemName = "menu_item_name"
        case safetyRating = "safety_rating"
        case triggers
        case notes
        case restaurantName = "restaurant_name"
        case createdAt = "created_at"
    }

    var createdDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: createdAt)
    }

    var formattedDate: String {
        guard let date = createdDate else { return createdAt }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var safetyColor: String {
        switch safetyRating.lowercased() {
        case "safe":
            return "green"
        case "caution":
            return "yellow"
        case "avoid":
            return "red"
        default:
            return "gray"
        }
    }
}

struct BookmarkListResponse: Codable {
    let bookmarks: [BookmarkResponse]
    let total: Int
}
