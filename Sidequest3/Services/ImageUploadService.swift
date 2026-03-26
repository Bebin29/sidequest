//
//  ImageUploadService.swift
//  Sidequest
//

import Foundation
import UIKit

final class ImageUploadService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func upload(image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw AppError.unknown(underlying: nil)
        }

        let base64 = data.base64EncodedString()

        guard let url = URL(string: "\(Constants.API.baseURL)/api/uploads") else {
            throw AppError.unknown(underlying: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "image": base64,
            "extension": "jpg"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (responseData, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }

        struct UploadResponse: Codable { let url: String }
        let decoded = try JSONDecoder().decode(UploadResponse.self, from: responseData)
        return decoded.url
    }
}
