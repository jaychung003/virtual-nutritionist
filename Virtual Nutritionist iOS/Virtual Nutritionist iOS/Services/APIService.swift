import Foundation
import UIKit

/// Service for communicating with the backend API
class APIService {
    static let shared = APIService()
    
    /// Production backend on Render. Use a different URL for local/simulator if needed.
    private let baseURL = "https://virtual-nutritionist-1upi.onrender.com" 
    
    private init() {}
    
    /// Analyze a menu image and return safety ratings
    /// - Parameters:
    ///   - image: The captured menu image
    ///   - protocols: List of dietary protocol IDs
    /// - Returns: Array of analyzed menu items
    func analyzeMenu(image: UIImage, protocols: [String]) async throws -> [MenuItem] {
        // Prepare image
        let resizedImage = CameraService.shared.resizeImage(image, maxDimension: 1920)
        guard let imageData = CameraService.shared.compressImage(resizedImage, maxSizeKB: 2048) else {
            throw APIError.imageProcessingFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Build request
        guard let url = URL(string: "\(baseURL)/analyze-menu") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Allow time for AI processing
        
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
