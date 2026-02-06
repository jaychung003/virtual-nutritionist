//
//  BookmarksView.swift
//  Virtual Nutritionist iOS
//
//  View for displaying bookmarked menu items.
//

import SwiftUI

struct BookmarksView: View {
    @State private var bookmarks: [BookmarkResponse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFilter: String? = nil

    private let apiService = APIService.shared

    var body: some View {
        NavigationView {
            Group {
                if isLoading && bookmarks.isEmpty {
                    ProgressView("Loading bookmarks...")
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)

                        Button("Retry") {
                            Task {
                                await loadBookmarks()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if bookmarks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No bookmarks yet")
                            .font(.title3)
                            .fontWeight(.medium)

                        Text("Bookmark your favorite menu items for quick access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        // Group by safety rating
                        if !safeBookmarks.isEmpty {
                            Section(header: Text("Safe")) {
                                ForEach(safeBookmarks) { bookmark in
                                    BookmarkRow(bookmark: bookmark)
                                }
                                .onDelete { indexSet in
                                    deleteBookmarks(at: indexSet, from: safeBookmarks)
                                }
                            }
                        }

                        if !cautionBookmarks.isEmpty {
                            Section(header: Text("Caution")) {
                                ForEach(cautionBookmarks) { bookmark in
                                    BookmarkRow(bookmark: bookmark)
                                }
                                .onDelete { indexSet in
                                    deleteBookmarks(at: indexSet, from: cautionBookmarks)
                                }
                            }
                        }

                        if !avoidBookmarks.isEmpty {
                            Section(header: Text("Avoid")) {
                                ForEach(avoidBookmarks) { bookmark in
                                    BookmarkRow(bookmark: bookmark)
                                }
                                .onDelete { indexSet in
                                    deleteBookmarks(at: indexSet, from: avoidBookmarks)
                                }
                            }
                        }
                    }
                    .refreshable {
                        await loadBookmarks()
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .toolbar {
                if !bookmarks.isEmpty {
                    EditButton()
                }
            }
            .task {
                await loadBookmarks()
            }
        }
    }

    private var safeBookmarks: [BookmarkResponse] {
        bookmarks.filter { $0.safetyRating.lowercased() == "safe" }
    }

    private var cautionBookmarks: [BookmarkResponse] {
        bookmarks.filter { $0.safetyRating.lowercased() == "caution" }
    }

    private var avoidBookmarks: [BookmarkResponse] {
        bookmarks.filter { $0.safetyRating.lowercased() == "avoid" }
    }

    private func loadBookmarks() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.getBookmarks(safetyRating: selectedFilter)
            bookmarks = response.bookmarks
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func deleteBookmarks(at offsets: IndexSet, from group: [BookmarkResponse]) {
        for index in offsets {
            let bookmark = group[index]

            Task {
                do {
                    try await apiService.deleteBookmark(bookmarkId: bookmark.id)
                    await MainActor.run {
                        bookmarks.removeAll { $0.id == bookmark.id }
                    }
                } catch {
                    print("Failed to delete bookmark: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct BookmarkRow: View {
    let bookmark: BookmarkResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(bookmark.menuItemName)
                    .font(.headline)

                Spacer()

                SafetyBadge(safety: bookmark.safetyRating)
            }

            if let restaurantName = bookmark.restaurantName {
                Text(restaurantName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if !bookmark.triggers.isEmpty {
                HStack {
                    ForEach(bookmark.triggers, id: \.self) { trigger in
                        Text(trigger)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }

            if let notes = bookmark.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }

            Text(bookmark.formattedDate)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BookmarksView()
}
