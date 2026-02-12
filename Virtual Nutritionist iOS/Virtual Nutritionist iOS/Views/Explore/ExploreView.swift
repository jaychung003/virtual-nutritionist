//
//  ExploreView.swift
//  Virtual Nutritionist iOS
//
//  Main explore tab for restaurant discovery
//

import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @State private var selectedRestaurant: RestaurantNearbyResult?
    @State private var showingDetail = false

    var body: some View {
        NavigationView {
            ZStack {
                // Always show map immediately (parallel loading with location)
                RestaurantMapView(
                    restaurants: viewModel.restaurants,
                    userLocation: viewModel.userLocation,
                    selectedRestaurant: $viewModel.selectedMapRestaurant,
                    showRedoButton: viewModel.showRedoSearchButton,
                    onCameraMove: { center in
                        viewModel.onMapCameraMoved(newCenter: center)
                    },
                    onRedoSearch: { center in
                        viewModel.redoSearchInArea(center: center)
                    }
                )

                // Loading overlay (on top of map)
                if viewModel.isLoading {
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(viewModel.userLocation == nil ? "Getting your location..." : "Finding restaurants...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            Spacer()
                        }
                        .padding(.top, 80)
                        Spacer()
                    }
                    .transition(.opacity)
                }

                // Redo search button (top center)
                if viewModel.showRedoSearchButton && !viewModel.isLoading {
                    VStack {
                        RedoSearchButton {
                            if let center = viewModel.currentMapCenter {
                                viewModel.redoSearchInArea(center: center)
                            }
                        }
                        .padding(.top, 80)  // Below search bar
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.showRedoSearchButton)
                }

                // Info card for selected restaurant
                if let selected = viewModel.selectedMapRestaurant {
                    VStack {
                        Spacer()
                        RestaurantInfoCard(restaurant: selected) {
                            selectedRestaurant = selected
                            showingDetail = true
                        }
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: viewModel.selectedMapRestaurant)
                }

                // Search bar overlay
                VStack {
                    SearchBar(text: $viewModel.searchQuery)
                        .padding()
                        .background(Color(.systemBackground).opacity(0.95))
                    Spacer()
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedRestaurant) { restaurant in
                RestaurantDetailView(placeId: restaurant.placeId)
            }
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search restaurants...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Restaurant Card

struct RestaurantCard: View {
    let restaurant: RestaurantNearbyResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.headline)

                    HStack(spacing: 4) {
                        if let rating = restaurant.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .font(.subheadline)
                            }
                        }

                        if !restaurant.priceString.isEmpty {
                            Text("·")
                                .foregroundColor(.gray)
                            Text(restaurant.priceString)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        if let cuisine = restaurant.cuisineType {
                            Text("·")
                                .foregroundColor(.gray)
                            Text(cuisine)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    if restaurant.distanceMeters > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(restaurant.distanceString)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }

                Spacer()
            }

            // Menu status badge
            FreshnessBadge(status: restaurant.freshnessStatus, lastAnalyzed: restaurant.lastAnalyzed)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Freshness Badge

struct FreshnessBadge: View {
    let status: FreshnessStatus
    let lastAnalyzed: Date?

    var body: some View {
        HStack(spacing: 6) {
            Text(status.icon)
                .font(.caption)

            if status == .none {
                Text("No menu data")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if let date = lastAnalyzed {
                let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
                Text("Menu analyzed \(days) day\(days == 1 ? "" : "s") ago")
                    .font(.caption)
                    .foregroundColor(status == .fresh ? .green : status == .recent ? .orange : .red)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            status == .none ? Color.gray.opacity(0.1) :
            status == .fresh ? Color.green.opacity(0.1) :
            status == .recent ? Color.orange.opacity(0.1) :
            Color.red.opacity(0.1)
        )
        .cornerRadius(8)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Find Safe Restaurants")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Search by name or use your location to find restaurants with menu data")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Oops!")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: retryAction) {
                Text("Retry")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
    }
}

#Preview {
    ExploreView()
}
