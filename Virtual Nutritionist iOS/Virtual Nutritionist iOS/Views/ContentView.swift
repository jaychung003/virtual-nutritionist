import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userProfile: UserProfile
    @State private var showingCamera = false
    @State private var showingResults = false
    @State private var showingProfile = false
    @State private var capturedImage: UIImage?
    @State private var analysisResults: [MenuItem] = []
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
                    
                    Text("Menu Scanner")
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
            .sheet(isPresented: $showingResults) {
                ResultsView(menuItems: analysisResults)
            }
            .onChange(of: capturedImage) { _, newImage in
                if let image = newImage {
                    analyzeImage(image)
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
    
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        errorMessage = nil
        
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

#Preview {
    ContentView()
        .environmentObject(UserProfile())
}
