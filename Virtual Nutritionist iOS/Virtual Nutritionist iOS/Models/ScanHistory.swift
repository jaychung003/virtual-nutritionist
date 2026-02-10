//
//  ScanHistory.swift
//  Virtual Nutritionist iOS
//
//  Models for scan history.
//

import Foundation

struct ScanItem: Codable, Identifiable, Hashable {
    let id: String
    let protocolsUsed: [String]
    let restaurantName: String?
    let itemCount: Int
    let scannedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case protocolsUsed = "protocols_used"
        case restaurantName = "restaurant_name"
        case itemCount = "item_count"
        case scannedAt = "scanned_at"
    }

    var scannedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: scannedAt) {
            return date
        }
        // Fallback without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: scannedAt)
    }

    var formattedDate: String {
        guard let date = scannedDate else { return scannedAt }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var detailedDateTime: String {
        guard let date = scannedDate else { return scannedAt }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    var relativeTime: String {
        guard let date = scannedDate else { return scannedAt }

        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)

        if let days = components.day, days > 0 {
            return days == 1 ? "Yesterday" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
}

struct ScanListResponse: Codable {
    let scans: [ScanItem]
    let total: Int
    let page: Int
    let pageSize: Int

    enum CodingKeys: String, CodingKey {
        case scans
        case total
        case page
        case pageSize = "page_size"
    }
}

struct ScanDetailResponse: Codable, Identifiable {
    let id: String
    let protocolsUsed: [String]
    let menuItems: [MenuItem]
    let restaurantName: String?
    let imageData: String?
    let scannedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case protocolsUsed = "protocols_used"
        case menuItems = "menu_items"
        case restaurantName = "restaurant_name"
        case imageData = "image_data"
        case scannedAt = "scanned_at"
    }

    var scannedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: scannedAt) {
            return date
        }
        // Fallback without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: scannedAt)
    }

    var formattedDate: String {
        guard let date = scannedDate else { return scannedAt }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
