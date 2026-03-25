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

    func fetchLocations() async throws -> [Location] {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/locations") else {
            throw AppError.unknown(underlying: nil)
        }

        let (data, response) = try await session.data(from: url)

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
}
