//
//  AuthViewModel.swift
//  Virtual Nutritionist iOS
//
//  View model for managing authentication state.
//

import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = AuthService.shared

    init() {
        // Check if user is already authenticated
        isAuthenticated = authService.isAuthenticated()
    }

    // MARK: - Authentication Actions

    func register(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.register(email: email, password: password)
            currentUser = response.user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.login(email: email, password: password)
            currentUser = response.user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.logout()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refreshToken() async {
        do {
            let response = try await authService.refreshToken()
            currentUser = response.user
            isAuthenticated = true
        } catch {
            // Refresh failed - log out
            currentUser = nil
            isAuthenticated = false
        }
    }

    // MARK: - Validation Helpers

    func validateEmail(_ email: String) -> String? {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)

        if email.isEmpty {
            return "Email is required"
        } else if !emailPredicate.evaluate(with: email) {
            return "Invalid email format"
        }
        return nil
    }

    func validatePassword(_ password: String) -> String? {
        if password.isEmpty {
            return "Password is required"
        } else if password.count < 8 {
            return "Password must be at least 8 characters"
        } else if !password.contains(where: { $0.isLetter }) {
            return "Password must contain at least one letter"
        } else if !password.contains(where: { $0.isNumber }) {
            return "Password must contain at least one number"
        }
        return nil
    }

    func validatePasswordMatch(_ password: String, _ confirmPassword: String) -> String? {
        if confirmPassword.isEmpty {
            return "Please confirm your password"
        } else if password != confirmPassword {
            return "Passwords do not match"
        }
        return nil
    }
}
