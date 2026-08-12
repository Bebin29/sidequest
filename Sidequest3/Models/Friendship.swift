//
//  Friendship.swift
//  Sidequest
//

import Foundation

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
    case declined
    case blocked
}

struct Friendship: Codable, Identifiable {
    let id: UUID
    let requesterId: UUID
    let receiverId: UUID
    let status: FriendshipStatus

    let createdAt: String
    let acceptedAt: String?

    let requesterUsername: String
    let receiverUsername: String

    // Erweiterte Felder (optional, nur bei getPendingRequests)
    let requesterDisplayName: String?
    let requesterProfileImageUrl: String?
    let mutualCount: Int?
    let receiverDisplayName: String?
    let receiverProfileImageUrl: String?
    let requesterSpotCount: Int?
    let receiverSpotCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, status
        case requesterId = "requester_id"
        case receiverId = "receiver_id"
        case createdAt = "created_at"
        case acceptedAt = "accepted_at"
        case requesterUsername = "requester_username"
        case receiverUsername = "receiver_username"
        case requesterDisplayName = "requester_display_name"
        case requesterProfileImageUrl = "requester_profile_image_url"
        case mutualCount = "mutual_count"
        case receiverDisplayName = "receiver_display_name"
        case receiverProfileImageUrl = "receiver_profile_image_url"
        case requesterSpotCount = "requester_spot_count"
        case receiverSpotCount = "receiver_spot_count"
    }
}

struct FriendshipsResponse: Codable {
    let data: [Friendship]
    let count: Int
}

struct FriendSuggestion: Codable, Identifiable {
    let id: UUID
    let username: String
    let displayName: String?
    let profileImageUrl: String?
    let mutualCount: Int
    let mutualUsernames: [String]

    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case profileImageUrl = "profile_image_url"
        case mutualCount = "mutual_count"
        case mutualUsernames = "mutual_usernames"
    }
}

struct FriendSuggestionsResponse: Codable {
    let data: [FriendSuggestion]
}
