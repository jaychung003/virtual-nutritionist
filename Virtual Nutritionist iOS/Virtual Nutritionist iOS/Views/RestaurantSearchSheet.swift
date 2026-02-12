//
//  RestaurantSearchSheet.swift
//  Virtual Nutritionist iOS
//
//  Bottom sheet for selecting which restaurant the menu is from
//  Features smart suggestions, expandable search, and personal benefit messaging
//

import SwiftUI
import Combine
import CoreLocation

struct RestaurantSearchSheet: View {
    let onSelect: (String, String) -> Void  // (placeId, name)
    let onSkip: () -> Void

    @StateObject private var viewModel = RestaurantSearchViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showSkipConfirmation = false
    @State private var showSearch = false

    var body: some View {
        Group {
            if FeatureFlags.smartRestaurantSuggestions {
                bottomSheetView
            } else {
                legacyView
            }
        }
    }

    // MARK: - New Bottom Sheet Design

    private var bottomSheetView: some View {
        VStack(spacing: 0) {
            // Drag handle
            DragHandle()

            ScrollView {
                VStack(spacing: 16) {
                    // Title - conversational
                    Text("Where did you take this?")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Auto-selected restaurant (high confidence mode)
                    if let topSuggestion = viewModel.topSuggestions.first,
                       topSuggestion.distanceMeters < 50 {
                        autoSelectedSection(topSuggestion: topSuggestion)
                    } else {
                        // Regular suggestions
                        suggestionsSection
                    }

                    // Expandable search
                    expandableSearchSection

                    // Skip link (low prominence)
                    Button(action: {
                        showSkipConfirmation = true
                    }) {
                        Text("Not sure? Skip")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .onAppear {
            viewModel.loadSmartSuggestions()
        }
        .alert("Skip restaurant selection?", isPresented: $showSkipConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Skip", role: .destructive) {
                onSkip()
                dismiss()
            }
        } message: {
            Text("You won't see if this restaurant has analyzed menu items for your diet.")
        }
    }

    // MARK: - Auto-Selected Section (High Confidence)

    private func autoSelectedSection(topSuggestion: RestaurantNearbyResult) -> some View {
        VStack(spacing: 16) {
            // Pre-selected card with emphasis
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                    Text("Are you at this restaurant?")
                        .font(.headline)
                    Spacer()
                }

                // Prominent selected card
                Button(action: {
                    onSelect(topSuggestion.placeId, topSuggestion.name)
                    dismiss()
                }) {
                    RestaurantSuggestionCard(restaurant: topSuggestion, isSelected: true)
                }
                .buttonStyle(PlainButtonStyle())

                // Primary action button
                Button(action: {
                    onSelect(topSuggestion.placeId, topSuggestion.name)
                    dismiss()
                }) {
                    Text("Yes, I'm at \(topSuggestion.name)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.green.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal)

            // Alternative suggestions
            if viewModel.topSuggestions.count > 1 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Or choose a different restaurant:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    ForEach(viewModel.topSuggestions.dropFirst().prefix(2)) { restaurant in
                        Button(action: {
                            onSelect(restaurant.placeId, restaurant.name)
                            dismiss()
                        }) {
                            RestaurantSuggestionCard(restaurant: restaurant)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Regular Suggestions Section

    private var suggestionsSection: some View {
        VStack(spacing: 12) {
            if viewModel.isLoadingSuggestions {
                ProgressView("Finding nearby restaurants...")
                    .padding()
            } else if viewModel.topSuggestions.isEmpty && viewModel.userLocation != nil {
                VStack(spacing: 12) {
                    Image(systemName: "location.slash")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No restaurants found nearby")
                        .font(.headline)
                    Text("Try expanding search below")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
            } else if viewModel.userLocation == nil && !viewModel.isLoadingSuggestions {
                // No location permission
                VStack(spacing: 12) {
                    Image(systemName: "location.circle")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Enable location for suggestions")
                        .font(.headline)
                    Button(action: {
                        viewModel.requestLocation()
                    }) {
                        Text("Enable Location")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
            } else {
                // Show suggestions
                let suggestionCount = viewModel.topSuggestions.first?.distanceMeters ?? 999 < 50 ? 3 : 5
                ForEach(viewModel.topSuggestions.prefix(suggestionCount)) { restaurant in
                    Button(action: {
                        onSelect(restaurant.placeId, restaurant.name)
                        dismiss()
                    }) {
                        RestaurantSuggestionCard(restaurant: restaurant)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Expandable Search Section

    private var expandableSearchSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation {
                    showSearch.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Search for restaurant")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: showSearch ? "chevron.up" : "chevron.down")
                }
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)

            if showSearch {
                VStack(spacing: 12) {
                    SearchBar(text: $viewModel.searchQuery)
                        .padding(.horizontal)

                    // Search results
                    if viewModel.isLoading {
                        ProgressView("Searching...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundColor(.red)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.title)
                                .foregroundColor(.gray)
                            Text("No restaurants found")
                                .font(.headline)
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else if !viewModel.searchResults.isEmpty {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.searchResults.prefix(10)) { restaurant in
                                Button(action: {
                                    onSelect(restaurant.placeId, restaurant.name)
                                    dismiss()
                                }) {
                                    RestaurantSuggestionCard(restaurant: restaurant)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                        .frame(maxHeight: 400)
                    }
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Legacy View (Old Modal Design)

    private var legacyView: some View {
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
                            HStack(spacing: 12) {
                                // Restaurant info
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

                                Spacer()

                                // Distance badge
                                if restaurant.distanceMeters > 0 {
                                    Text(restaurant.distanceString)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
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
    @Published var searchResults: [RestaurantNearbyResult] = []
    @Published var topSuggestions: [RestaurantNearbyResult] = []
    @Published var isLoading = false
    @Published var isLoadingSuggestions = false
    @Published var errorMessage: String?
    @Published var userLocation: CLLocationCoordinate2D?

    private let apiService = APIService.shared
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private let cacheKey = "restaurant_suggestions_cache"
    private let cacheExpirationSeconds: TimeInterval = 300 // 5 minutes

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
                    self?.searchResults = []
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Smart Suggestions

    func loadSmartSuggestions() {
        // Try to load from cache first
        if let cached = loadCachedSuggestions() {
            topSuggestions = cached
            return
        }

        // Request location and fetch suggestions
        requestLocation()
    }

    func requestLocation() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            errorMessage = nil // Don't show error, just show "Enable location" message
        @unknown default:
            break
        }
    }

    private func fetchNearbyQuick() async {
        guard let location = userLocation else { return }

        isLoadingSuggestions = true
        errorMessage = nil

        do {
            // Use optimized nearby search (500m radius, limit 10)
            let nearby = try await apiService.getNearbyRestaurants(
                latitude: location.latitude,
                longitude: location.longitude,
                radiusMeters: 500,
                limit: 10
            )

            // Rank suggestions
            let ranked = rankRestaurants(nearby)
            topSuggestions = ranked

            // Cache suggestions
            cacheSuggestions(ranked, location: location)
        } catch {
            // Don't show error for suggestions - just fall back to search
            topSuggestions = []
        }

        isLoadingSuggestions = false
    }

    func rankRestaurants(_ restaurants: [RestaurantNearbyResult]) -> [RestaurantNearbyResult] {
        return restaurants.sorted { r1, r2 in
            // Priority 1: Distance (closest first)
            if abs(r1.distanceMeters - r2.distanceMeters) > 50 {
                return r1.distanceMeters < r2.distanceMeters
            }

            // Priority 2: Has menu data (prefer restaurants with existing analysis)
            if r1.hasMenuData != r2.hasMenuData {
                return r1.hasMenuData
            }

            // Priority 3: Rating (higher rated more likely)
            return (r1.rating ?? 0) > (r2.rating ?? 0)
        }
    }

    // MARK: - Caching

    private struct SuggestionCache: Codable {
        let suggestions: [RestaurantNearbyResult]
        let latitude: Double
        let longitude: Double
        let timestamp: Date
    }

    private func cacheSuggestions(_ suggestions: [RestaurantNearbyResult], location: CLLocationCoordinate2D) {
        let cache = SuggestionCache(
            suggestions: suggestions,
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: Date()
        )

        if let encoded = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }

    private func loadCachedSuggestions() -> [RestaurantNearbyResult]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cache = try? JSONDecoder().decode(SuggestionCache.self, from: data)
        else { return nil }

        // Check if cache is still valid (5 minutes)
        let age = Date().timeIntervalSince(cache.timestamp)
        guard age < cacheExpirationSeconds else { return nil }

        // Check if user hasn't moved significantly (100m)
        if let currentLocation = userLocation {
            let cacheLocation = CLLocation(latitude: cache.latitude, longitude: cache.longitude)
            let currentCLLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            let distance = cacheLocation.distance(from: currentCLLocation)

            guard distance < 100 else { return nil }
        }

        return cache.suggestions
    }

    // MARK: - Search

    func performSearch(query: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let results = try await apiService.searchRestaurants(query: query)

            // Convert to nearby format
            searchResults = results.map { searchResult in
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
            searchResults = []
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
                radiusMeters: 1609  // 1 mile, sorted by distance (closest first)
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
            await self.fetchNearbyQuick()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            // Don't show error - just gracefully degrade to search mode
            self.userLocation = nil
            self.isLoadingSuggestions = false
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
