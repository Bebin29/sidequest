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
}

struct CommentsResponse: Codable {
    let data: [Comment]
    let count: Int
}
