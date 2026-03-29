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
        guard let imageData = resized.jpegData(compressionQuality: 0.7) else {
            throw AppError.unknown(underlying: nil)
        }

        guard let url = URL(string: "\(Constants.API.baseURL)/api/uploads") else {
            throw AppError.unknown(underlying: nil)
        }

        // Multipart/form-data statt Base64 JSON (33% weniger Bandbreite)
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.API.timeoutInterval

        var body = Data()

        // Extension-Feld
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"extension\"\r\n\r\n".data(using: .utf8)!)
        body.append("jpg\r\n".data(using: .utf8)!)

        // Bild-Datei
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // End-Boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        Log.network.info("Upload: multipart \(imageData.count) bytes (was \(imageData.count * 4 / 3) as base64)")

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
