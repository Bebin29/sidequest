//
//  FeedService.swift
//  Sidequest
//

import Foundation

struct FeedResponse: Codable {
    let data: [Location]
    let count: Int
    let hasMore: Bool
}

final class FeedService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchFeed(userId: UUID, limit: Int = 20, offset: Int = 0) async throws -> FeedResponse {
        var components = URLComponents(string: "\(Constants.API.baseURL)/api/feed")!
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userId.uuidString),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        guard let url = components.url else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .useProtocolCachePolicy

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        return try JSONDecoder.api.decode(FeedResponse.self, from: data)
    }
}
