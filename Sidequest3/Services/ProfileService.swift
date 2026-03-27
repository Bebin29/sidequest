//
//  ProfileService.swift
//  Sidequest
//

import Foundation

final class ProfileService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func getUser(id: UUID) async throws -> User {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/users/\(id.uuidString)") else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        struct SingleResponse: Codable { let data: User }
        return try JSONDecoder().decode(SingleResponse.self, from: data).data
    }

    func checkUsername(username: String) async throws -> Bool {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/users/check-username?username=\(username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username)") else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        struct CheckResponse: Codable { let available: Bool }
        return try JSONDecoder().decode(CheckResponse.self, from: data).available
    }

    func updateProfile(userId: UUID, body: [String: Any]) async throws -> User {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/users/\(userId.uuidString)") else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        struct SingleResponse: Codable { let data: User }
        return try JSONDecoder().decode(SingleResponse.self, from: data).data
    }
}
