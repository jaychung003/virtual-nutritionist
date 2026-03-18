import SwiftUI

/// View displaying the analysis results for menu items
struct ResultsView: View {
    @Environment(\.dismiss) private var dismiss
    let menuItems: [MenuItem]
    let contributionMessage: String?  // NEW

    @State private var selectedFilter: SafetyFilter = .all
    
    enum SafetyFilter: String, CaseIterable {
        case all = "All"
        case safe = "Safe"
        case caution = "Caution"
        case avoid = "Avoid"
    }
    
    var filteredItems: [MenuItem] {
        switch selectedFilter {
        case .all:
            return menuItems
        case .safe:
            return menuItems.filter { $0.safety == .safe }
        case .caution:
            return menuItems.filter { $0.safety == .caution }
        case .avoid:
            return menuItems.filter { $0.safety == .avoid }
        }
    }
    
    var safeCount: Int { menuItems.filter { $0.safety == .safe }.count }
    var cautionCount: Int { menuItems.filter { $0.safety == .caution }.count }
    var avoidCount: Int { menuItems.filter { $0.safety == .avoid }.count }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Combined header with summary stats and filters
                VStack(spacing: 0) {
                    // Summary header with emojis
                    SummaryHeader(
                        safeCount: safeCount,
                        cautionCount: cautionCount,
                        avoidCount: avoidCount,
                        selectedFilter: $selectedFilter
                    )

                    // Filter chips (all options in one row)
                    FilterTabs(selectedFilter: $selectedFilter)
                }
                .background(Color(.systemGray6))

                // AI Disclaimer Banner
                AIDisclaimerBanner()

                // Contribution message banner
                if let message = contributionMessage {
                    HStack {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                }
                
                // Results list
                if filteredItems.isEmpty {
                    EmptyResultsView(filter: selectedFilter)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredItems) { item in
                                MenuItemCard(item: item)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Analysis Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

/// AI Disclaimer Banner
struct AIDisclaimerBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 4) {
                Text("AI-Powered Analysis")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("This app uses AI to infer ingredients in menu items. Results may not be 100% accurate. Always verify with restaurant staff before consuming, especially for severe allergies or dietary restrictions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.orange.opacity(0.3)),
            alignment: .bottom
        )
    }
}

/// Summary statistics header with clickable filters
struct SummaryHeader: View {
    let safeCount: Int
    let cautionCount: Int
    let avoidCount: Int
    @Binding var selectedFilter: ResultsView.SafetyFilter

    var body: some View {
        HStack(spacing: 0) {
            SummaryItem(
                count: safeCount,
                label: "Safe",
                color: .green,
                icon: "checkmark.circle.fill",
                isSelected: selectedFilter == .safe,
                action: { selectedFilter = .safe }
            )

            Divider()
                .frame(height: 40)

            SummaryItem(
                count: cautionCount,
                label: "Caution",
                color: .orange,
                icon: "exclamationmark.triangle.fill",
                isSelected: selectedFilter == .caution,
                action: { selectedFilter = .caution }
            )

            Divider()
                .frame(height: 40)

            SummaryItem(
                count: avoidCount,
                label: "Avoid",
                color: .red,
                icon: "xmark.circle.fill",
                isSelected: selectedFilter == .avoid,
                action: { selectedFilter = .avoid }
            )
        }
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
    }
}

struct SummaryItem: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                    Text("\(count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(isSelected ? color.opacity(0.15) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

/// Filter tabs for safety categories
struct FilterTabs: View {
    @Binding var selectedFilter: ResultsView.SafetyFilter

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ResultsView.SafetyFilter.allCases, id: \.self) { filter in
                FilterChip(
                    title: filter.rawValue,
                    isSelected: selectedFilter == filter,
                    color: colorForFilter(filter)
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = filter
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    func colorForFilter(_ filter: ResultsView.SafetyFilter) -> Color {
        switch filter {
        case .all: return .blue
        case .safe: return .green
        case .caution: return .orange
        case .avoid: return .red
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.systemBackground))
                .foregroundStyle(isSelected ? .white : color)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(color, lineWidth: isSelected ? 0 : 1.5)
                )
                .cornerRadius(18)
        }
        .buttonStyle(.plain)
    }
}

