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

    enum CodingKeys: String, CodingKey {
        case openTime = "open_time"
        case closeTime = "close_time"
        case isClosed = "is_closed"
    }
}

struct ParkingInfo: Codable {
    let hasParking: Bool
    let parkingType: String?
    let isFree: Bool?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case hasParking = "has_parking"
        case parkingType = "parking_type"
        case isFree = "is_free"
        case notes
    }
}

struct AccessibilityInfo: Codable {
    let wheelchairAccessible: Bool
    let hasElevator: Bool
    let hasAccessibleRestroom: Bool

    enum CodingKeys: String, CodingKey {
        case wheelchairAccessible = "wheelchair_accessible"
        case hasElevator = "has_elevator"
        case hasAccessibleRestroom = "has_accessible_restroom"
    }
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

    enum CodingKeys: String, CodingKey {
        case id, name, address, latitude, longitude, geohash, category, tags, website, description
        case averageRating = "average_rating"
        case totalRatings = "total_ratings"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdBy = "created_by"
        case imageUrls = "image_urls"
        case thumbnailUrl = "thumbnail_url"
        case priceRange = "price_range"
        case openingHours = "opening_hours"
        case parkingInfo = "parking_info"
        case accessibility
        case noiseLevel = "noise_level"
        case wifiAvailable = "wifi_available"
        case isDogFriendly = "is_dog_friendly"
        case isFamilyFriendly = "is_family_friendly"
        case phoneNumber = "phone_number"
        case instagramHandle = "instagram_handle"
        case isVerified = "is_verified"
        case reportCount = "report_count"
        case trendingScore = "trending_score"
    }
}

struct LocationsResponse: Codable {
    let data: [Location]
    let count: Int
}
