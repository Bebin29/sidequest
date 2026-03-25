//
//  MapViewModel.swift
//  Sidequest
//

import Foundation

@Observable
final class MapViewModel {
    var locations: [Location] = []
    var isLoading = false
    var errorMessage: String?

    private let locationService = LocationService()

    func loadLocations(userId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            locations = try await locationService.fetchLocations(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func addLocation(_ body: [String: Any]) async -> Bool {
        do {
            let newLocation = try await locationService.createLocation(body)
            locations.append(newLocation)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
