//
//  OnboardingDisclaimerView.swift
//  Virtual Nutritionist iOS
//
//  Legal disclaimer shown on first app launch
//

import SwiftUI

struct OnboardingDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    let onAccept: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.orange)
                        .padding(.top, 32)

                    // Title
                    Text("Important Disclaimer")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    // Main disclaimer
                    VStack(alignment: .leading, spacing: 16) {
                        DisclaimerSection(
                            icon: "brain",
                            title: "AI-Powered Analysis",
                            description: "This app uses artificial intelligence to analyze menu items and infer their ingredients based on typical recipes and common preparations."
                        )

                        DisclaimerSection(
                            icon: "exclamationmark.triangle.fill",
                            title: "Not 100% Accurate",
                            description: "AI analysis may not detect all ingredients or cross-contamination risks. Results should be considered estimates, not definitive ingredient lists."
                        )

                        DisclaimerSection(
                            icon: "person.crop.circle.badge.exclamationmark",
                            title: "Always Verify with Staff",
                            description: "Before consuming any menu item, especially if you have severe allergies or strict dietary requirements, always confirm ingredients with restaurant staff."
                        )

                        DisclaimerSection(
                            icon: "shield.slash.fill",
                            title: "No Liability",
                            description: "The app developers are not liable for any adverse reactions or health issues that may occur from consuming foods based on this app's analysis. Use at your own risk."
                        )
                    }
                    .padding(.horizontal)

                    // Agreement section
                    VStack(spacing: 12) {
                        Text("By continuing, you acknowledge that:")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 8) {
                            CheckItem(text: "You understand this app uses AI inference")
                            CheckItem(text: "Results may not be 100% accurate")
                            CheckItem(text: "You will verify with restaurant staff")
                            CheckItem(text: "You use this app at your own risk")
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Accept button
                    Button(action: {
                        onAccept()
                        dismiss()
                    }) {
                        Text("I Understand & Accept")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled() // Prevent dismissing without accepting
        }
    }
}

struct DisclaimerSection: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct CheckItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.orange)
                .font(.caption)

            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    OnboardingDisclaimerView(onAccept: {})
}
