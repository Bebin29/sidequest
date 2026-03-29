//
//  ServiceProtocol.swift
//  Sidequest
//

import Foundation

/// Shared JSONDecoder mit snake_case Strategy — ersetzt manuelle CodingKeys in allen Models.
extension JSONDecoder {
    static let api: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

/// Shared JSONEncoder mit snake_case Strategy fuer Request Bodies.
extension JSONEncoder {
    static let api: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}

/// Cache-Policy fuer API-Requests.
enum APICachePolicy {
    case networkOnly       // Immer Netzwerk (Standard bisher)
    case cacheFirst        // Cache bevorzugen, Netzwerk als Fallback
    case cacheAndRefresh   // Cache sofort liefern, im Hintergrund aktualisieren
}

/// Basis-Protokoll für alle Services – ermöglicht Dependency Injection und Testbarkeit.
protocol NetworkServiceProtocol {
    func request<T: Decodable>(endpoint: String, method: HTTPMethod) async throws -> T
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: (any Encodable)?,
        queryItems: [URLQueryItem]?,
        cachePolicy: APICachePolicy
    ) async throws -> T
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
