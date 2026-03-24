//
//  DependencyContainer.swift
//  Sidequest
//

import Foundation

/// Zentraler Container für Dependency Injection.
final class DependencyContainer: ObservableObject {
    let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
}
