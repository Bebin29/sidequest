//
//  FriendsViewModel.swift
//  Sidequest
//

import Foundation
import AudioToolbox
import AVFoundation

@Observable
final class FriendsViewModel {
    var friends: [Friendship] = []
    var pendingRequests: [Friendship] = []
    var searchResults: [User] = []
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?

    private let service = FriendshipService()

    func loadFriends(userId: UUID) async {
        isLoading = true
        do {
            friends = try await service.getFriends(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadPendingRequests(userId: UUID) async {
        do {
            pendingRequests = try await service.getPendingRequests(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchUsers(query: String) async {
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        do {
            searchResults = try await service.searchUsers(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendRequest(requesterId: UUID, receiverUsername: String) async {
        errorMessage = nil
        successMessage = nil
        do {
            _ = try await service.sendRequest(requesterId: requesterId, receiverUsername: receiverUsername)
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true)
            AudioServicesPlayAlertSound(1407)
            successMessage = "Anfrage an @\(receiverUsername) gesendet"
            searchResults = []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptRequest(friendshipId: UUID, userId: UUID) async {
        do {
            _ = try await service.updateStatus(friendshipId: friendshipId, status: "accepted")
            await loadPendingRequests(userId: userId)
            await loadFriends(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func declineRequest(friendshipId: UUID, userId: UUID) async {
        do {
            _ = try await service.updateStatus(friendshipId: friendshipId, status: "declined")
            await loadPendingRequests(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFriend(friendshipId: UUID, userId: UUID) async {
        do {
            try await service.removeFriend(friendshipId: friendshipId)
            await loadFriends(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
