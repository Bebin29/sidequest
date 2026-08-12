//
//  Comment.swift
//  Sidequest
//

import Foundation

struct Comment: Codable, Identifiable {
    let id: UUID
    let locationId: UUID
    let userId: UUID
    let username: String
    let text: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, username, text
        case locationId = "location_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct CommentsResponse: Codable {
    let data: [Comment]
    let count: Int
}
