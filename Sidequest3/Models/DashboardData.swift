//
//  DashboardData.swift
//  Sidequest
//

import Foundation

struct DashboardData: Codable {
    let status: String
    let timestamp: String
    let queryMs: Int
    let server: ServerInfo
    let database: DatabaseOverview
    let tables: TableCounts?
    let userAnalytics: UserAnalytics?
    let locationAnalytics: LocationAnalytics?
    let socialAnalytics: SocialAnalytics?
    let activityFeed: [ActivityItem]?

    var isHealthy: Bool { status == "ok" }

    var formattedUptime: String {
        let total = server.uptimeSeconds
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    enum CodingKeys: String, CodingKey {
        case status, timestamp, server, database, tables
        case queryMs = "query_ms"
        case userAnalytics = "user_analytics"
        case locationAnalytics = "location_analytics"
        case socialAnalytics = "social_analytics"
        case activityFeed = "activity_feed"
    }
}

// MARK: - Server

struct ServerInfo: Codable {
    let uptimeSeconds: Int
    let nodeVersion: String
    let memoryMb: MemoryInfo

    enum CodingKeys: String, CodingKey {
        case uptimeSeconds = "uptime_seconds"
        case nodeVersion = "node_version"
        case memoryMb = "memory_mb"
    }

    struct MemoryInfo: Codable {
        let rss: Int
        let heapUsed: Int
        let heapTotal: Int

        enum CodingKeys: String, CodingKey {
            case rss
            case heapUsed = "heap_used"
            case heapTotal = "heap_total"
        }
    }
}

// MARK: - Database

struct DatabaseOverview: Codable {
    let connected: Bool
    let responseMs: Int?
    let serverTime: String?
    let error: String?
    let dbSize: String?
    let tableSizes: TableSizes?

    enum CodingKeys: String, CodingKey {
        case connected, error
        case responseMs = "response_ms"
        case serverTime = "server_time"
        case dbSize = "db_size"
        case tableSizes = "table_sizes"
    }

    struct TableSizes: Codable {
        let users: String
        let locations: String
        let comments: String
        let friendships: String
        let notifications: String
    }
}

struct TableCounts: Codable {
    let users: Int
    let locations: Int
    let comments: Int
    let friendships: Int
    let notifications: Int
}

// MARK: - User Analytics

struct UserAnalytics: Codable {
    let growth: [DayCount]
    let engagement: Engagement
    let topContributors: [Contributor]

    enum CodingKeys: String, CodingKey {
        case growth, engagement
        case topContributors = "top_contributors"
    }

    struct Engagement: Codable {
        let active24h: Int
        let active7d: Int
        let active30d: Int
        let verifiedCount: Int
        let moderatorCount: Int
        let withAvatar: Int
        let withBio: Int
        let total: Int

        enum CodingKeys: String, CodingKey {
            case total
            case active24h = "active_24h"
            case active7d = "active_7d"
            case active30d = "active_30d"
            case verifiedCount = "verified_count"
            case moderatorCount = "moderator_count"
            case withAvatar = "with_avatar"
            case withBio = "with_bio"
        }
    }

    struct Contributor: Codable, Identifiable {
        var id: String { username }
        let username: String
        let displayName: String
        let spotCount: Int
        let commentCount: Int

        enum CodingKeys: String, CodingKey {
            case username
            case displayName = "display_name"
            case spotCount = "spot_count"
            case commentCount = "comment_count"
        }
    }
}

// MARK: - Location Analytics

struct LocationAnalytics: Codable {
    let growth: [DayCount]
    let categories: [CategoryCount]
}

struct CategoryCount: Codable, Identifiable {
    var id: String { category }
    let category: String
    let count: Int
}

// MARK: - Social Analytics

struct SocialAnalytics: Codable {
    let friendships: FriendshipStats
    let network: NetworkStats
    let comments: CommentStats

    struct FriendshipStats: Codable {
        let accepted: Int
        let pending: Int
        let declined: Int
        let blocked: Int
        let total: Int
        let avgAcceptHours: Double?

        enum CodingKeys: String, CodingKey {
            case accepted, pending, declined, blocked, total
            case avgAcceptHours = "avg_accept_hours"
        }
    }

    struct NetworkStats: Codable {
        let avgFriendsPerUser: Double?
        let maxFriends: Int

        enum CodingKeys: String, CodingKey {
            case avgFriendsPerUser = "avg_friends_per_user"
            case maxFriends = "max_friends"
        }
    }

    struct CommentStats: Codable {
        let totalComments: Int
        let uniqueCommenters: Int
        let locationsWithComments: Int
        let avgPerLocation: Double?

        enum CodingKeys: String, CodingKey {
            case totalComments = "total_comments"
            case uniqueCommenters = "unique_commenters"
            case locationsWithComments = "locations_with_comments"
            case avgPerLocation = "avg_per_location"
        }
    }
}

// MARK: - Shared

struct DayCount: Codable, Identifiable {
    var id: String { date }
    let date: String
    let count: Int
}

struct ActivityItem: Codable, Identifiable {
    var id: String { "\(type)-\(actor)-\(createdAt)" }
    let type: String
    let actor: String
    let detail: String?
    let target: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case type, actor, detail, target
        case createdAt = "created_at"
    }
}
