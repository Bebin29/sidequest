//
//  LocationService.swift
//  Sidequest
//

import Foundation

struct LocationFilter: Equatable {
    var category: String?
    var search: String?
    var latitude: Double?
    var longitude: Double?
    var radiusMeters: Double?

    var isEmpty: Bool {
        category == nil && (search ?? "").isEmpty && radiusMeters == nil
    }
}

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

    func fetchLocations(userId: UUID, filter: LocationFilter = LocationFilter()) async throws -> [Location] {
        // swiftlint:disable:next force_unwrapping
        var components = URLComponents(string: "\(Constants.API.baseURL)/api/locations")!
        var queryItems = [URLQueryItem(name: "user_id", value: userId.uuidString)]

        if let category = filter.category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        if let search = filter.search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        if let lat = filter.latitude, let lon = filter.longitude, let radius = filter.radiusMeters {
            queryItems.append(URLQueryItem(name: "lat", value: String(lat)))
            queryItems.append(URLQueryItem(name: "lon", value: String(lon)))
            queryItems.append(URLQueryItem(name: "radius", value: String(radius)))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
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

    func fetchCategories() async throws -> [String] {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/categories") else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        struct CategoriesResponse: Codable { let data: [String] }
        return try JSONDecoder().decode(CategoriesResponse.self, from: data).data
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
