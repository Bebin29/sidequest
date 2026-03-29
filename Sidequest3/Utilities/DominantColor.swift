//
//  DominantColor.swift
//  Sidequest
//
//  Extracts the dominant color from an image for adaptive backgrounds.
//

import SwiftUI
import UIKit

// MARK: - Dominant Color Cache

actor DominantColorCache {
    static let shared = DominantColorCache()

    private var cache: [String: Color] = [:]

    func color(for key: String) -> Color? {
        cache[key]
    }

    func store(_ color: Color, for key: String) {
        cache[key] = color
    }
}

// MARK: - UIImage Extension

extension UIImage {
    /// Computes the average color by downscaling to a small size and averaging all pixels.
    var dominantColor: Color? {
        let size = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: size))

        guard let context = UIGraphicsGetCurrentContext(),
              let data = context.makeImage()?.dataProvider?.data,
              let pointer = CFDataGetBytePtr(data) else {
            return nil
        }

        let length = CFDataGetLength(data)
        let bytesPerPixel = 4
        let pixelCount = length / bytesPerPixel

        guard pixelCount > 0 else { return nil }

        var totalR: Double = 0
        var totalG: Double = 0
        var totalB: Double = 0

        for i in 0..<pixelCount {
            let offset = i * bytesPerPixel
            totalR += Double(pointer[offset])
            totalG += Double(pointer[offset + 1])
            totalB += Double(pointer[offset + 2])
        }

        let count = Double(pixelCount)
        return Color(
            red: totalR / count / 255.0,
            green: totalG / count / 255.0,
            blue: totalB / count / 255.0
        )
    }
}

// MARK: - Dominant Color Loader

enum DominantColorLoader {
    /// Extracts and caches the dominant color from an image at the given URL.
    static func dominantColor(from url: URL) async -> Color? {
        let key = url.absoluteString

        // Check cache first
        if let cached = await DominantColorCache.shared.color(for: key) {
            return cached
        }

        // Download + extract
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data),
              let color = image.dominantColor else {
            return nil
        }

        await DominantColorCache.shared.store(color, for: key)
        return color
    }

    /// Extracts dominant color directly from a UIImage (no download needed).
    static func dominantColor(from image: UIImage) async -> Color? {
        guard let color = image.dominantColor else { return nil }
        return color
    }

    /// Extracts and caches dominant color from a UIImage with a URL key.
    static func dominantColor(from image: UIImage, cacheKey: String) async -> Color? {
        if let cached = await DominantColorCache.shared.color(for: cacheKey) {
            return cached
        }
        guard let color = image.dominantColor else { return nil }
        await DominantColorCache.shared.store(color, for: cacheKey)
        return color
    }
}
