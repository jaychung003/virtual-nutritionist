import SwiftUI

@main
struct MenuScannerApp: App {
    @StateObject private var userProfile = UserProfile()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userProfile)
        }
    }
}
