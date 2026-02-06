//
//  AuthService.swift
//  Virtual Nutritionist iOS
//
//  Authentication service for user registration, login, and token management.
//

import Foundation

enum AuthError: LocalizedError {
    case invalidResponse
    case networkError(Error)
    case serverError(String)
    case unauthorized
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Unauthorized access"
        case .invalidCredentials:
            return "Invalid email or password"
        }
    }
}

class AuthService {
    static let shared = AuthService()

    private let baseURL = "https://virtual-nutritionist.onrender.com"
    private let keychain = KeychainService.shared

    private init() {}

    // MARK: - Public Methods

    func register(email: String, password: String) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/auth/register"

        let body: [String: Any] = [
            "email": email,
            "password": password
        ]

        let data = try await performRequest(url: endpoint, method: "POST", body: body)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)

        // Save tokens to keychain
        try keychain.saveAccessToken(response.accessToken)
        try keychain.saveRefreshToken(response.refreshToken)

        return response
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/auth/login"

        let body: [String: Any] = [
            "email": email,
            "password": password
        ]

        let data = try await performRequest(url: endpoint, method: "POST", body: body)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)

        // Save tokens to keychain
        try keychain.saveAccessToken(response.accessToken)
        try keychain.saveRefreshToken(response.refreshToken)

        return response
    }

    func refreshToken() async throws -> AuthResponse {
        guard let refreshToken = try keychain.getRefreshToken() else {
            throw AuthError.unauthorized
        }

        let endpoint = "\(baseURL)/auth/refresh"

        let body: [String: Any] = [
            "refresh_token": refreshToken
        ]

        let data = try await performRequest(url: endpoint, method: "POST", body: body)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)

        // Save new tokens to keychain
        try keychain.saveAccessToken(response.accessToken)
        try keychain.saveRefreshToken(response.refreshToken)

        return response
    }

    func logout() async throws {
        guard let refreshToken = try keychain.getRefreshToken() else {
            // Already logged out
            try keychain.clearAllTokens()
            return
        }

        let endpoint = "\(baseURL)/auth/logout"

        let body: [String: Any] = [
            "refresh_token": refreshToken
        ]

        // Call logout endpoint (ignore errors - clear tokens anyway)
        try? await performRequest(url: endpoint, method: "POST", body: body)

        // Clear tokens from keychain
        try keychain.clearAllTokens()
    }

    func isAuthenticated() -> Bool {
        // Check if we have tokens stored
        guard let accessToken = try? keychain.getAccessToken(),
              !accessToken.isEmpty else {
            return false
        }
        return true
    }

    // MARK: - Private Helpers

    private func performRequest(url: String, method: String, body: [String: Any]? = nil, requiresAuth: Bool = false) async throws -> Data {
        guard let requestURL = URL(string: url) else {
            throw AuthError.invalidResponse
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authorization header if required
        if requiresAuth {
            guard let accessToken = try keychain.getAccessToken() else {
                throw AuthError.unauthorized
            }
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        // Add body if present
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }

            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw AuthError.unauthorized
            case 400...499:
                // Try to parse error message from response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let detail = json["detail"] as? String {
                    throw AuthError.serverError(detail)
                }
                throw AuthError.invalidCredentials
            default:
                throw AuthError.serverError("Server error: \(httpResponse.statusCode)")
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
}
