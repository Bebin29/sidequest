//
//  CachedAsyncImage.swift
//  Sidequest
//

import SwiftUI

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
        return URLSession(configuration: config)
    }()
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    var onLoad: ((UIImage) -> Void)? = nil
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
            // Reset state when URL changes (MapKit annotation view recycling)
            image = nil
            isLoading = false
            failed = false
            retryCount = 0
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url else { return }
        guard !isLoading else { return }
        isLoading = true
        failed = false

        let request = URLRequest(url: url)

        // Check cache first
        if let cached = ImageCacheStore.cache.cachedResponse(for: request),
           let uiImage = UIImage(data: cached.data) {
            self.image = uiImage
            onLoad?(uiImage)
            isLoading = false
            return
        }

        do {
            let (data, response) = try await ImageCacheStore.session.data(for: request)
            if let uiImage = UIImage(data: data) {
                // Store in cache
                let cachedResponse = CachedURLResponse(response: response, data: data)
                ImageCacheStore.cache.storeCachedResponse(cachedResponse, for: request)
                self.image = uiImage
                onLoad?(uiImage)
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
