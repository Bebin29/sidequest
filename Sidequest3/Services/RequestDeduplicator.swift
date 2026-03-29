//
//  RequestDeduplicator.swift
//  Sidequest
//

import Foundation

/// Verhindert doppelte gleichzeitige Netzwerk-Requests fuer denselben Endpoint.
/// Wenn ein Request fuer eine URL bereits in-flight ist, wird der gleiche Task zurueckgegeben
/// statt einen neuen Request zu starten. Arbeitet auf Data-Ebene.
actor RequestDeduplicator {

    private var inFlight: [String: Task<Data, Error>] = [:]

    /// Fuehrt den Request aus, oder gibt die Daten des bereits laufenden Requests zurueck.
    func deduplicate(key: String, perform: @escaping () async throws -> Data) async throws -> Data {
        // Pruefen ob bereits ein Request fuer diesen Key laeuft
        if let existing = inFlight[key] {
            return try await existing.value
        }

        // Neuen Task erstellen
        let task = Task<Data, Error> {
            defer { Task { await self.removeInFlight(key: key) } }
            return try await perform()
        }

        inFlight[key] = task

        do {
            return try await task.value
        } catch {
            inFlight.removeValue(forKey: key)
            throw error
        }
    }

    private func removeInFlight(key: String) {
        inFlight.removeValue(forKey: key)
    }
}
