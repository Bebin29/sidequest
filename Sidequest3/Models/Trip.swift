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
}

struct TripsResponse: Codable {
    let data: [Trip]
    let count: Int
}
