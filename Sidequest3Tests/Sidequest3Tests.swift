//
//  Sidequest3Tests.swift
//  Sidequest3Tests
//
//  Created by ole on 23.03.26.
//

import Testing
import Foundation
@testable import Sidequest3

struct Sidequest3Tests {

    @Test func userDecodingFromJSON() async throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "email": "test@sidequest.de",
            "username": "testuser",
            "display_name": "Test User",
            "profile_image_url": null,
            "created_at": "2026-03-24T10:00:00.000Z",
            "updated_at": null,
            "last_seen_at": null,
            "bio": "Testbio",
            "preferences": null,
            "favorite_categories": [],
            "is_verified": false,
            "is_moderator": false,
            "is_private": false,
            "fcm_token": null,
            "stats": {}
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)
        #expect(user.username == "testuser")
        #expect(user.displayName == "Test User")
        #expect(user.email == "test@sidequest.de")
        #expect(user.bio == "Testbio")
        #expect(user.isVerified == false)
    }

    @Test func friendshipStatusDecoding() async throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440001",
            "requester_id": "550e8400-e29b-41d4-a716-446655440002",
            "receiver_id": "550e8400-e29b-41d4-a716-446655440003",
            "status": "pending",
            "created_at": "2026-03-24T10:00:00.000Z",
            "accepted_at": null,
            "requester_username": "alice",
            "receiver_username": "bob"
        }
        """.data(using: .utf8)!

        let friendship = try JSONDecoder().decode(Friendship.self, from: json)
        #expect(friendship.status == .pending)
        #expect(friendship.requesterUsername == "alice")
        #expect(friendship.receiverUsername == "bob")
    }

    @Test func ratingValidRange() async throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440004",
            "location_id": "550e8400-e29b-41d4-a716-446655440005",
            "location_name": "Testcafé",
            "user_id": "550e8400-e29b-41d4-a716-446655440006",
            "username": "testuser",
            "user_profile_image_url": null,
            "rating": 4,
            "comment": "Sehr gut!",
            "image_urls": [],
            "thumbnail_urls": [],
            "created_at": "2026-03-24T10:00:00.000Z",
            "updated_at": null,
            "trip_id": null,
            "is_verified": false,
            "verified_at": null,
            "report_count": 0,
            "is_hidden": false,
            "reaction_count": 0,
            "comment_count": 0,
            "helpful_count": 0,
            "visit_date": null,
            "price_spent": null,
            "would_recommend": true
        }
        """.data(using: .utf8)!

        let rating = try JSONDecoder().decode(Rating.self, from: json)
        #expect(rating.rating >= 1 && rating.rating <= 5)
        #expect(rating.locationName == "Testcafé")
        #expect(rating.wouldRecommend == true)
    }
}
