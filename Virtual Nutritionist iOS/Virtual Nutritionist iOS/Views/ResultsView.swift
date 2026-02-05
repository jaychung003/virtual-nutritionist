import SwiftUI

/// View displaying the analysis results for menu items
struct ResultsView: View {
    @Environment(\.dismiss) private var dismiss
    let menuItems: [MenuItem]
    
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
                // Summary header
                SummaryHeader(
                    safeCount: safeCount,
                    cautionCount: cautionCount,
                    avoidCount: avoidCount
                )
                
                // Filter tabs
                FilterTabs(selectedFilter: $selectedFilter)
                
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

/// Summary statistics header
struct SummaryHeader: View {
    let safeCount: Int
    let cautionCount: Int
    let avoidCount: Int
    
    var body: some View {
        HStack(spacing: 0) {
            SummaryItem(
                count: safeCount,
                label: "Safe",
                color: .green,
                icon: "checkmark.circle.fill"
            )
            
            Divider()
                .frame(height: 40)
            
            SummaryItem(
                count: cautionCount,
                label: "Caution",
                color: .orange,
                icon: "exclamationmark.triangle.fill"
            )
            
            Divider()
                .frame(height: 40)
            
            SummaryItem(
                count: avoidCount,
                label: "Avoid",
                color: .red,
                icon: "xmark.circle.fill"
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
    
    var body: some View {
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
    }
}

/// Filter tabs for safety categories
struct FilterTabs: View {
    @Binding var selectedFilter: ResultsView.SafetyFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
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
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color.opacity(0.2) : Color(.systemGray6))
                .foregroundStyle(isSelected ? color : .secondary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

/// Card displaying a single menu item analysis
struct MenuItemCard: View {
    let item: MenuItem
    @State private var isExpanded = false
    
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
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
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
            .buttonStyle(.plain)
            
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
    ])
}
