//
//  RestaurantSuggestionCard.swift
//  Virtual Nutritionist iOS
//
//  Card component for displaying restaurant suggestions
//

import SwiftUI

struct RestaurantSuggestionCard: View {
    let restaurant: RestaurantNearbyResult
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Restaurant icon (green for data, gray for no data)
            Image(systemName: "fork.knife.circle.fill")
                .font(.title2)
                .foregroundColor(restaurant.hasMenuData ? .green : .gray)

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    if let cuisine = restaurant.cuisineType {
                        Text(cuisine)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("·")
                            .foregroundColor(.secondary)
                    }
                    Text(restaurant.distanceString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Value signal badge
                if restaurant.hasMenuData, let safeCount = restaurant.safeItemsCount, safeCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(safeCount) safe item\(safeCount == 1 ? "" : "s")")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
                } else if !restaurant.hasMenuData {
                    // Opportunity badge
                    HStack(spacing: 4) {
                        Image(systemName: "star.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Be the first to scan!")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }

            Spacer()

            // Distance badge (smaller, secondary)
            Text(restaurant.distanceString)
                .font(.caption2)
                .foregroundColor(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        // Restaurant with data
        RestaurantSuggestionCard(
            restaurant: RestaurantNearbyResult(
                placeId: "1",
                name: "Chipotle",
                vicinity: "123 Main St",
                distanceMeters: 50,
                latitude: 0,
                longitude: 0,
                rating: 4.5,
                priceLevel: 2,
                cuisineType: "Mexican",
                photosAvailable: true,
                isOpen: true,
                hasMenuData: true,
                safeItemsCount: 12,
                lastAnalyzed: Date()
            )
        )

        // Restaurant without data
        RestaurantSuggestionCard(
            restaurant: RestaurantNearbyResult(
                placeId: "2",
                name: "Panera Bread",
                vicinity: "456 Oak Ave",
                distanceMeters: 200,
                latitude: 0,
                longitude: 0,
                rating: 4.2,
                priceLevel: 2,
                cuisineType: "American",
                photosAvailable: true,
                isOpen: true,
                hasMenuData: false,
                safeItemsCount: nil,
                lastAnalyzed: nil
            )
        )

        // Selected state
        RestaurantSuggestionCard(
            restaurant: RestaurantNearbyResult(
                placeId: "3",
                name: "Sweetgreen",
                vicinity: "789 Elm St",
                distanceMeters: 150,
                latitude: 0,
                longitude: 0,
                rating: 4.7,
                priceLevel: 2,
                cuisineType: "Salads",
                photosAvailable: true,
                isOpen: true,
                hasMenuData: true,
                safeItemsCount: 8,
                lastAnalyzed: Date()
            ),
            isSelected: true
        )
    }
    .padding()
}
