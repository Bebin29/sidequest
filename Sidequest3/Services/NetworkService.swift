//
//  NetworkService.swift
//  Sidequest
//

import Foundation

final class NetworkService: NetworkServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(endpoint: String, method: HTTPMethod) async throws -> T {
        guard let url = URL(string: "\(Constants.API.baseURL)/\(endpoint)") else {
            throw AppError.unknown(underlying: nil)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.timeoutInterval = Constants.API.timeoutInterval

        Log.network.info("Request: \(method.rawValue) \(endpoint)")

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.unknown(underlying: nil)
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw AppError.decoding(underlying: error)
                }
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
