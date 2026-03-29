//
//  DeepLinkRouter.swift
//  Sidequest
//

import Foundation

/// Moegliche Navigation-Ziele fuer Push Notifications und Deep Links
enum DeepLinkDestination: Equatable {
    case friendRequests
    case location(id: UUID)
    case userProfile(id: UUID)
}

/// Zentraler Router fuer Deep-Link Navigation aus Push Notifications
@Observable
final class DeepLinkRouter {
    var pendingDestination: DeepLinkDestination?
    var selectedTab: AppTab?

    /// Notification-Payload verarbeiten und Navigation-Ziel setzen
    @MainActor
    func handleNotification(userInfo: [AnyHashable: Any]) {
        guard let data = userInfo["data"] as? [String: Any],
              let type = userInfo["type"] as? String ?? (userInfo["aps"] as? [String: Any])?["thread-id"] as? String
        else {
            // Fallback: type aus dem aps thread-id lesen
            if let aps = userInfo["aps"] as? [String: Any],
               let threadId = aps["thread-id"] as? String {
                handleType(threadId, data: userInfo["data"] as? [String: Any] ?? [:])
                return
            }
            return
        }

        handleType(type, data: data)
    }

    @MainActor
    private func handleType(_ type: String, data: [String: Any]) {
        switch type {
        case "friend_request", "friend_accepted":
            selectedTab = .profile
            pendingDestination = .friendRequests

        case "new_comment", "friend_new_spot":
            if let locationIdString = data["location_id"] as? String,
               let locationId = UUID(uuidString: locationIdString) {
                selectedTab = .home
                pendingDestination = .location(id: locationId)
            }

        default:
            break
        }
    }

    /// Destination als konsumiert markieren
    @MainActor
    func clearDestination() {
        pendingDestination = nil
    }
}
