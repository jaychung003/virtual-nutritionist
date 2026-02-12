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
    @State private var hasAppeared = false  // Prevent auto-load on tab init

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $viewModel.searchQuery)
                    .padding()

                // Location button (only show if not searching)
                if viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.requestLocation()
                    }) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                            Text("Use My Location")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // View mode toggle (only show if we have restaurants)
                if !viewModel.restaurants.isEmpty {
                    Picker("View Mode", selection: $viewModel.viewMode) {
                        Text("List").tag(ExploreViewModel.ViewMode.list)
                        Text("Map").tag(ExploreViewModel.ViewMode.map)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading restaurants...")
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    ErrorView(message: error, retryAction: {
                        if !viewModel.searchQuery.isEmpty {
                            Task {
                                await viewModel.performSearch(query: viewModel.searchQuery)
                            }
                        } else if viewModel.userLocation != nil {
                            Task {
                                await viewModel.searchNearby()
                            }
                        }
                    })
                    Spacer()
                } else if viewModel.restaurants.isEmpty {
                    Spacer()
                    EmptyStateView()
                    Spacer()
                } else {
                    // Restaurant list or map view
                    if viewModel.viewMode == .list {
                        List(viewModel.restaurants) { restaurant in
                            Button(action: {
                                selectedRestaurant = restaurant
                                showingDetail = true
                            }) {
                                RestaurantCard(restaurant: restaurant)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .listStyle(PlainListStyle())
                    } else {
                        // Map view
                        ZStack(alignment: .bottom) {
                            RestaurantMapView(
                                restaurants: viewModel.restaurants,
                                userLocation: viewModel.userLocation,
                                selectedRestaurant: $viewModel.selectedMapRestaurant
                            )
                            .edgesIgnoringSafeArea(.bottom)

                            // Info card for selected restaurant
                            if let selected = viewModel.selectedMapRestaurant {
                                RestaurantInfoCard(restaurant: selected) {
                                    selectedRestaurant = selected
                                    showingDetail = true
                                }
                                .transition(.move(edge: .bottom))
                                .animation(.easeInOut, value: viewModel.selectedMapRestaurant)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Explore")
            .sheet(item: $selectedRestaurant) { restaurant in
                RestaurantDetailView(placeId: restaurant.placeId)
            }
            .onAppear {
                hasAppeared = true
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
