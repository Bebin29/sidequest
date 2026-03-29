//
//  AuthService.swift
//  Sidequest
//

import Foundation
import AuthenticationServices

final class AuthService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func signInWithApple(appleUserId: String, email: String?, displayName: String?) async throws -> (User, Bool) {
        guard let url = URL(string: "\(Constants.API.baseURL)/api/auth/apple") else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any?] = [
            "appleUserId": appleUserId,
            "email": email,
            "displayName": displayName
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        struct AuthResponse: Codable {
            let data: User
            let isNewUser: Bool
        }

        let decoded = try JSONDecoder.api.decode(AuthResponse.self, from: data)
        return (decoded.data, decoded.isNewUser)
    }
}
