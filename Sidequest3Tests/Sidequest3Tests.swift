//
//  Sidequest3Tests.swift
//  Sidequest3Tests
//
//  Created by ole on 23.03.26.
//

import Testing
import Foundation
@testable import Sidequest3

// Resolve ambiguity with Testing framework's Comment type
typealias AppComment = Sidequest3.Comment

// MARK: - Mock URLProtocol

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var mockData: Data?
    nonisolated(unsafe) static var mockResponse: HTTPURLResponse?
    nonisolated(unsafe) static var mockError: Error?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canInit(with task: URLSessionTask) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override class func requestIsCacheEquivalent(_ lhs: URLRequest, to rhs: URLRequest) -> Bool { false }

    override func startLoading() {
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        if let response = MockURLProtocol.mockResponse {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = MockURLProtocol.mockData {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
    }
}

func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    config.timeoutIntervalForRequest = 2
    config.timeoutIntervalForResource = 2
    config.urlCache = nil
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    return URLSession(configuration: config)
}

func mockSuccess(json: String, statusCode: Int = 200) {
    MockURLProtocol.mockData = json.data(using: .utf8)
    MockURLProtocol.mockResponse = HTTPURLResponse(
        url: URL(string: "http://test.local")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )
    MockURLProtocol.mockError = nil
}

func mockFailure(statusCode: Int) {
    MockURLProtocol.mockData = "{\"error\":\"fail\"}".data(using: .utf8)
    MockURLProtocol.mockResponse = HTTPURLResponse(
        url: URL(string: "http://test.local")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )
    MockURLProtocol.mockError = nil
}

// MARK: - Test Data

let testLocationJSON = """
{
    "id": "550e8400-e29b-41d4-a716-446655440010",
    "name": "Testcafé Mitte",
    "address": "Torstraße 1, Berlin",
    "latitude": 52.5290,
    "longitude": 13.4010,
    "geohash": "u33dc",
    "category": "Café",
    "average_rating": 4.5,
    "total_ratings": 12,
    "created_at": "2026-03-20T10:00:00.000Z",
    "updated_at": null,
    "created_by": "550e8400-e29b-41d4-a716-446655440099",
    "description": "Gemütliches Café mit Hafermilch",
    "image_urls": ["http://example.com/img1.jpg", "http://example.com/img2.jpg"],
    "thumbnail_url": null,
    "tags": ["vegan", "wifi"],
    "price_range": "€€",
    "opening_hours": null,
    "parking_info": null,
    "accessibility": null,
    "noise_level": "Moderat",
    "wifi_available": true,
    "is_dog_friendly": false,
    "is_family_friendly": true,
    "phone_number": null,
    "website": "https://testcafe.de",
    "instagram_handle": "@testcafe",
    "is_verified": false,
    "report_count": 0,
    "trending_score": 1.5,
    "creator_username": "alice",
    "creator_display_name": "Alice M.",
    "creator_profile_image_url": null
}
"""

// MARK: - Model Decoding Tests

struct ModelDecodingTests {

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
        #expect(user.isModerator == false)
        #expect(user.favoriteCategories.isEmpty)
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

    @Test func friendshipAllStatusValues() async throws {
        for status in ["pending", "accepted", "declined", "blocked"] {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440001",
                "requester_id": "550e8400-e29b-41d4-a716-446655440002",
                "receiver_id": "550e8400-e29b-41d4-a716-446655440003",
                "status": "\(status)",
                "created_at": "2026-03-24T10:00:00.000Z",
                "accepted_at": null,
                "requester_username": "a",
                "receiver_username": "b"
            }
            """.data(using: .utf8)!

            let friendship = try JSONDecoder().decode(Friendship.self, from: json)
            #expect(friendship.status.rawValue == status)
        }
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

    @Test func locationDecodingFullJSON() async throws {
        let data = testLocationJSON.data(using: .utf8)!
        let location = try JSONDecoder().decode(Location.self, from: data)

        #expect(location.name == "Testcafé Mitte")
        #expect(location.address == "Torstraße 1, Berlin")
        #expect(location.latitude == 52.5290)
        #expect(location.longitude == 13.4010)
        #expect(location.category == "Café")
        #expect(location.averageRating == 4.5)
        #expect(location.totalRatings == 12)
        #expect(location.imageUrls.count == 2)
        #expect(location.tags == ["vegan", "wifi"])
        #expect(location.wifiAvailable == true)
        #expect(location.isDogFriendly == false)
        #expect(location.isFamilyFriendly == true)
        #expect(location.website == "https://testcafe.de")
        #expect(location.instagramHandle == "@testcafe")
        #expect(location.creatorUsername == "alice")
        #expect(location.creatorDisplayName == "Alice M.")
    }

    @Test func commentDecoding() async throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440020",
            "location_id": "550e8400-e29b-41d4-a716-446655440021",
            "user_id": "550e8400-e29b-41d4-a716-446655440022",
            "username": "bob",
            "text": "Toller Spot!",
            "created_at": "2026-03-25T14:30:00.000Z"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AppComment.self, from: json)
        #expect(decoded.username == "bob")
        #expect(decoded.text == "Toller Spot!")
        #expect(decoded.createdAt.hasPrefix("2026-03-25"))
    }

    @Test func tripDecoding() async throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440030",
            "user_id": "550e8400-e29b-41d4-a716-446655440031",
            "username": "alice",
            "name": "Berlin Weekend",
            "description": "3 Tage Berlin",
            "location_count": 5,
            "created_at": "2026-03-20T08:00:00.000Z",
            "updated_at": null,
            "start_date": "2026-04-01",
            "end_date": "2026-04-03",
            "cover_image_url": null,
            "is_collaborative": false,
            "is_public": true,
            "view_count": 42,
            "reminder_date": null
        }
        """.data(using: .utf8)!

        let trip = try JSONDecoder().decode(Trip.self, from: json)
        #expect(trip.name == "Berlin Weekend")
        #expect(trip.locationCount == 5)
        #expect(trip.isPublic == true)
        #expect(trip.isCollaborative == false)
        #expect(trip.viewCount == 42)
        #expect(trip.startDate == "2026-04-01")
    }

