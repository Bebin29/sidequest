//
//  Location.swift
//  Sidequest
//

import Foundation

enum LocationCategory: String, Codable, CaseIterable {
    case restaurant = "Restaurant"
    case cafe = "Café"
    case bar = "Bar"
    case club = "Club"
    case bakery = "Bäckerei"
    case fastFood = "Fast Food"
    case iceCream = "Eisdiele"
    case park = "Park"
    case museum = "Museum"
    case shopping = "Shopping"
    case viewpoint = "Aussichtspunkt"
    case beach = "Strand"
    case other = "Sonstiges"
}

enum PriceRange: String, Codable, CaseIterable {
    case budget = "€"
    case moderate = "€€"
    case upscale = "€€€"
    case luxury = "€€€€"
}

enum NoiseLevel: String, Codable, CaseIterable {
    case quiet = "Ruhig"
    case moderate = "Moderat"
    case loud = "Laut"
    case veryLoud = "Sehr laut"
}

struct OpeningHours: Codable {
    let monday: DayHours?
    let tuesday: DayHours?
    let wednesday: DayHours?
    let thursday: DayHours?
    let friday: DayHours?
    let saturday: DayHours?
    let sunday: DayHours?
}

struct DayHours: Codable {
    let openTime: String
    let closeTime: String
    let isClosed: Bool
}

struct ParkingInfo: Codable {
    let hasParking: Bool
    let parkingType: String?
    let isFree: Bool?
    let notes: String?
}

struct AccessibilityInfo: Codable {
    let wheelchairAccessible: Bool
    let hasElevator: Bool
    let hasAccessibleRestroom: Bool
}

struct Location: Codable, Identifiable, Hashable {
    static func == (lhs: Location, rhs: Location) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let geohash: String
    let category: String

    let averageRating: Double
    let totalRatings: Int

    let createdAt: String
    let updatedAt: String?
    let createdBy: UUID

    let description: String?

    let imageUrls: [String]
    let thumbnailUrl: String?
    let tags: [String]

    let priceRange: String?
    let openingHours: OpeningHours?
    let parkingInfo: ParkingInfo?
    let accessibility: AccessibilityInfo?

    let noiseLevel: String?
    let wifiAvailable: Bool?
    let isDogFriendly: Bool?
    let isFamilyFriendly: Bool?

    let phoneNumber: String?
    let website: String?
    let instagramHandle: String?

    let isVerified: Bool
    let reportCount: Int
    let trendingScore: Double?

    // Creator info (from JOIN)
    let creatorUsername: String?
    let creatorDisplayName: String?
    let creatorProfileImageUrl: String?
}

struct LocationsResponse: Codable {
    let data: [Location]
    let count: Int
}
