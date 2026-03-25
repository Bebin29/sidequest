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

    enum CodingKeys: String, CodingKey {
        case id, rating, comment, username
        case locationId = "location_id"
        case locationName = "location_name"
        case userId = "user_id"
        case userProfileImageUrl = "user_profile_image_url"
        case imageUrls = "image_urls"
        case thumbnailUrls = "thumbnail_urls"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case tripId = "trip_id"
        case isVerified = "is_verified"
        case verifiedAt = "verified_at"
        case reportCount = "report_count"
        case isHidden = "is_hidden"
        case reactionCount = "reaction_count"
        case commentCount = "comment_count"
        case helpfulCount = "helpful_count"
        case visitDate = "visit_date"
        case priceSpent = "price_spent"
        case wouldRecommend = "would_recommend"
    }
}

struct RatingsResponse: Codable {
    let data: [Rating]
    let count: Int
}
