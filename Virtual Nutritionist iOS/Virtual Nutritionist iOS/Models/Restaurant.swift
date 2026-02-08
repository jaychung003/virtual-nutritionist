//
//  Restaurant.swift
//  Virtual Nutritionist iOS
//
//  Models for Google Places restaurant data
//

import Foundation

// MARK: - Search Result
struct RestaurantSearchResult: Codable, Identifiable {
    let placeId: String
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let rating: Double?
    let userRatingsTotal: Int?
    let priceLevel: Int?
    let cuisineType: String?
    let photosAvailable: Bool
    let hasMenuData: Bool

    var id: String { placeId }

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case address
        case latitude
        case longitude
        case rating
        case userRatingsTotal = "user_ratings_total"
        case priceLevel = "price_level"
        case cuisineType = "cuisine_type"
        case photosAvailable = "photos_available"
        case hasMenuData = "has_menu_data"
    }

    var priceString: String {
        guard let level = priceLevel, level > 0 else { return "" }
        return String(repeating: "$", count: level)
    }
}

// MARK: - Nearby Result
struct RestaurantNearbyResult: Codable, Identifiable {
    let placeId: String
    let name: String
    let vicinity: String
    let distanceMeters: Int
    let latitude: Double
    let longitude: Double
    let rating: Double?
    let priceLevel: Int?
    let cuisineType: String?
    let photosAvailable: Bool
    let isOpen: Bool?
    let hasMenuData: Bool
    let safeItemsCount: Int?
    let lastAnalyzed: Date?

    var id: String { placeId }

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case vicinity
        case distanceMeters = "distance_meters"
        case latitude
        case longitude
        case rating
        case priceLevel = "price_level"
        case cuisineType = "cuisine_type"
        case photosAvailable = "photos_available"
        case isOpen = "is_open"
        case hasMenuData = "has_menu_data"
        case safeItemsCount = "safe_items_count"
        case lastAnalyzed = "last_analyzed"
    }

    var priceString: String {
        guard let level = priceLevel, level > 0 else { return "" }
        return String(repeating: "$", count: level)
    }

    var distanceString: String {
        let miles = Double(distanceMeters) * 0.000621371
        return String(format: "%.1f mi", miles)
    }

    var freshnessStatus: FreshnessStatus {
        guard let lastAnalyzed = lastAnalyzed else {
            return .none
        }

        let daysSince = Calendar.current.dateComponents([.day], from: lastAnalyzed, to: Date()).day ?? 0

        if daysSince < 30 {
            return .fresh
        } else if daysSince < 90 {
            return .recent
        } else {
            return .stale
        }
    }
}

// MARK: - Detail Response
struct RestaurantDetail: Codable {
    let placeId: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let rating: Double?
    let userRatingsTotal: Int?
    let priceLevel: Int?
    let cuisineType: String?
    let website: String?
    let phone: String?
    let photos: [RestaurantPhoto]
    let hasMenuData: Bool
    let menuItemCount: Int?
    let lastAnalyzed: Date?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case address
        case latitude
        case longitude
        case rating
        case userRatingsTotal = "user_ratings_total"
        case priceLevel = "price_level"
        case cuisineType = "cuisine_type"
        case website
        case phone
        case photos
        case hasMenuData = "has_menu_data"
        case menuItemCount = "menu_item_count"
        case lastAnalyzed = "last_analyzed"
    }

    var priceString: String {
        guard let level = priceLevel, level > 0 else { return "" }
        return String(repeating: "$", count: level)
    }

    var freshnessStatus: FreshnessStatus {
        guard let lastAnalyzed = lastAnalyzed else {
            return .none
        }

        let daysSince = Calendar.current.dateComponents([.day], from: lastAnalyzed, to: Date()).day ?? 0

        if daysSince < 30 {
            return .fresh
        } else if daysSince < 90 {
            return .recent
        } else {
            return .stale
        }
    }
}

struct RestaurantPhoto: Codable, Identifiable {
    let photoReference: String
    let width: Int
    let height: Int

    var id: String { photoReference }

    enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
        case width
        case height
    }
}

// MARK: - Cached Menu Response
struct CachedMenuResponse: Codable {
    let restaurant: CachedMenuRestaurant
    let menuItems: [CachedMenuItem]
    let metadata: MenuMetadata
    let message: String
}

struct CachedMenuRestaurant: Codable {
    let placeId: String
    let name: String
    let address: String
    let cuisineType: String?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case address
        case cuisineType = "cuisine_type"
    }
}

struct CachedMenuItem: Codable, Identifiable {
    let name: String
    let description: String?
    let price: String?
    let category: String?

    var id: String { name }
}

struct MenuMetadata: Codable {
    let lastAnalyzed: Date
    let daysSinceScan: Int
    let freshness: String
    let totalScans: Int
    let itemCount: Int

    enum CodingKeys: String, CodingKey {
        case lastAnalyzed = "last_analyzed"
        case daysSinceScan = "days_since_scan"
        case freshness
        case totalScans = "total_scans"
        case itemCount = "item_count"
    }

    var freshnessStatus: FreshnessStatus {
        if daysSinceScan < 30 {
            return .fresh
        } else if daysSinceScan < 90 {
            return .recent
        } else {
            return .stale
        }
    }
}

// MARK: - Freshness Status
enum FreshnessStatus {
    case fresh   // < 30 days
    case recent  // 30-90 days
    case stale   // 90+ days
    case none    // No data

    var icon: String {
        switch self {
        case .fresh: return "🟢"
        case .recent: return "🟡"
        case .stale: return "🔴"
        case .none: return "⚪"
        }
    }

    var label: String {
        switch self {
        case .fresh: return "Fresh"
        case .recent: return "Recent"
        case .stale: return "Stale"
        case .none: return "No menu data"
        }
    }

    var color: String {
        switch self {
        case .fresh: return "green"
        case .recent: return "yellow"
        case .stale: return "red"
        case .none: return "gray"
        }
    }
}
