//
//  CachedAsyncImage.swift
//  Sidequest
//

import SwiftUI
import ImageIO

/// Globaler Image-Download-Throttler: begrenzt parallele Downloads.
private actor ImageDownloadThrottle {
    static let shared = ImageDownloadThrottle()

    private var activeCount = 0
    private let maxConcurrent = 6
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        if activeCount < maxConcurrent {
            activeCount += 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func release() {
        activeCount -= 1
        if let next = waiters.first {
            waiters.removeFirst()
            activeCount += 1
            next.resume()
        }
    }
}

private enum ImageCacheStore {
    static let cache: URLCache = {
        URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        )
    }()

    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        // useProtocolCachePolicy statt returnCacheDataElseLoad —
        // verhindert dass kaputte/unvollstaendige Responses ewig aus dem Cache serviert werden
        config.requestCachePolicy = .useProtocolCachePolicy
        config.httpMaximumConnectionsPerHost = 6
        return URLSession(configuration: config)
    }()

    /// Downsampled UIImage aus Data erzeugen — spart 90%+ RAM.
    /// Fallback auf UIImage(data:) wenn CGImageSource fehlschlaegt.
    static func decodeImage(from data: Data, maxPixelSize: Int = 800) -> UIImage? {
        // Pruefen ob Daten ueberhaupt ein Bild sein koennten (min. JPEG/PNG Header)
        guard data.count > 12 else { return nil }

        // Versuch 1: CGImageSource Downsampling (speichereffizient)
        if let source = CGImageSourceCreateWithData(data as CFData, nil) {
            let options: [CFString: Any] = [
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                return UIImage(cgImage: cgImage)
            }
        }

        // Versuch 2: Normales UIImage(data:) als Fallback
        if let fullImage = UIImage(data: data) {
            // Wenn moeglich verkleinern um RAM zu sparen
            let maxDim = CGFloat(maxPixelSize)
            let size = fullImage.size
            if max(size.width, size.height) > maxDim {
                let scale = maxDim / max(size.width, size.height)
                let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
                let renderer = UIGraphicsImageRenderer(size: targetSize)
                return renderer.image { _ in
                    fullImage.draw(in: CGRect(origin: .zero, size: targetSize))
                }
            }
            return fullImage
        }

        return nil
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var failed = false
    @State private var retryCount = 0

    var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
            } else if failed {
                placeholder()
                    .onTapGesture {
                        retry()
                    }
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url, image == nil else { return }
        guard !isLoading else { return }
        isLoading = true
        failed = false

        let request = URLRequest(url: url)

        // Check cache first (kein Throttle noetig)
        if let cached = ImageCacheStore.cache.cachedResponse(for: request),
           let uiImage = ImageCacheStore.decodeImage(from: cached.data) {
            self.image = uiImage
            isLoading = false
            return
        }

        // Throttle: max 6 gleichzeitige Downloads
        await ImageDownloadThrottle.shared.acquire()
        defer { Task { await ImageDownloadThrottle.shared.release() } }

        do {
            let (data, response) = try await ImageCacheStore.session.data(for: request)

            // Nur cachen und decodieren wenn HTTP 200 und genuegend Daten
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  data.count > 100 else {
                failed = true
                isLoading = false
                return
            }

            if let uiImage = ImageCacheStore.decodeImage(from: data) {
                let cachedResponse = CachedURLResponse(response: response, data: data)
                ImageCacheStore.cache.storeCachedResponse(cachedResponse, for: request)
                self.image = uiImage
            } else {
                failed = true
            }
        } catch {
            if retryCount < 2 {
                retryCount += 1
                try? await Task.sleep(for: .milliseconds(500 * retryCount))
                isLoading = false
                await loadImage()
                return
            }
            failed = true
        }
        isLoading = false
    }

    private func retry() {
        retryCount = 0
        failed = false
        Task { await loadImage() }
    }
}
