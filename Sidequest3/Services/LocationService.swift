//
//  LocationService.swift
//  Sidequest
//

import Foundation

final class LocationService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func getLocation(id: UUID) async throws -> Location {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/locations/\(id.uuidString)") else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        struct SingleResponse: Codable { let data: Location }
        return try JSONDecoder().decode(SingleResponse.self, from: data).data
    }

    func fetchLocations(userId: UUID) async throws -> [Location] {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/locations?user_id=\(userId.uuidString)") else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        let decoded = try JSONDecoder().decode(LocationsResponse.self, from: data)
        return decoded.data
    }

    func createLocation(_ body: [String: Any]) async throws -> Location {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/locations") else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        struct SingleResponse: Codable {
            let data: Location
        }

        let decoded = try JSONDecoder().decode(SingleResponse.self, from: data)
        return decoded.data
    }

    func updateLocation(id: UUID, body: [String: Any]) async throws -> Location {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/locations/\(id.uuidString)") else {
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

        struct SingleResponse: Codable { let data: Location }
        return try JSONDecoder().decode(SingleResponse.self, from: data).data
    }

    func deleteLocation(id: UUID) async throws {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/locations/\(id.uuidString)") else {
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
