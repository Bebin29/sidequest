//
//  Rating.swift
//  Sidequest
//

import Foundation

struct Rating: Codable, Identifiable {
    let id: UUID
    let locationId: UUID
    let locationName: String
    let userId: UUID
    let username: String
    let userProfileImageUrl: String?

    let rating: Int
    let comment: String?
    let imageUrls: [String]
    let thumbnailUrls: [String]

    let createdAt: String
    let updatedAt: String?

    let tripId: UUID?
    let isVerified: Bool
    let verifiedAt: String?

    let reportCount: Int
    let isHidden: Bool

    let reactionCount: Int
    let commentCount: Int
    let helpfulCount: Int

    let visitDate: String?
    let priceSpent: Double?
    let wouldRecommend: Bool?
}

struct RatingsResponse: Codable {
    let data: [Rating]
    let count: Int
}
