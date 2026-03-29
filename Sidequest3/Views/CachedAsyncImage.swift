//
//  CachedAsyncImage.swift
//  Sidequest
//

import SwiftUI

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
        // Warten bis ein Slot frei wird
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
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.httpMaximumConnectionsPerHost = 6
        return URLSession(configuration: config)
    }()
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
           let uiImage = UIImage(data: cached.data) {
            self.image = uiImage
            isLoading = false
            return
        }

        // Throttle: max 4 gleichzeitige Downloads
        await ImageDownloadThrottle.shared.acquire()
        defer { Task { await ImageDownloadThrottle.shared.release() } }

        do {
            let (data, response) = try await ImageCacheStore.session.data(for: request)
            if let uiImage = UIImage(data: data) {
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
