//
//  CachedMenuView.swift
//  Virtual Nutritionist iOS
//
//  View for displaying cached menu analysis from the community
//

import SwiftUI

struct CachedMenuView: View {
    let placeId: String
    let restaurantName: String

    @StateObject private var viewModel = CachedMenuViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading menu...")
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error, retryAction: {
                        Task {
                            await viewModel.loadMenu(placeId: placeId)
                        }
                    })
                } else if let menuData = viewModel.menuData {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Header with freshness
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(menuData.metadata.freshnessStatus.icon)
                                        .font(.title2)
                                    VStack(alignment: .leading) {
                                        Text("Analyzed \(menuData.metadata.daysSinceScan) day\(menuData.metadata.daysSinceScan == 1 ? "" : "s") ago")
                                            .font(.headline)
                                        Text(menuData.metadata.freshnessStatus.label)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }

                                if let protocols = UserProfile.shared.selectedProtocols.map({ $0.name }).joined(separator: ", "), !protocols.isEmpty {
                                    Text("Showing all items for: \(protocols)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Text("📊 \(menuData.metadata.itemCount) items · \(menuData.metadata.totalScans) scan\(menuData.metadata.totalScans == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding()

                            // Menu items
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(menuData.menuItems) { item in
                                    MenuItemCard(item: item)
                                }
                            }
                            .padding(.horizontal)

                            // Rescan option
                            if menuData.metadata.freshnessStatus == .stale || menuData.metadata.freshnessStatus == .recent {
                                VStack(spacing: 8) {
                                    Text("Menu may have changed")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)

                                    Button(action: {
                                        // TODO: Trigger camera for rescan
                                        dismiss()
                                    }) {
                                        HStack {
                                            Image(systemName: "camera")
                                            Text("Scan New Version")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                }
                                .padding()
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(restaurantName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadMenu(placeId: placeId)
        }
    }
}

// MARK: - Menu Item Card

struct MenuItemCard: View {
    let item: CachedMenuItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.name)
                .font(.headline)

            if let description = item.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            if let price = item.price {
                Text(price)
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .cornerRadius(10)
    }
}

// MARK: - ViewModel

@MainActor
class CachedMenuViewModel: ObservableObject {
    @Published var menuData: CachedMenuResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func loadMenu(placeId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let protocols = UserProfile.shared.selectedProtocols.map { $0.id }
            menuData = try await apiService.getCachedMenu(placeId: placeId, protocols: protocols)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    CachedMenuView(placeId: "ChIJ_dQjyK-AhYARBc9DFlxcclg", restaurantName: "Nopa")
}
