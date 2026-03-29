//
//  FeedViewModel.swift
//  Sidequest
//

import Foundation

@MainActor
@Observable
final class FeedViewModel {
    var locations: [Location] = []
    var isLoading = false
    var isLoadingMore = false
    var hasMore = true
    var errorMessage: String?

    private let feedService = FeedService()
    private let pageSize = 10
    private var hasFetched = false

    /// Lädt den Feed nur wenn nötig (erster Aufruf oder force refresh).
    /// Tab-Wechsel triggert KEINEN erneuten Netzwerk-Request.
    func loadFeed(userId: UUID, forceRefresh: Bool = false) async {
        // Bereits geladene Daten bei Tab-Wechsel beibehalten
        guard forceRefresh || !hasFetched else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await feedService.fetchFeed(userId: userId, limit: pageSize, offset: 0)
            locations = response.data
            hasMore = response.hasMore
            hasFetched = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore(userId: UUID) async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let response = try await feedService.fetchFeed(userId: userId, limit: pageSize, offset: locations.count)
            locations.append(contentsOf: response.data)
            hasMore = response.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
