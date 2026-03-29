//
//  CacheService.swift
//  Sidequest
//

import Foundation

/// Thread-safe In-Memory Cache mit TTL fuer API-Responses.
/// Verwendet einen Actor fuer sichere Concurrent-Zugriffe.
actor CacheService {

    struct Entry {
        let data: Data
        let timestamp: Date
    }

    /// Maximale Cache-Dauer pro Endpoint-Typ (Sekunden)
    enum TTL {
        static let feed: TimeInterval = 30
        static let profile: TimeInterval = 300  // 5 min
        static let friends: TimeInterval = 60
        static let locations: TimeInterval = 60
        static let comments: TimeInterval = 30
        static let defaultTTL: TimeInterval = 60
    }

    private var store: [String: Entry] = [:]
    private let maxEntries = 100

    // MARK: - Public API

    /// Cached Daten holen, wenn noch gueltig (innerhalb TTL).
    func get<T: Decodable>(key: String, maxAge: TimeInterval? = nil) -> T? {
        guard let entry = store[key] else { return nil }

        let ttl = maxAge ?? ttlForKey(key)
        guard Date().timeIntervalSince(entry.timestamp) < ttl else {
            store.removeValue(forKey: key)
            return nil
        }

        return try? JSONDecoder.api.decode(T.self, from: entry.data)
    }

    /// Daten im Cache speichern.
    func set(key: String, data: Data) {
        // Eviction wenn Cache zu gross
        if store.count >= maxEntries {
            evictOldest()
        }
        store[key] = Entry(data: data, timestamp: Date())
    }

    /// Einzelnen Key invalidieren.
    func invalidate(key: String) {
        store.removeValue(forKey: key)
    }

    /// Keys die mit einem Prefix beginnen invalidieren (z.B. alle /api/locations/*).
    func invalidatePrefix(_ prefix: String) {
        store.keys.filter { $0.contains(prefix) }.forEach { store.removeValue(forKey: $0) }
    }

    /// Gesamten Cache leeren.
    func invalidateAll() {
        store.removeAll()
    }

    // MARK: - Private

    private func ttlForKey(_ key: String) -> TimeInterval {
        if key.contains("/api/feed") { return TTL.feed }
        if key.contains("/api/users/") { return TTL.profile }
        if key.contains("/api/friends") { return TTL.friends }
        if key.contains("/api/locations") { return TTL.locations }
        if key.contains("/api/comments") { return TTL.comments }
        return TTL.defaultTTL
    }

    private func evictOldest() {
        guard let oldest = store.min(by: { $0.value.timestamp < $1.value.timestamp }) else { return }
        store.removeValue(forKey: oldest.key)
    }
}
