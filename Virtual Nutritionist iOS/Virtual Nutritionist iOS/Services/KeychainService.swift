//
//  KeychainService.swift
//  Virtual Nutritionist iOS
//
//  Secure storage for authentication tokens using iOS Keychain.
//

import Foundation
import Security

enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unknown(OSStatus)
}

class KeychainService {
    static let shared = KeychainService()

    private let service = "com.virtualnutritionist.app"

    private enum Key {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
    }

    private init() {}

    // MARK: - Access Token

    func saveAccessToken(_ token: String) throws {
        try save(token, forKey: Key.accessToken)
    }

    func getAccessToken() throws -> String? {
        try retrieve(forKey: Key.accessToken)
    }

    func deleteAccessToken() throws {
        try delete(forKey: Key.accessToken)
    }

    // MARK: - Refresh Token

    func saveRefreshToken(_ token: String) throws {
        try save(token, forKey: Key.refreshToken)
    }

    func getRefreshToken() throws -> String? {
        try retrieve(forKey: Key.refreshToken)
    }

    func deleteRefreshToken() throws {
        try delete(forKey: Key.refreshToken)
    }

    // MARK: - Clear All

    func clearAllTokens() throws {
        try? deleteAccessToken()
        try? deleteRefreshToken()
    }

    // MARK: - Private Helpers

    private func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        // Delete existing item first
        try? delete(forKey: key)

        // Add new item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }

    private func retrieve(forKey key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }

        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return value
    }

    private func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Success if deleted or item didn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
}
