import SwiftUI

@main
struct MenuScannerApp: App {
    @StateObject private var userProfile = UserProfile()
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("hasSeenOnboardingDisclaimer") private var hasSeenDisclaimer = false
    @State private var showingDisclaimer = false

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(userProfile)
                    .environmentObject(authViewModel)
                    .sheet(isPresented: $showingDisclaimer) {
                        OnboardingDisclaimerView(onAccept: {
                            hasSeenDisclaimer = true
                        })
                    }
                    .onAppear {
                        // Show disclaimer on first launch after authentication
                        if !hasSeenDisclaimer {
                            showingDisclaimer = true
                        }
                    }
            } else {
                AuthContainerView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
