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
        let resized = Self.resize(image, maxDimension: 1920)
        guard let data = resized.jpegData(compressionQuality: 0.7) else {
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

    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }

        let scale: CGFloat
        if size.width > size.height {
            scale = maxDimension / size.width
        } else {
            scale = maxDimension / size.height
        }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
