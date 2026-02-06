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
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let apiService = APIService.shared

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
                            if let restaurantName = scan.restaurantName {
                                Text(restaurantName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }

                            Text(scan.formattedDate)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                ForEach(scan.protocolsUsed, id: \.self) { protocol in
                                    Text(protocolDisplayName(protocol))
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

                    // Menu items section
                    Section(header: Text("Menu Items (\(scan.menuItems.count))")) {
                        ForEach(scan.menuItems, id: \.name) { item in
                            MenuItemRow(item: item)
                        }
                    }
                }
            }
        }
        .navigationTitle("Scan Details")
        .navigationBarTitleDisplayMode(.inline)
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
    let safety: String

    var body: some View {
        Text(safety.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(8)
    }

    private var backgroundColor: Color {
        switch safety.lowercased() {
        case "safe":
            return .green
        case "caution":
            return .orange
        case "avoid":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    NavigationView {
        ScanDetailView(scanId: "sample-id")
    }
}
