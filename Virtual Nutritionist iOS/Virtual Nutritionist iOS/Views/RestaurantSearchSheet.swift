//
//  RestaurantSearchSheet.swift
//  Virtual Nutritionist iOS
//
//  Modal sheet for selecting which restaurant the menu is from
//

import SwiftUI
import Combine
import CoreLocation

struct RestaurantSearchSheet: View {
    let onSelect: (String, String) -> Void  // (placeId, name)
    let onSkip: () -> Void

    @StateObject private var viewModel = RestaurantSearchViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Info banner
                VStack(alignment: .leading, spacing: 8) {
                    Text("Help the community!")
                        .font(.headline)
                    Text("Link this scan to a restaurant so others can benefit from your analysis.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))

                // Search bar
                SearchBar(text: $viewModel.searchQuery)
                    .padding()

                // Location button
                if viewModel.searchQuery.isEmpty && viewModel.restaurants.isEmpty {
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
                }

                // Results
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                } else if viewModel.restaurants.isEmpty && !viewModel.searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No restaurants found")
                            .font(.headline)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else if !viewModel.restaurants.isEmpty {
                    List(viewModel.restaurants) { restaurant in
                        Button(action: {
                            onSelect(restaurant.placeId, restaurant.name)
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(restaurant.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                if !restaurant.vicinity.isEmpty {
                                    Text(restaurant.vicinity)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }

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
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("Search for Restaurant")
                            .font(.headline)

                        Text("Enter the restaurant name or use your location to find nearby restaurants")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Where is this menu from?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        onSkip()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class RestaurantSearchViewModel: NSObject, ObservableObject {
    @Published var searchQuery = ""
    @Published var restaurants: [RestaurantNearbyResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userLocation: CLLocationCoordinate2D?

    private let apiService = APIService.shared
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        locationManager.delegate = self

        // Search as user types
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if !query.isEmpty {
                    Task {
                        await self?.performSearch(query: query)
                    }
                } else {
                    self?.restaurants = []
                }
            }
            .store(in: &cancellables)
    }

    func requestLocation() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            errorMessage = "Location permission denied. Please enable in Settings."
        @unknown default:
            break
        }
    }

    func performSearch(query: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let results = try await apiService.searchRestaurants(query: query)

            // Convert to nearby format
            restaurants = results.map { searchResult in
                RestaurantNearbyResult(
                    placeId: searchResult.placeId,
                    name: searchResult.name,
                    vicinity: searchResult.address ?? "",
                    distanceMeters: 0,
                    latitude: searchResult.latitude,
                    longitude: searchResult.longitude,
                    rating: searchResult.rating,
                    priceLevel: searchResult.priceLevel,
                    cuisineType: searchResult.cuisineType,
                    photosAvailable: searchResult.photosAvailable,
                    isOpen: nil,
                    hasMenuData: searchResult.hasMenuData,
                    safeItemsCount: nil,
                    lastAnalyzed: nil
                )
            }
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            restaurants = []
        }

        isLoading = false
    }

    func searchNearby() async {
        guard let location = userLocation else { return }

        isLoading = true
        errorMessage = nil

        do {
            restaurants = try await apiService.getNearbyRestaurants(
                latitude: location.latitude,
                longitude: location.longitude,
                radiusMeters: 2000  // 2km for search
            )
        } catch {
            errorMessage = "Failed to load nearby restaurants: \(error.localizedDescription)"
            restaurants = []
        }

        isLoading = false
    }
}

// MARK: - Location Delegate

extension RestaurantSearchViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        Task { @MainActor in
            self.userLocation = location.coordinate
            await self.searchNearby()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "Location error: \(error.localizedDescription)"
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus

            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}

#Preview {
    RestaurantSearchSheet(
        onSelect: { placeId, name in
            print("Selected: \(name)")
        },
        onSkip: {
            print("Skipped")
        }
    )
}
