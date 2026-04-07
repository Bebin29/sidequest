//
//  Location.swift
//  Sidequest
//

import Foundation
import SwiftUI

enum LocationCategory: String, Codable, CaseIterable {
    case restaurant = "Restaurant"
    case cafe = "Café"
    case bar = "Bar"
    case club = "Club"
    case bakery = "Bäckerei"
    case fastFood = "Fast Food"
    case iceCream = "Eisdiele"
    case hotel = "Hotel"
    case cinema = "Kino"
    case gym = "Fitnessstudio"
    case spa = "Spa & Wellness"
    case landmark = "Sehenswürdigkeit"
    case park = "Park"
    case museum = "Museum"
    case shopping = "Shopping"
    case viewpoint = "Aussichtspunkt"
    case beach = "Strand"
    case other = "Sonstiges"

    var color: Color {
        switch self {
        case .restaurant: return .orange
        case .cafe: return .brown
        case .bar: return .purple
        case .club: return .pink
        case .bakery: return .yellow
        case .fastFood: return .red
        case .iceCream: return .cyan
        case .hotel: return .blue
        case .cinema: return .red
        case .gym: return .mint
        case .spa: return .purple
        case .landmark: return .yellow
        case .park: return .green
        case .museum: return .blue
        case .shopping: return .pink
        case .viewpoint: return .teal
        case .beach: return .cyan
        case .other: return .indigo
        }
    }

    static func color(for categoryString: String) -> Color {
        (LocationCategory(rawValue: categoryString) ?? .other).color
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
    let category: String

    let createdAt: String
    let updatedAt: String?
    let createdBy: UUID

    let description: String?

    let imageUrls: [String]
    let tags: [String]

    let priceRange: String?

    let noiseLevel: String?
    let wifiAvailable: Bool?
    let isDogFriendly: Bool?
    let isFamilyFriendly: Bool?

    let phoneNumber: String?
    let website: String?
    let instagramHandle: String?

    let isVerified: Bool

    // Creator info (from JOIN)
    let creatorUsername: String?
    let creatorDisplayName: String?
    let creatorProfileImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, address, latitude, longitude, category, tags, website, description
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdBy = "created_by"
        case imageUrls = "image_urls"
        case priceRange = "price_range"
        case noiseLevel = "noise_level"
        case wifiAvailable = "wifi_available"
        case isDogFriendly = "is_dog_friendly"
        case isFamilyFriendly = "is_family_friendly"
        case phoneNumber = "phone_number"
        case instagramHandle = "instagram_handle"
        case isVerified = "is_verified"
        case creatorUsername = "creator_username"
        case creatorDisplayName = "creator_display_name"
        case creatorProfileImageUrl = "creator_profile_image_url"
    }
}

struct LocationsResponse: Codable {
    let data: [Location]
    let count: Int
}
