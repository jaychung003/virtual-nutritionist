//
//  ExploreViewModel.swift
//  Virtual Nutritionist iOS
//
//  ViewModel for restaurant discovery and exploration
//

import Foundation
import CoreLocation
import Combine

@MainActor
class ExploreViewModel: NSObject, ObservableObject {
    @Published var searchQuery = ""
    @Published var restaurants: [RestaurantNearbyResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedRestaurant: RestaurantDetail?

    @Published var userLocation: CLLocationCoordinate2D?
    @Published var locationPermissionDenied = false

    private let apiService = APIService.shared
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private weak var userProfile: UserProfile?

    init(userProfile: UserProfile? = nil) {
        self.userProfile = userProfile
        super.init()
        locationManager.delegate = self

        // Search as user types (with debounce)
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if !query.isEmpty {
                    Task {
                        await self?.performSearch(query: query)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Location

    func requestLocation() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            locationPermissionDenied = true
        @unknown default:
            break
        }
    }

    // MARK: - Search

    func performSearch(query: String) async {
        guard !query.isEmpty else {
            restaurants = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let results = try await apiService.searchRestaurants(query: query)

            // Convert search results to nearby format for display
            // Note: This is a simplification - in production you'd want different views
            restaurants = results.map { searchResult in
                RestaurantNearbyResult(
                    placeId: searchResult.placeId,
                    name: searchResult.name,
                    vicinity: searchResult.address ?? "",
                    distanceMeters: 0, // Unknown for search results
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
        }

        isLoading = false
    }

    func searchNearby() async {
        guard let location = userLocation else {
            errorMessage = "Location not available"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Get user's active protocols for filtering
            let protocols = userProfile?.selectedProtocols ?? []

            restaurants = try await apiService.getNearbyRestaurants(
                latitude: location.latitude,
                longitude: location.longitude,
                radiusMeters: 5000,
                protocols: protocols
            )
        } catch {
            errorMessage = "Failed to load nearby restaurants: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Restaurant Details

    func loadRestaurantDetails(placeId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            selectedRestaurant = try await apiService.getRestaurantDetails(placeId: placeId)
        } catch {
            errorMessage = "Failed to load restaurant details: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - CLLocationManagerDelegate

extension ExploreViewModel: CLLocationManagerDelegate {
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

            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationPermissionDenied = false
                manager.requestLocation()
            case .denied, .restricted:
                self.locationPermissionDenied = true
            default:
                break
            }
        }
    }
}
