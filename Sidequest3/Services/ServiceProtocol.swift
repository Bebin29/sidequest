//
//  ServiceProtocol.swift
//  Sidequest
//

import Foundation

/// Basis-Protokoll für alle Services – ermöglicht Dependency Injection und Testbarkeit.
protocol NetworkServiceProtocol {
    func request<T: Decodable>(endpoint: String, method: HTTPMethod) async throws -> T
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
