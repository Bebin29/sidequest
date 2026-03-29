//
//  NetworkService.swift
//  Sidequest
//

import Foundation
import os

final class NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let cache = CacheService()
    private let deduplicator = RequestDeduplicator()

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Simple request (backward-compatible)

    func request<T: Decodable>(endpoint: String, method: HTTPMethod) async throws -> T {
        try await request(endpoint: endpoint, method: method, body: nil, queryItems: nil, cachePolicy: .networkOnly)
    }

    // MARK: - Extended request with body, query params, caching, dedup

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        cachePolicy: APICachePolicy = .networkOnly
    ) async throws -> T {

        // URL mit Query-Items aufbauen
        guard var components = URLComponents(string: "\(Constants.API.baseURL)/\(endpoint)") else {
            throw AppError.unknown(underlying: nil)
        }
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw AppError.unknown(underlying: nil)
        }

        let cacheKey = url.absoluteString

        // Cache pruefen (nur fuer GET-Requests)
        if method == .get {
            switch cachePolicy {
            case .cacheFirst, .cacheAndRefresh:
                if let cached: T = await cache.get(key: cacheKey) {
                    if cachePolicy == .cacheAndRefresh {
                        // Im Hintergrund aktualisieren
                        Task { [weak self] in
                            guard let self else { return }
                            _ = try? await self.fetchData(url: url, method: method, body: body)
                        }
                    }
                    return cached
                }
            case .networkOnly:
                break
            }
        }

        // GET-Requests deduplizieren
        let data: Data
        if method == .get {
            data = try await deduplicator.deduplicate(key: cacheKey) { [self] in
                try await self.fetchData(url: url, method: method, body: body)
            }
        } else {
            data = try await fetchData(url: url, method: method, body: body)
        }

        // Erfolgreiche Antwort cachen (nur GET)
        if method == .get {
            await cache.set(key: cacheKey, data: data)
        }

        do {
            return try JSONDecoder.api.decode(T.self, from: data)
        } catch {
            throw AppError.decoding(underlying: error)
        }
    }

    // MARK: - Cache-Invalidierung (fuer Mutationen)

    func invalidateCache(prefix: String) async {
        await cache.invalidatePrefix(prefix)
    }

    func invalidateAllCache() async {
        await cache.invalidateAll()
    }

    // MARK: - Private: Netzwerk-Request ausfuehren

    private func fetchData(
        url: URL,
        method: HTTPMethod,
        body: (any Encodable)?
    ) async throws -> Data {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.timeoutInterval = Constants.API.timeoutInterval

        if let body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder.api.encode(AnyEncodable(body))
        }

        Log.network.info("Request: \(method.rawValue) \(url.path())")

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.unknown(underlying: nil)
            }

            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw AppError.unauthorized
            case 404:
                throw AppError.notFound
            default:
                throw AppError.server(statusCode: httpResponse.statusCode, message: nil)
            }
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.network(underlying: error)
        }
    }
}

// MARK: - Type-erased Encodable wrapper

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        _encode = { encoder in try value.encode(to: encoder) }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
