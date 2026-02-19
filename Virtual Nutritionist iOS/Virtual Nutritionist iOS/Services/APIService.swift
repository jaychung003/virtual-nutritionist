import Foundation
import UIKit

/// Service for communicating with the backend API
class APIService {
    static let shared = APIService()

    /// Production backend on Render. Use a different URL for local/simulator if needed.
    private let baseURL = "http://52.12.190.32"
    private let keychain = KeychainService.shared
    private let authService = AuthService.shared

    private init() {}

    // MARK: - Date Decoding Helper

    /// Custom date decoder that handles ISO8601 with fractional seconds and timezone variations
    private static func customDateDecoder() -> JSONDecoder.DateDecodingStrategy {
        return .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }

            // Try standard ISO8601
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }

            // Try DateFormatter for edge cases
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            print("⚠️ Failed to decode date: \(dateString)")
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
    }

    // MARK: - Private Helpers

    private func getAuthHeaders() -> [String: String] {
        var headers = ["Content-Type": "application/json"]

        // Add auth token if available
        if let accessToken = try? keychain.getAccessToken() {
            headers["Authorization"] = "Bearer \(accessToken)"
        }

        return headers
    }

    private func performRequest<T: Decodable>(
        url: String,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = false,
        responseType: T.Type
    ) async throws -> T {
        guard let requestURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        request.timeoutInterval = 30  // Increase timeout for slow backend

        // Add headers
        for (key, value) in getAuthHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Add body if present
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Handle 401 - try to refresh token
            if httpResponse.statusCode == 401 && requiresAuth {
                // Try to refresh token
                try? await authService.refreshToken()

                // Retry request with new token
                for (key, value) in getAuthHeaders() {
                    request.setValue(value, forHTTPHeaderField: key)
                }

                let (retryData, retryResponse) = try await URLSession.shared.data(for: request)

                guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                if !(200...299).contains(retryHttpResponse.statusCode) {
                    throw APIError.httpError(retryHttpResponse.statusCode)
                }

                return try JSONDecoder().decode(T.self, from: retryData)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to parse error message
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.detail)
                }
                throw APIError.httpError(httpResponse.statusCode)
            }

            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingError
        }
    }

    // MARK: - Menu Analysis

    /// Analyze a menu image and return safety ratings
    /// - Parameters:
    ///   - image: The captured menu image
    ///   - protocols: List of dietary protocol IDs
    /// - Returns: Array of analyzed menu items
    func analyzeMenu(image: UIImage, protocols: [String]) async throws -> [MenuItem] {
        // Prepare image
        let resizedImage = CameraService.shared.resizeImage(image, maxDimension: 1280)
        guard let imageData = CameraService.shared.compressImage(resizedImage, maxSizeKB: 500) else {
            throw APIError.imageProcessingFailed
        }

        let base64Image = imageData.base64EncodedString()

        // Build request
        guard let url = URL(string: "\(baseURL)/analyze-menu") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60 // Allow time for AI processing

        // Add auth headers
        for (key, value) in getAuthHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let requestBody = AnalyzeMenuRequest(image: base64Image, protocols: protocols)
        request.httpBody = try JSONEncoder().encode(requestBody)

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.detail)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        // Parse response
        let analysisResponse = try JSONDecoder().decode(AnalyzeMenuResponse.self, from: data)
        return analysisResponse.menuItems
    }
    
    /// Fetch available dietary protocols from the server
    func getProtocols() async throws -> [ProtocolInfo] {
        guard let url = URL(string: "\(baseURL)/protocols") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let protocolsResponse = try JSONDecoder().decode(ProtocolsResponse.self, from: data)
        return protocolsResponse.protocols
    }
    
    /// Check if the backend server is reachable
    func healthCheck() async -> Bool {
        guard let url = URL(string: "\(baseURL)/") else {
            return false
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...299).contains(httpResponse.statusCode)
            }
            return false
        } catch {
            return false
        }
    }

    // MARK: - Restaurant Discovery

    /// Search for restaurants by name
    func searchRestaurants(query: String, location: String? = nil) async throws -> [RestaurantSearchResult] {
        var urlString = "\(baseURL)/restaurants/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let location = location {
            urlString += "&location=\(location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }

        return try await performRequest(
            url: urlString,
            responseType: [RestaurantSearchResult].self
        )
    }

    /// Get nearby restaurants
    func getNearbyRestaurants(
        latitude: Double,
        longitude: Double,
        radiusMeters: Int = 5000,
        cuisineType: String? = nil,
        protocols: [String] = [],
        limit: Int = 15
    ) async throws -> [RestaurantNearbyResult] {
        var urlString = "\(baseURL)/restaurants/nearby?latitude=\(latitude)&longitude=\(longitude)&radius_meters=\(radiusMeters)&limit=\(limit)"

        if let cuisine = cuisineType {
            urlString += "&cuisine_type=\(cuisine.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }

        for dietaryProtocol in protocols {
            urlString += "&protocols=\(dietaryProtocol)"
        }

        // Configure JSON decoder with date decoding (handle fractional seconds)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = APIService.customDateDecoder()

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        for (key, value) in getAuthHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.detail)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try decoder.decode([RestaurantNearbyResult].self, from: data)
    }

    /// Get restaurant details
    func getRestaurantDetails(placeId: String) async throws -> RestaurantDetail {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds first
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }

            // Fallback to standard ISO8601
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }

        guard let url = URL(string: "\(baseURL)/restaurants/\(placeId)/details") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        for (key, value) in getAuthHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.detail)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try decoder.decode(RestaurantDetail.self, from: data)
    }

    /// Get cached menu analysis for a restaurant
    func getCachedMenu(placeId: String, protocols: [String] = []) async throws -> CachedMenuResponse {
        var urlString = "\(baseURL)/restaurants/\(placeId)/menu"

        if !protocols.isEmpty {
            urlString += "?protocols=" + protocols.joined(separator: "&protocols=")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = APIService.customDateDecoder()

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        for (key, value) in getAuthHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.detail)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try decoder.decode(CachedMenuResponse.self, from: data)
    }

    /// Analyze restaurant menu with community contribution
    func analyzeRestaurantMenu(
        placeId: String,
        image: UIImage,
        protocols: [String]
    ) async throws -> AnalyzeMenuResponse {
        // Prepare image
        let resizedImage = CameraService.shared.resizeImage(image, maxDimension: 1280)
        guard let imageData = CameraService.shared.compressImage(resizedImage, maxSizeKB: 500) else {
            throw APIError.imageProcessingFailed
        }

        let base64Image = imageData.base64EncodedString()

        // Build request
        guard let url = URL(string: "\(baseURL)/restaurants/\(placeId)/analyze") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60

        for (key, value) in getAuthHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }

        struct AnalyzeRestaurantRequest: Encodable {
            let image: String
            let protocols: [String]
        }

        let requestBody = AnalyzeRestaurantRequest(image: base64Image, protocols: protocols)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.detail)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(AnalyzeMenuResponse.self, from: data)
    }

    // MARK: - Profile & Preferences

    func getProfile() async throws -> ProfileResponse {
        try await performRequest(
            url: "\(baseURL)/profile",
            requiresAuth: true,
            responseType: ProfileResponse.self
        )
    }

    func updatePreferences(protocols: [String]) async throws -> UserPreferencesData {
        struct UpdateRequest: Encodable {
            let selectedProtocols: [String]

            enum CodingKeys: String, CodingKey {
                case selectedProtocols = "selected_protocols"
            }
        }

        return try await performRequest(
            url: "\(baseURL)/profile/preferences",
            method: "PUT",
            body: UpdateRequest(selectedProtocols: protocols),
            requiresAuth: true,
            responseType: UserPreferencesData.self
        )
    }

    // MARK: - Scan History

    func getScanHistory(page: Int = 1, pageSize: Int = 20) async throws -> ScanListResponse {
        try await performRequest(
            url: "\(baseURL)/scans?page=\(page)&page_size=\(pageSize)",
            requiresAuth: true,
            responseType: ScanListResponse.self
        )
    }

    func getScanDetail(scanId: String) async throws -> ScanDetailResponse {
        try await performRequest(
            url: "\(baseURL)/scans/\(scanId)",
            requiresAuth: true,
            responseType: ScanDetailResponse.self
        )
    }

    func deleteScan(scanId: String) async throws {
        struct DeleteResponse: Decodable {
            let message: String
        }

        let _: DeleteResponse = try await performRequest(
            url: "\(baseURL)/scans/\(scanId)",
            method: "DELETE",
            requiresAuth: true,
            responseType: DeleteResponse.self
        )
    }

    // MARK: - Bookmarks

    func createBookmark(
        menuItemName: String,
        safetyRating: String,
        triggers: [String],
        notes: String?,
        restaurantName: String?
    ) async throws -> BookmarkResponse {
        struct CreateRequest: Encodable {
            let menuItemName: String
            let safetyRating: String
            let triggers: [String]
            let notes: String?
            let restaurantName: String?

            enum CodingKeys: String, CodingKey {
                case menuItemName = "menu_item_name"
                case safetyRating = "safety_rating"
                case triggers
                case notes
                case restaurantName = "restaurant_name"
            }
        }

        return try await performRequest(
            url: "\(baseURL)/bookmarks",
            method: "POST",
            body: CreateRequest(
                menuItemName: menuItemName,
                safetyRating: safetyRating,
                triggers: triggers,
                notes: notes,
                restaurantName: restaurantName
            ),
            requiresAuth: true,
            responseType: BookmarkResponse.self
        )
    }

    func getBookmarks(safetyRating: String? = nil) async throws -> BookmarkListResponse {
        var urlString = "\(baseURL)/bookmarks"
        if let rating = safetyRating {
            urlString += "?safety_rating=\(rating)"
        }

        return try await performRequest(
            url: urlString,
            requiresAuth: true,
            responseType: BookmarkListResponse.self
        )
    }

    func deleteBookmark(bookmarkId: String) async throws {
        struct DeleteResponse: Decodable {
            let message: String
        }

        let _: DeleteResponse = try await performRequest(
            url: "\(baseURL)/bookmarks/\(bookmarkId)",
            method: "DELETE",
            requiresAuth: true,
            responseType: DeleteResponse.self
        )
    }
}

// MARK: - Request/Response Models

struct AnalyzeMenuRequest: Encodable {
    let image: String
    let protocols: [String]
}

struct AnalyzeMenuResponse: Decodable {
    let menuItems: [MenuItem]
    
    enum CodingKeys: String, CodingKey {
        case menuItems = "menu_items"
    }
}

struct ProtocolsResponse: Decodable {
    let protocols: [ProtocolInfo]
}

struct ProtocolInfo: Decodable, Identifiable {
    let id: String
    let name: String
    let description: String
}

struct ErrorResponse: Decodable {
    let detail: String
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case imageProcessingFailed
    case httpError(Int)
    case serverError(String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .imageProcessingFailed:
            return "Failed to process the image"
        case .httpError(let code):
            return "Server error (HTTP \(code))"
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to parse server response"
        }
    }
}
