//
//  RestaurantDetailView.swift
//  Virtual Nutritionist iOS
//
//  Detail view for a restaurant with menu viewing and scanning options
//

import SwiftUI
import Combine

struct RestaurantDetailView: View {
    let placeId: String

    @StateObject private var viewModel = RestaurantDetailViewModel()
    @State private var showingCachedMenu = false
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisResults: [MenuItem] = []
    @State private var showingResults = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfile: UserProfile

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error, retryAction: {
                        Task {
                            await viewModel.loadDetails(placeId: placeId)
                        }
                    })
                } else if let restaurant = viewModel.restaurant {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text(restaurant.name)
                                    .font(.title)
                                    .fontWeight(.bold)

                                if let rating = restaurant.rating {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", rating))
                                        if let total = restaurant.userRatingsTotal {
                                            Text("(\(total) reviews)")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }

                                Text(restaurant.address)
                                    .foregroundColor(.gray)

                                HStack {
                                    if !restaurant.priceString.isEmpty {
                                        Text(restaurant.priceString)
                                            .foregroundColor(.gray)
                                    }
                                    if let cuisine = restaurant.cuisineType {
                                        Text("·")
                                            .foregroundColor(.gray)
                                        Text(cuisine)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()

                            Divider()

                            // Menu status
                            if restaurant.hasMenuData {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(restaurant.freshnessStatus.icon)
                                            .font(.title2)
                                        VStack(alignment: .leading) {
                                            Text("Menu Analyzed")
                                                .font(.headline)
                                            if let lastAnalyzed = restaurant.lastAnalyzed {
                                                let days = Calendar.current.dateComponents([.day], from: lastAnalyzed, to: Date()).day ?? 0
                                                Text("\(days) day\(days == 1 ? "" : "s") ago · \(restaurant.freshnessStatus.label)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        Spacer()
                                    }

                                    if let count = restaurant.menuItemCount {
                                        Text("📊 \(count) items analyzed")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }

                                    // Primary action: View menu
                                    Button(action: {
                                        showingCachedMenu = true
                                    }) {
                                        HStack {
                                            Image(systemName: "list.bullet.rectangle")
                                            Text("View Safe Menu Items")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(10)
                                    }

                                    // Secondary action: Scan new
                                    Button(action: {
                                        showingCamera = true
                                    }) {
                                        HStack {
                                            Image(systemName: "camera")
                                            Text("Scan New Menu")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                }
                                .padding()
                            } else {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("⚪")
                                            .font(.title2)
                                        VStack(alignment: .leading) {
                                            Text("No Menu Data")
                                                .font(.headline)
                                            Text("Be the first to scan!")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }

                                    Button(action: {
                                        showingCamera = true
                                    }) {
                                        HStack {
                                            Image(systemName: "camera.fill")
                                            Text("Be First to Scan Menu")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                    }
                                }
                                .padding()
                            }

                            Divider()

                            // Contact info
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About")
                                    .font(.headline)

                                if let phone = restaurant.phone {
                                    Button(action: {
                                        if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "phone.fill")
                                            Text(phone)
                                        }
                                    }
                                }

                                if let website = restaurant.website {
                                    Button(action: {
                                        if let url = URL(string: website) {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "globe")
                                            Text("Website")
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCachedMenu) {
                if let restaurant = viewModel.restaurant {
                    CachedMenuView(placeId: restaurant.placeId, restaurantName: restaurant.name)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(capturedImage: $capturedImage)
            }
            .sheet(isPresented: $showingResults) {
                ResultsView(
                    menuItems: analysisResults,
                    contributionMessage: "✅ Analysis saved to community for \(viewModel.restaurant?.name ?? "this restaurant")!"
                )
            }
            .onChange(of: capturedImage) { _, newImage in
                if let image = newImage, let restaurant = viewModel.restaurant {
                    analyzeForRestaurant(image: image, placeId: restaurant.placeId)
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
        .task {
            await viewModel.loadDetails(placeId: placeId)
        }
    }

    private func analyzeForRestaurant(image: UIImage, placeId: String) {
        isAnalyzing = true
        errorMessage = nil

        Task {
            do {
                let response = try await APIService.shared.analyzeRestaurantMenu(
                    placeId: placeId,
                    image: image,
                    protocols: userProfile.selectedProtocols
                )

                await MainActor.run {
                    analysisResults = response.menuItems
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

// MARK: - ViewModel

@MainActor
class RestaurantDetailViewModel: ObservableObject {
    @Published var restaurant: RestaurantDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func loadDetails(placeId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            restaurant = try await apiService.getRestaurantDetails(placeId: placeId)
        } catch {
            errorMessage = "Failed to load restaurant: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