/// Card displaying a single menu item analysis
struct MenuItemCard: View {
    let item: MenuItem
    @State private var isExpanded = false
    @State private var isBookmarked = false
    @State private var showingBookmarkAlert = false
    @State private var bookmarkError: String?

    private let apiService = APIService.shared
    private let authService = AuthService.shared

    var safetyColor: Color {
        switch item.safety {
        case .safe: return .green
        case .caution: return .orange
        case .avoid: return .red
        }
    }
    
    var safetyIcon: String {
        switch item.safety {
        case .safe: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .avoid: return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            ZStack(alignment: .trailing) {
                // Tap area for expansion (everything except bookmark button)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 12) {
                        // Safety indicator
                        Image(systemName: safetyIcon)
                            .font(.title2)
                            .foregroundStyle(safetyColor)

                        // Item name
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)

                            Text(item.safety.displayName)
                                .font(.caption)
                                .foregroundStyle(safetyColor)
                        }

                        Spacer()

                        // Expand/collapse chevron
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }

                // Bookmark button (highest priority) - only shown if feature enabled
                if FeatureFlags.bookmarksEnabled {
                    Button(action: {
                        handleBookmark()
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(isBookmarked ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(16)
                }
            }
            .alert("Sign In Required", isPresented: $showingBookmarkAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please sign in to bookmark menu items")
            }
            .alert("Error", isPresented: .constant(bookmarkError != nil)) {
                Button("OK") {
                    bookmarkError = nil
                }
            } message: {
                Text(bookmarkError ?? "")
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    // Triggers
                    if !item.triggers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trigger Ingredients")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            FlowLayout(spacing: 6) {
                                ForEach(item.triggers, id: \.self) { trigger in
                                    TriggerTag(text: trigger)
                                }
                            }
                        }
                    }
                    
                    // Notes
                    if !item.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            Text(item.notes)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(safetyColor.opacity(0.3), lineWidth: 1)
        )
    }

    private func handleBookmark() {
        // Check if user is authenticated
        guard authService.isAuthenticated() else {
            showingBookmarkAlert = true
            return
        }

        Task {
            do {
                _ = try await apiService.createBookmark(
                    menuItemName: item.name,
                    safetyRating: item.safety.rawValue,
                    triggers: item.triggers,
                    notes: item.notes,
                    restaurantName: nil
                )

                await MainActor.run {
                    isBookmarked = true
                }
            } catch {
                await MainActor.run {
                    bookmarkError = error.localizedDescription
                }
            }
        }
    }
}

struct TriggerTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.red.opacity(0.1))
            .foregroundStyle(.red)
            .cornerRadius(6)
    }
}

/// Empty state view when no items match the filter
struct EmptyResultsView: View {
    let filter: ResultsView.SafetyFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: filter == .safe ? "checkmark.circle" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text(emptyMessage)
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
    }
    
    var emptyMessage: String {
        switch filter {
        case .all:
            return "No menu items were found"
        case .safe:
            return "No safe items found.\nConsider asking the server about modifications."
        case .caution:
            return "No items flagged as caution"
        case .avoid:
            return "Great news! No items to avoid were found."
        }
    }
}

#Preview {
    ResultsView(menuItems: [
        MenuItem(
            name: "Grilled Salmon",
            safety: .safe,
            triggers: [],
            notes: "Plain grilled fish is generally safe. Ask about seasonings."
        ),
        MenuItem(
            name: "Chicken Alfredo",
            safety: .avoid,
            triggers: ["dairy (cream, parmesan)", "garlic", "wheat (pasta)"],
            notes: "Alfredo sauce contains heavy cream and typically garlic."
        ),
        MenuItem(
            name: "Garden Salad",
            safety: .caution,
            triggers: ["possible onion", "dressing may contain garlic"],
            notes: "Ask for plain olive oil and lemon instead of dressing."
        )
    ], contributionMessage: nil)
}
