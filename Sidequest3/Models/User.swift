//
//  User.swift
//  Sidequest
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let username: String
    let displayName: String
    let profileImageUrl: String?
    let createdAt: String
    let updatedAt: String?
    let bio: String?
    let preferences: [String: String]?
    let isVerified: Bool
    let isModerator: Bool

    enum CodingKeys: String, CodingKey {
        case id, email, username, bio, preferences
        case displayName = "display_name"
        case profileImageUrl = "profile_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isVerified = "is_verified"
        case isModerator = "is_moderator"
    }
}

struct UsersResponse: Codable {
    let data: [User]
    let count: Int
}
