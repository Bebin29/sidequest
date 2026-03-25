//
//  DependencyContainer.swift
//  Sidequest
//

import Foundation
import Combine

/// Zentraler Container für Dependency Injection.
final class DependencyContainer: ObservableObject {
    let networkService: NetworkServiceProtocol
    let objectWillChange = ObservableObjectPublisher()

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
}
