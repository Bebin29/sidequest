//
//  ServerStatus.swift
//  Sidequest
//

import Foundation

struct ServerStatus: Codable {
    let status: String
    let timestamp: String
    let server: ServerInfo
    let database: DatabaseInfo
    let tables: TableCounts?

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

    struct DatabaseInfo: Codable {
        let connected: Bool
        let responseMs: Int?
        let serverTime: String?
        let error: String?

        enum CodingKeys: String, CodingKey {
            case connected
            case responseMs = "response_ms"
            case serverTime = "server_time"
            case error
        }
    }

    struct TableCounts: Codable {
        let users: Int
        let locations: Int
        let ratings: Int
        let comments: Int
        let friendships: Int
        let notifications: Int
    }

    var isHealthy: Bool { status == "ok" }

    var formattedUptime: String {
        let total = server.uptimeSeconds
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
