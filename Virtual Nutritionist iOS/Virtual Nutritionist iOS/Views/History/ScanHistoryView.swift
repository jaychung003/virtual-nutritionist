//
//  ScanHistoryView.swift
//  Virtual Nutritionist iOS
//
//  View for displaying scan history list.
//

import SwiftUI

struct ScanHistoryView: View {
    @State private var scans: [ScanItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedScan: ScanItem?

    private let apiService = APIService.shared

    var body: some View {
        NavigationView {
            Group {
                if isLoading && scans.isEmpty {
                    ProgressView("Loading history...")
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
                                await loadScans()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if scans.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No scan history yet")
                            .font(.title3)
                            .fontWeight(.medium)

                        Text("Scanned menus will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(scans) { scan in
                            NavigationLink(
                                destination: ScanDetailView(scanId: scan.id),
                                tag: scan,
                                selection: $selectedScan
                            ) {
                                ScanHistoryRow(scan: scan)
                            }
                        }
                        .onDelete(perform: deleteScans)
                    }
                    .refreshable {
                        await loadScans()
                    }
                }
            }
            .navigationTitle("Scan History")
            .toolbar {
                if !scans.isEmpty {
                    EditButton()
                }
            }
            .task {
                await loadScans()
            }
        }
    }

    private func loadScans() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.getScanHistory()
            scans = response.scans
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func deleteScans(at offsets: IndexSet) {
        for index in offsets {
            let scan = scans[index]

            Task {
                do {
                    try await apiService.deleteScan(scanId: scan.id)
                    await MainActor.run {
                        scans.remove(at: index)
                    }
                } catch {
                    print("Failed to delete scan: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct ScanHistoryRow: View {
    let scan: ScanItem

    var body: some View {
        HStack(spacing: 12) {
            // Left side: Date icon
            VStack {
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }

            // Right side: Content
            VStack(alignment: .leading, spacing: 6) {
                // Primary: Date and time
                Text(scan.detailedDateTime)
                    .font(.headline)
                    .foregroundColor(.primary)

                // Secondary: Restaurant name and item count
                HStack(spacing: 8) {
                    if let restaurantName = scan.restaurantName {
                        Text(restaurantName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("\(scan.itemCount) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }

                // Protocols
                if !scan.protocolsUsed.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(scan.protocolsUsed, id: \.self) { dietaryProtocol in
                            Text(protocolDisplayName(dietaryProtocol))
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
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

#Preview {
    ScanHistoryView()
}