    @Test func locationCategoryRawValues() {
        #expect(LocationCategory.restaurant.rawValue == "Restaurant")
        #expect(LocationCategory.cafe.rawValue == "Café")
        #expect(LocationCategory.bar.rawValue == "Bar")
        #expect(LocationCategory.park.rawValue == "Park")
        #expect(LocationCategory.allCases.count == 13)
    }

    @Test func feedResponseDecoding() async throws {
        let json = """
        {
            "data": [\(testLocationJSON)],
            "count": 1,
            "hasMore": true
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(FeedResponse.self, from: json)
        #expect(response.data.count == 1)
        #expect(response.count == 1)
        #expect(response.hasMore == true)
        #expect(response.data.first?.name == "Testcafé Mitte")
    }
}

// MARK: - Service Layer Tests (with Mock URLSession)

struct ServiceTests {

    @Test func feedServiceSuccess() async throws {
        let session = makeMockSession()
        let service = FeedService(session: session)

        mockSuccess(json: """
        {
            "data": [\(testLocationJSON)],
            "count": 1,
            "hasMore": false
        }
        """)

        let userId = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440099")!
        let response = try await service.fetchFeed(userId: userId)
        #expect(response.data.count == 1)
        #expect(response.hasMore == false)
        #expect(response.data.first?.name == "Testcafé Mitte")
    }

    @Test func feedServiceServerError() async throws {
        let session = makeMockSession()
        let service = FeedService(session: session)

        mockFailure(statusCode: 500)

        let userId = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440099")!
        do {
            _ = try await service.fetchFeed(userId: userId)
            #expect(Bool(false), "Should have thrown")
        } catch let error as AppError {
            if case .server(let code, _) = error {
                #expect(code == 500)
            } else {
                #expect(Bool(false), "Wrong error type: \(error)")
            }
        }
    }

    @Test func locationServiceGetLocation() async throws {
        let session = makeMockSession()
        let service = LocationService(session: session)

        mockSuccess(json: "{\"data\": \(testLocationJSON)}")

        let locationId = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440010")!
        let location = try await service.getLocation(id: locationId)
        #expect(location.name == "Testcafé Mitte")
        #expect(location.category == "Café")
    }

    @Test func locationServiceFetchLocations() async throws {
        let session = makeMockSession()
        let service = LocationService(session: session)

        mockSuccess(json: """
        {
            "data": [\(testLocationJSON)],
            "count": 1
        }
        """)

        let userId = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440099")!
        let locations = try await service.fetchLocations(userId: userId)
        #expect(locations.count == 1)
    }

    @Test func locationService404Error() async throws {
        let session = makeMockSession()
        let service = LocationService(session: session)

        mockFailure(statusCode: 404)

        let locationId = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440010")!
        do {
            _ = try await service.getLocation(id: locationId)
            #expect(Bool(false), "Should have thrown")
        } catch let error as AppError {
            if case .server(let code, _) = error {
                #expect(code == 404)
            } else {
                #expect(Bool(false), "Wrong error type")
            }
        }
    }

    @Test func commentServiceFetchComments() async throws {
        let session = makeMockSession()
        let service = Sidequest3.CommentService(session: session)

        mockSuccess(json: """
        {
            "data": [
                {
                    "id": "550e8400-e29b-41d4-a716-446655440020",
                    "location_id": "550e8400-e29b-41d4-a716-446655440021",
                    "user_id": "550e8400-e29b-41d4-a716-446655440022",
                    "username": "bob",
                    "text": "Super Laden!",
                    "created_at": "2026-03-25T14:30:00.000Z"
                }
            ],
            "count": 1
        }
        """)

        let locationId = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440021")!
        let result: [AppComment] = try await service.fetchComments(locationId: locationId)
        #expect(result.count == 1)
        #expect(result.first?.text == "Super Laden!")
    }
}
