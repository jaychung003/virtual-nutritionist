//
//  RestaurantMapView.swift
//  Virtual Nutritionist iOS
//
//  Map view component for displaying restaurants on Google Maps
//

import SwiftUI
import GoogleMaps
import CoreLocation

struct RestaurantMapView: UIViewRepresentable {
    let restaurants: [RestaurantNearbyResult]
    let userLocation: CLLocationCoordinate2D?
    @Binding var selectedRestaurant: RestaurantNearbyResult?
    let showRedoButton: Bool
    let onCameraMove: (CLLocationCoordinate2D) -> Void
    let onRedoSearch: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> GMSMapView {
        let camera: GMSCameraPosition
        if let location = userLocation {
            camera = GMSCameraPosition.camera(
                withLatitude: location.latitude,
                longitude: location.longitude,
                zoom: 14.0
            )
        } else {
            // Default to San Francisco if no location
            camera = GMSCameraPosition.camera(
                withLatitude: 37.7749,
                longitude: -122.4194,
                zoom: 12.0
            )
        }

        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.delegate = context.coordinator
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true

        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Clear existing markers
        mapView.clear()

        // Add restaurant markers
        for restaurant in restaurants {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(
                latitude: restaurant.latitude,
                longitude: restaurant.longitude
            )
            marker.title = restaurant.name
            marker.snippet = restaurant.vicinity
            marker.userData = restaurant

            // Set marker color based on menu data freshness
            marker.icon = GMSMarker.markerImage(with: markerColor(for: restaurant))
            marker.map = mapView
        }

        // Only center on user location on first load
        if let location = userLocation, !context.coordinator.hasInitiallyPositioned {
            let camera = GMSCameraPosition.camera(
                withLatitude: location.latitude,
                longitude: location.longitude,
                zoom: 14.0
            )
            mapView.animate(to: camera)
            context.coordinator.hasInitiallyPositioned = true
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func markerColor(for restaurant: RestaurantNearbyResult) -> UIColor {
        guard restaurant.hasMenuData else {
            return .gray  // No menu data
        }

        // Calculate freshness (similar to FreshnessStatus logic)
        guard let lastAnalyzed = restaurant.lastAnalyzed else {
            return .gray
        }

        let daysSince = Calendar.current.dateComponents([.day], from: lastAnalyzed, to: Date()).day ?? 0

        if daysSince <= 7 {
            return UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)  // Green - Fresh
        } else if daysSince <= 30 {
            return UIColor(red: 0.95, green: 0.77, blue: 0.06, alpha: 1.0)  // Yellow - Stale
        } else {
            return UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)  // Red - Outdated
        }
    }

    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: RestaurantMapView
        var hasInitiallyPositioned = false

        init(_ parent: RestaurantMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let restaurant = marker.userData as? RestaurantNearbyResult {
                parent.selectedRestaurant = restaurant
            }
            return true  // Return true to prevent default behavior (centering)
        }

        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            // Deselect when tapping empty space
            parent.selectedRestaurant = nil
        }

        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            // Called when camera movement ends
            let center = CLLocationCoordinate2D(
                latitude: position.target.latitude,
                longitude: position.target.longitude
            )
            parent.onCameraMove(center)
        }
    }
}

// MARK: - Redo Search Button Overlay

struct RedoSearchButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.subheadline)
                Text("Redo search in this area")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.green)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Restaurant Info Card

struct RestaurantInfoCard: View {
    let restaurant: RestaurantNearbyResult
    let onViewDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.headline)
                        .lineLimit(2)

                    if !restaurant.vicinity.isEmpty {
                        Text(restaurant.vicinity)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        if let rating = restaurant.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .font(.subheadline)
                            }
                        }

                        if restaurant.distanceMeters > 0 {
                            Text("·")
                                .foregroundColor(.gray)
                            Text(restaurant.distanceString)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        if !restaurant.priceString.isEmpty {
                            Text("·")
                                .foregroundColor(.gray)
                            Text(restaurant.priceString)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }

                Spacer()

                // Freshness badge
                if restaurant.hasMenuData {
                    FreshnessBadge(
                        status: restaurant.freshnessStatus,
                        lastAnalyzed: lastAnalyzedDate(for: restaurant)
                    )
                }
            }

            Button(action: onViewDetails) {
                Text("View Details")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        .padding()
    }

    private func lastAnalyzedDate(for restaurant: RestaurantNearbyResult) -> Date? {
        return restaurant.lastAnalyzed
    }
}
