//
//  User.swift
//  Virtual Nutritionist iOS
//
//  User model for authenticated users.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case user
    }
}

struct ProfileResponse: Codable {
    let id: String
    let email: String
    let createdAt: String
    let preferences: UserPreferencesData

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case preferences
    }
}

struct UserPreferencesData: Codable {
    let selectedProtocols: [String]
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case selectedProtocols = "selected_protocols"
        case updatedAt = "updated_at"
    }
}
