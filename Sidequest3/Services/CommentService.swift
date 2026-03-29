//
//  CommentService.swift
//  Sidequest
//

import Foundation

final class CommentService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchComments(locationId: UUID) async throws -> [Comment] {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/locations/\(locationId.uuidString)/comments") else {
            throw AppError.unknown(underlying: nil)
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        let decoded = try JSONDecoder.api.decode(CommentsResponse.self, from: data)
        return decoded.data
    }

    func createComment(locationId: UUID, userId: UUID, text: String) async throws -> Comment {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/comments") else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "location_id": locationId.uuidString,
            "user_id": userId.uuidString,
            "text": text
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        struct SingleResponse: Codable { let data: Comment }
        return try JSONDecoder.api.decode(SingleResponse.self, from: data).data
    }
}
