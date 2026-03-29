//
//  FeedViewModel.swift
//  Sidequest
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class FeedViewModel {
    var locations: [Location] = []
    var isLoading = false
    var isLoadingMore = false
    var hasMore = true
    var errorMessage: String?

    // Carousel state
    var currentIndex: Int = 0
    var dominantColors: [UUID: Color] = [:]

    private let feedService = FeedService()
    private let pageSize = 20

    // MARK: - Dominant Color

    var currentDominantColor: Color? {
        guard currentIndex >= 0, currentIndex < locations.count else { return nil }
        return dominantColors[locations[currentIndex].id]
    }

    func setDominantColor(_ color: Color, for locationId: UUID) {
        dominantColors[locationId] = color
    }

    func loadFeed(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await feedService.fetchFeed(userId: userId, limit: pageSize, offset: 0)
            locations = response.data
            hasMore = response.hasMore
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
