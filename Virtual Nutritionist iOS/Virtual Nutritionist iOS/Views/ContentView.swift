import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0  // Default to first tab (Scan)

    var body: some View {
        TabView(selection: $selectedTab) {
            if FeatureFlags.exploreEnabled {
                ExploreView()
                    .tabItem {
                        Label("Explore", systemImage: "magnifyingglass")
                    }
                    .tag(0)

                ScannerHomeView()
                    .tabItem {
                        Label("Scan", systemImage: "camera.fill")
                    }
                    .tag(1)

                ScanHistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            } else {
                ScannerHomeView()
                    .tabItem {
                        Label("Scan", systemImage: "camera.fill")
                    }
                    .tag(0)

                ScanHistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(1)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(2)
            }
        }
    }
}

struct ScannerHomeView: View {
    @EnvironmentObject var userProfile: UserProfile
    @State private var showingCamera = false
    @State private var showingResults = false
    @State private var showingProfile = false
    @State private var showingRestaurantSearch = false  // NEW
    @State private var capturedImage: UIImage?
    @State private var selectedRestaurant: (placeId: String, name: String)?  // NEW
    @State private var analysisResults: [MenuItem] = []
    @State private var contributionMessage: String?  // NEW
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green)
                    
                    Text("Diet Watch")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Scan menus to find safe options for your diet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Selected protocols display
                if !userProfile.selectedProtocols.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Active Protocols")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(userProfile.selectedProtocols, id: \.self) { protocolId in
                                ProtocolTag(protocolId: protocolId)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundStyle(.orange)
                        
                        Text("No dietary protocols selected")
                            .font(.headline)
                        
                        Text("Tap the settings icon to select your dietary restrictions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Scan button
                Button(action: {
                    showingCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Scan Menu")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(userProfile.selectedProtocols.isEmpty ? Color.gray : Color.green)
                    .cornerRadius(16)
                }
                .disabled(userProfile.selectedProtocols.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(capturedImage: $capturedImage)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingRestaurantSearch) {
                RestaurantSearchSheet(
                    onSelect: { placeId, name in
                        selectedRestaurant = (placeId, name)
                        if let image = capturedImage {
                            analyzeWithRestaurant(image, placeId: placeId, name: name)
                        }
                    },
                    onSkip: {
                        if let image = capturedImage {
                            analyzeAnonymously(image)
                        }
                    }
                )
            }
            .sheet(isPresented: $showingResults) {
                ResultsView(
                    menuItems: analysisResults,
                    contributionMessage: contributionMessage
                )
            }
            .onChange(of: capturedImage) { _, newImage in
                if let image = newImage {
                    if FeatureFlags.exploreEnabled {
                        // Show restaurant search for community contribution
                        showingRestaurantSearch = true
                    } else {
                        // Analyze directly without restaurant linking
                        analyzeAnonymously(image)
                    }
                }
            }
            .overlay {
                if isAnalyzing {
                    AnalyzingOverlay()
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    // Anonymous scan (no restaurant linking)
    private func analyzeAnonymously(_ image: UIImage) {
        isAnalyzing = true
        errorMessage = nil
        contributionMessage = nil

        Task {
            do {
                let results = try await APIService.shared.analyzeMenu(
                    image: image,
                    protocols: userProfile.selectedProtocols
                )

                await MainActor.run {
                    analysisResults = results
                    isAnalyzing = false
                    capturedImage = nil
                    showingResults = true
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    capturedImage = nil
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // Community contribution (linked to restaurant)
    private func analyzeWithRestaurant(_ image: UIImage, placeId: String, name: String) {
        isAnalyzing = true
        errorMessage = nil

        Task {
            do {
                let response = try await APIService.shared.analyzeRestaurantMenu(
                    placeId: placeId,
                    image: image,
                    protocols: userProfile.selectedProtocols
                )

                await MainActor.run {
                    analysisResults = response.menuItems
                    contributionMessage = "✅ Analysis saved! Other users can now see \(name) has menu data."
                    isAnalyzing = false
                    capturedImage = nil
                    selectedRestaurant = nil
                    showingResults = true
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    capturedImage = nil
                    selectedRestaurant = nil
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct AnalyzingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Analyzing menu...")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("This may take a few seconds")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }
}

struct ProtocolTag: View {
    let protocolId: String
    
    var protocolName: String {
        switch protocolId {
        case "low_fodmap": return "Low-FODMAP"
        case "scd": return "SCD"
        case "low_residue": return "Low-Residue"
        default: return protocolId
        }
    }
    
    var body: some View {
        Text(protocolName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.2))
            .foregroundStyle(.green)
            .cornerRadius(8)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
                self.size.height = y + rowHeight
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingProfile = false

    var body: some View {
        NavigationView {
            List {
                // User section
                if let user = authViewModel.currentUser {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.email)
                                .font(.headline)
                            Text("Member since \(formatDate(user.createdAt))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Dietary protocols
                Section(header: Text("Dietary Protocols")) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        HStack {
                            Text("Manage Protocols")
                            Spacer()
                            Text("\(userProfile.selectedProtocols.count) selected")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                // My Data section
                Section(header: Text("My Data")) {
                    NavigationLink(destination: BookmarksView()) {
                        Label("Bookmarks", systemImage: "bookmark.fill")
                    }
                }

                // Account actions
                Section {
                    Button(role: .destructive, action: {
                        Task {
                            await authViewModel.logout()
                        }
                    }) {
                        if authViewModel.isLoading {
                            HStack {
                                ProgressView()
                                Text("Logging out...")
                            }
                        } else {
                            Text("Log Out")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
        }
    }

    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return isoString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserProfile())
        .environmentObject(AuthViewModel())
}
