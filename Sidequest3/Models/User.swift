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
    let lastSeenAt: String?
    let bio: String?
    let preferences: [String: String]?
    let favoriteCategories: [String]
    let isVerified: Bool
    let isModerator: Bool
    let isPrivate: Bool
    let fcmToken: String?
    let stats: [String: Int]?

    enum CodingKeys: String, CodingKey {
        case id, email, username, bio, preferences, stats
        case displayName = "display_name"
        case profileImageUrl = "profile_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastSeenAt = "last_seen_at"
        case favoriteCategories = "favorite_categories"
        case isVerified = "is_verified"
        case isModerator = "is_moderator"
        case isPrivate = "is_private"
        case fcmToken = "fcm_token"
    }
}

struct UsersResponse: Codable {
    let data: [User]
    let count: Int
}
