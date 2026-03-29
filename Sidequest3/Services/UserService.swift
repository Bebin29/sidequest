//
//  UserService.swift
//  Sidequest
//

import Foundation

final class UserService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchUsers() async throws -> [User] {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/users") else {
            throw AppError.unknown(underlying: nil)
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        let decoded = try JSONDecoder.api.decode(UsersResponse.self, from: data)
        return decoded.data
    }
}
