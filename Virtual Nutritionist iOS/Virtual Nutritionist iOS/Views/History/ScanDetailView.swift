//
//  ScanDetailView.swift
//  Virtual Nutritionist iOS
//
//  View for displaying full scan details.
//

import SwiftUI

struct ScanDetailView: View {
    let scanId: String

    @State private var scan: ScanDetailResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedFilter: SafetyFilter = .all
    @State private var showFullScreenImage = false
    @Environment(\.dismiss) private var dismiss

    private let apiService = APIService.shared

    enum SafetyFilter: String, CaseIterable {
        case all = "All"
        case safe = "Safe"
        case caution = "Caution"
        case avoid = "Avoid"
    }

    var filteredMenuItems: [MenuItem] {
        guard let scan = scan else { return [] }

        switch selectedFilter {
        case .all:
            return scan.menuItems
        case .safe:
            return scan.menuItems.filter { $0.safety == .safe }
        case .caution:
            return scan.menuItems.filter { $0.safety == .caution }
        case .avoid:
            return scan.menuItems.filter { $0.safety == .avoid }
        }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let errorMessage = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)

                    Button("Retry") {
                        Task {
                            await loadScanDetail()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if let scan = scan {
                List {
                    // Header section
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            // Menu image thumbnail (if available)
                            if let imageData = scan.imageData,
                               let data = Data(base64Encoded: imageData),
                               let uiImage = UIImage(data: data) {
                                Button(action: {
                                    showFullScreenImage = true
                                }) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 150)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }

                            if let restaurantName = scan.restaurantName {
                                Text(restaurantName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }

                            Text(scan.formattedDate)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                ForEach(scan.protocolsUsed, id: \.self) { dietaryProtocol in
                                    Text(protocolDisplayName(dietaryProtocol))
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Filter section
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(SafetyFilter.allCases, id: \.self) { filter in
                                    FilterButton(
                                        title: filter.rawValue,
                                        count: countForFilter(filter),
                                        isSelected: selectedFilter == filter,
                                        color: colorForFilter(filter)
                                    ) {
                                        withAnimation {
                                            selectedFilter = filter
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }

                    // Menu items section
                    Section(header: Text("Menu Items (\(filteredMenuItems.count))")) {
                        if filteredMenuItems.isEmpty {
                            Text("No items match this filter")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                                .padding()
                        } else {
                            ForEach(filteredMenuItems, id: \.name) { item in
                                MenuItemRow(item: item)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Scan Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFullScreenImage) {
            if let scan = scan,
               let imageData = scan.imageData,
               let data = Data(base64Encoded: imageData),
               let uiImage = UIImage(data: data) {
                FullScreenImageView(image: uiImage)
            }
        }
        .task {
            await loadScanDetail()
        }
    }

    private func loadScanDetail() async {
        isLoading = true
        errorMessage = nil

        do {
            scan = try await apiService.getScanDetail(scanId: scanId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func protocolDisplayName(_ id: String) -> String {
        switch id {
        case "low_fodmap": return "Low-FODMAP"
        case "scd": return "SCD"
        case "low_residue": return "Low-Residue"
        default: return id
        }
    }

    private func countForFilter(_ filter: SafetyFilter) -> Int {
        guard let scan = scan else { return 0 }

        switch filter {
        case .all:
            return scan.menuItems.count
        case .safe:
            return scan.menuItems.filter { $0.safety == .safe }.count
        case .caution:
            return scan.menuItems.filter { $0.safety == .caution }.count
        case .avoid:
            return scan.menuItems.filter { $0.safety == .avoid }.count
        }
    }

    private func colorForFilter(_ filter: SafetyFilter) -> Color {
        switch filter {
        case .all:
            return .blue
        case .safe:
            return .green
        case .caution:
            return .orange
        case .avoid:
            return .red
        }
    }
}

struct FilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct MenuItemRow: View {
    let item: MenuItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.headline)

                Spacer()

                SafetyBadge(safety: item.safety)
            }

            if !item.triggers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Triggers:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(item.triggers, id: \.self) { trigger in
                        Text("• \(trigger)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            if !item.notes.isEmpty {
                Text(item.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SafetyBadge: View {
    let safety: SafetyRating

    var body: some View {
        Text(safety.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(8)
    }

    private var backgroundColor: Color {
        switch safety {
        case .safe:
            return .green
        case .caution:
            return .orange
        case .avoid:
            return .red
        }
    }
}

struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                // Reset if zoomed out too far
                                if scale < 1.0 {
                                    withAnimation {
                                        scale = 1.0
                                        lastScale = 1.0
                                    }
                                }
                                // Limit max zoom
                                if scale > 5.0 {
                                    withAnimation {
                                        scale = 5.0
                                        lastScale = 5.0
                                    }
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        // Double tap to reset zoom
                        withAnimation {
                            scale = 1.0
                            lastScale = 1.0
                        }
                    }
            }
            .navigationTitle("Menu Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ScanDetailView(scanId: "sample-id")
    }
}
