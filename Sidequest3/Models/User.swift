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
    let ringCode: String?
}

struct UsersResponse: Codable {
    let data: [User]
    let count: Int
}
