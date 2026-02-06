import Foundation
import SwiftUI
import Combine

/// Manages user's dietary protocol preferences
class UserProfile: ObservableObject {
    @Published var selectedProtocols: [String]
    @Published var isSyncing = false
    @Published var syncError: String?

    private let userDefaultsKey = "selectedProtocols"
    private let apiService = APIService.shared
    private let authService = AuthService.shared

    init() {
        // Load from UserDefaults
        if let saved = UserDefaults.standard.stringArray(forKey: userDefaultsKey) {
            self.selectedProtocols = saved
        } else {
            self.selectedProtocols = []
        }

        // Sync from backend if authenticated
        Task {
            await syncFromBackend()
        }
    }

    private func saveToUserDefaults() {
        UserDefaults.standard.set(selectedProtocols, forKey: userDefaultsKey)
    }

    func toggleProtocol(_ protocolId: String) {
        if selectedProtocols.contains(protocolId) {
            selectedProtocols.removeAll { $0 == protocolId }
        } else {
            selectedProtocols.append(protocolId)
        }

        // Save locally first
        saveToUserDefaults()

        // Sync to backend if authenticated
        Task {
            await syncToBackend()
        }
    }

    func isProtocolSelected(_ protocolId: String) -> Bool {
        selectedProtocols.contains(protocolId)
    }

    // MARK: - Backend Sync

    @MainActor
    func syncFromBackend() async {
        // Only sync if authenticated
        guard authService.isAuthenticated() else {
            return
        }

        isSyncing = true
        syncError = nil

        do {
            let profile = try await apiService.getProfile()
            selectedProtocols = profile.preferences.selectedProtocols

            // Update UserDefaults as well
            saveToUserDefaults()
        } catch {
            // Silently fail - use local data
            syncError = "Failed to sync preferences from cloud"
            print("Sync from backend failed: \(error.localizedDescription)")
        }

        isSyncing = false
    }

    @MainActor
    func syncToBackend() async {
        // Only sync if authenticated
        guard authService.isAuthenticated() else {
            return
        }

        do {
            _ = try await apiService.updatePreferences(protocols: selectedProtocols)
            syncError = nil
        } catch {
            // Silently fail - local changes are saved
            syncError = "Failed to sync preferences to cloud"
            print("Sync to backend failed: \(error.localizedDescription)")
        }
    }
}
