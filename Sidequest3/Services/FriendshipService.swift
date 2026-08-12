//
//  FriendshipService.swift
//  Sidequest
//

import Foundation

final class FriendshipService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private func freshRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }

    func searchUsers(query: String) async throws -> [User] {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/users/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)") else {
            throw AppError.unknown(underlying: nil)
        }

        let (data, response) = try await session.data(for: freshRequest(url: url))

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        let decoded = try JSONDecoder().decode(UsersResponse.self, from: data)
        return decoded.data
    }

    func sendRequest(requesterId: UUID, receiverUsername: String) async throws -> Friendship {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/friendships") else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "requester_id": requesterId.uuidString,
            "receiver_username": receiverUsername
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        struct SingleResponse: Codable { let data: Friendship }
        return try JSONDecoder().decode(SingleResponse.self, from: data).data
    }

    func getFriends(userId: UUID) async throws -> [Friendship] {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/friends/\(userId.uuidString)") else {
            throw AppError.unknown(underlying: nil)
        }

        let (data, response) = try await session.data(for: freshRequest(url: url))

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        let decoded = try JSONDecoder().decode(FriendshipsResponse.self, from: data)
        return decoded.data
    }

    func getPendingRequests(userId: UUID) async throws -> [Friendship] {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/friendships/pending/\(userId.uuidString)") else {
            throw AppError.unknown(underlying: nil)
        }

        let (data, response) = try await session.data(for: freshRequest(url: url))

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        let decoded = try JSONDecoder().decode(FriendshipsResponse.self, from: data)
        return decoded.data
    }

    func getSentRequests(userId: UUID) async throws -> [Friendship] {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/friendships/sent/\(userId.uuidString)") else {
            throw AppError.unknown(underlying: nil)
        }

        let (data, response) = try await session.data(for: freshRequest(url: url))

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        let decoded = try JSONDecoder().decode(FriendshipsResponse.self, from: data)
        return decoded.data
    }

    func updateStatus(friendshipId: UUID, status: String) async throws -> Friendship {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/friendships/\(friendshipId.uuidString)") else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["status": status])

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        struct SingleResponse: Codable { let data: Friendship }
        return try JSONDecoder().decode(SingleResponse.self, from: data).data
    }

    func getSuggestions(userId: UUID) async throws -> [FriendSuggestion] {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/friends/\(userId.uuidString)/suggestions") else {
            throw AppError.unknown(underlying: nil)
        }

        let (data, response) = try await session.data(for: freshRequest(url: url))

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        let decoded = try JSONDecoder().decode(FriendSuggestionsResponse.self, from: data)
        return decoded.data
    }

    func removeFriend(friendshipId: UUID) async throws {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/friendships/\(friendshipId.uuidString)") else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }
    }
}
