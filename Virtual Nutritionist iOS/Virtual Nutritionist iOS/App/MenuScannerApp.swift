import SwiftUI

@main
struct MenuScannerApp: App {
    @StateObject private var userProfile = UserProfile()
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(userProfile)
                    .environmentObject(authViewModel)
            } else {
                AuthContainerView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
