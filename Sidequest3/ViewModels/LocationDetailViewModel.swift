//
//  LocationDetailViewModel.swift
//  Sidequest
//

import Foundation

@Observable
final class LocationDetailViewModel {
    var comments: [Comment] = []
    var isLoading = false
    var errorMessage: String?

    private let commentService = CommentService()

    func loadComments(locationId: UUID) async {
        isLoading = true
        do {
            comments = try await commentService.fetchComments(locationId: locationId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addComment(locationId: UUID, userId: UUID, text: String) async {
        do {
            let comment = try await commentService.createComment(locationId: locationId, userId: userId, text: text)
            comments.append(comment)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
