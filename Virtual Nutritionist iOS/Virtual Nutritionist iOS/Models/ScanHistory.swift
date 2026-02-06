//
//  ScanHistory.swift
//  Virtual Nutritionist iOS
//
//  Models for scan history.
//

import Foundation

struct ScanItem: Codable, Identifiable {
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
        return formatter.date(from: scannedAt)
    }

    var formattedDate: String {
        guard let date = scannedDate else { return scannedAt }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
    let scannedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case protocolsUsed = "protocols_used"
        case menuItems = "menu_items"
        case restaurantName = "restaurant_name"
        case scannedAt = "scanned_at"
    }

    var scannedDate: Date? {
        let formatter = ISO8601DateFormatter()
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
