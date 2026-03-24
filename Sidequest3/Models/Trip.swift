//
//  Trip.swift
//  Sidequest
//

import Foundation

struct Trip: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let username: String
    let name: String
    let description: String?

    let locationCount: Int

    let createdAt: String
    let updatedAt: String?
    let startDate: String?
    let endDate: String?

    let coverImageUrl: String?
    let isCollaborative: Bool
    let isPublic: Bool
    let viewCount: Int
    let reminderDate: String?

    enum CodingKeys: String, CodingKey {
        case id, username, name, description
        case userId = "user_id"
        case locationCount = "location_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case startDate = "start_date"
        case endDate = "end_date"
        case coverImageUrl = "cover_image_url"
        case isCollaborative = "is_collaborative"
        case isPublic = "is_public"
        case viewCount = "view_count"
        case reminderDate = "reminder_date"
    }
}

struct TripsResponse: Codable {
    let data: [Trip]
    let count: Int
}
