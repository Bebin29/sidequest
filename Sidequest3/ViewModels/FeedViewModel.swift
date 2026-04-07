//
//  FeedViewModel.swift
//  Sidequest
//

import Foundation
import SwiftUI
import CoreLocation

@MainActor
@Observable
final class FeedViewModel {
    var locations: [Location] = []
    var isLoading = false
    var isLoadingMore = false
    var hasMore = true
    var errorMessage: String?

    // Carousel state
    var currentIndex: Int = 0
    var dominantColors: [UUID: Color] = [:]

    // Distance sorting
    var userLocation: CLLocation?

    private let feedService = FeedService()
    private let pageSize = 200

    // MARK: - Dominant Color

    var currentDominantColor: Color? {
        guard currentIndex >= 0, currentIndex < locations.count else { return nil }
        return dominantColors[locations[currentIndex].id]
    }

    func setDominantColor(_ color: Color, for locationId: UUID) {
        dominantColors[locationId] = color
    }

    // MARK: - Location

    func fetchLocation() async {
        let manager = CLLocationManager()
        let status = manager.authorizationStatus

        // Kein Standort verfügbar → Feed wird nach Datum sortiert
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            print("[Feed] Standort nicht erlaubt (\(status.rawValue)) – Sortierung nach Datum")
            return
        }

        // Fallback: letzter bekannter Standort
        let fallback = manager.location

        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if let location = update.location {
                    userLocation = location
                    print("[Feed] Standort geholt: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    return
                }
            }
        } catch {
            print("[Feed] Standort-Fehler: \(error.localizedDescription)")
        }

        // Fallback falls liveUpdates fehlschlägt
        if userLocation == nil {
            userLocation = fallback
            print("[Feed] Fallback-Standort: \(fallback?.coordinate.latitude ?? 0), \(fallback?.coordinate.longitude ?? 0)")
        }
    }

    func sortByDistance() {
        guard let userLocation else {
            // Kein Standort → nach Erstelldatum sortieren (neu → alt)
            locations.sort { $0.createdAt > $1.createdAt }
            print("[Feed] Kein Standort – Sortierung nach Datum (neueste zuerst)")
            return
        }
        locations.sort { loc1, loc2 in
            let d1 = CLLocation(latitude: loc1.latitude, longitude: loc1.longitude)
                .distance(from: userLocation)
            let d2 = CLLocation(latitude: loc2.latitude, longitude: loc2.longitude)
                .distance(from: userLocation)
            return d1 < d2
        }
        print("[Feed] Sortiert nach Entfernung – nächster Ort: \(locations.first?.name ?? "–")")
    }

    // MARK: - Feed Loading

    func loadFeed(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await feedService.fetchFeed(userId: userId, limit: pageSize, offset: 0)
            locations = response.data
            hasMore = response.hasMore
            sortByDistance()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore(userId: UUID) async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let response = try await feedService.fetchFeed(userId: userId, limit: pageSize, offset: locations.count)
            locations.append(contentsOf: response.data)
            hasMore = response.hasMore
            sortByDistance()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

