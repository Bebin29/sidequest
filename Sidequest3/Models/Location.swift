//
//  Location.swift
//  Sidequest
//

import Foundation

struct CategoryHelper {
    struct CategoryInfo {
        let name: String
        let icon: String
    }

    static let predefined: [CategoryInfo] = [
        CategoryInfo(name: "Restaurant", icon: "fork.knife"),
        CategoryInfo(name: "Café", icon: "cup.and.saucer.fill"),
        CategoryInfo(name: "Bar", icon: "wineglass.fill"),
        CategoryInfo(name: "Club", icon: "music.note.house.fill"),
        CategoryInfo(name: "Bäckerei", icon: "birthday.cake.fill"),
        CategoryInfo(name: "Fast Food", icon: "takeoutbag.and.cup.and.straw.fill"),
        CategoryInfo(name: "Eisdiele", icon: "snowflake"),
        CategoryInfo(name: "Park", icon: "leaf.fill"),
        CategoryInfo(name: "Museum", icon: "building.columns.fill"),
        CategoryInfo(name: "Shopping", icon: "bag.fill"),
        CategoryInfo(name: "Aussichtspunkt", icon: "binoculars.fill"),
        CategoryInfo(name: "Strand", icon: "beach.umbrella.fill"),
        CategoryInfo(name: "Sport", icon: "sportscourt.fill"),
        CategoryInfo(name: "Nachtleben", icon: "moon.stars.fill"),
        CategoryInfo(name: "Kultur", icon: "theatermasks.fill"),
        CategoryInfo(name: "Natur", icon: "tree.fill"),
        CategoryInfo(name: "Wellness", icon: "sparkles")
    ]

    static let defaultIcon = "mappin.circle.fill"

    static func icon(for category: String) -> String {
        predefined.first { $0.name == category }?.icon ?? defaultIcon
    }

    static var predefinedNames: [String] {
        predefined.map(\.name)
    }
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

    // Creator info (from JOIN)
    let creatorUsername: String?
    let creatorDisplayName: String?
    let creatorProfileImageUrl: String?

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
        case creatorUsername = "creator_username"
        case creatorDisplayName = "creator_display_name"
        case creatorProfileImageUrl = "creator_profile_image_url"
    }
}

struct LocationsResponse: Codable {
    let data: [Location]
    let count: Int
}
