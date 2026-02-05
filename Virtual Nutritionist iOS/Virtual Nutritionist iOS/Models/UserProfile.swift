import Foundation
import SwiftUI
import Combine

/// Manages user's dietary protocol preferences
class UserProfile: ObservableObject {
    @Published var selectedProtocols: [String]
    
    private let userDefaultsKey = "selectedProtocols"
    
    init() {
        // Load from UserDefaults
        if let saved = UserDefaults.standard.stringArray(forKey: userDefaultsKey) {
            self.selectedProtocols = saved
        } else {
            self.selectedProtocols = []
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
        saveToUserDefaults()
    }
    
    func isProtocolSelected(_ protocolId: String) -> Bool {
        selectedProtocols.contains(protocolId)
    }
}
