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

    enum CodingKeys: String, CodingKey {
        case id, status
        case requesterId = "requester_id"
        case receiverId = "receiver_id"
        case createdAt = "created_at"
        case acceptedAt = "accepted_at"
        case requesterUsername = "requester_username"
        case receiverUsername = "receiver_username"
    }
}

struct FriendshipsResponse: Codable {
    let data: [Friendship]
    let count: Int
}
