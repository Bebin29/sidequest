import SwiftUI
import MapKit
import CoreLocation
import Combine

// Autocomplete Service
class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {

    @Published var results: [SearchResult] = []
    var userLocation: CLLocation?

    private let completer = MKLocalSearchCompleter()

    struct SearchResult: Identifiable, Hashable {
        let id = UUID()
        let completion: MKLocalSearchCompletion
        var distance: CLLocationDistance?

        var formattedDistance: String? {
            guard let distance else { return nil }
            if distance < 1000 {
                return "\(Int(distance)) m"
            } else {
                return String(format: "%.1f km", distance / 1000)
            }
        }

        static func == (lhs: SearchResult, rhs: SearchResult) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .pointOfInterest
    }

    func update(query: String) {
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let completions = completer.results
        guard let userLoc = userLocation else {
            results = completions.map { SearchResult(completion: $0, distance: nil) }
            return
        }

        // Resolve distances
        let group = DispatchGroup()
        var searchResults: [SearchResult] = []

        for completion in completions {
            group.enter()
            let request = MKLocalSearch.Request(completion: completion)
            let search = MKLocalSearch(request: request)
            search.start { response, _ in
                var dist: CLLocationDistance?
                if let coord = response?.mapItems.first?.placemark.location {
                    dist = userLoc.distance(from: coord)
                }
                searchResults.append(SearchResult(completion: completion, distance: dist))
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.results = searchResults.sorted { ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude) }
        }
    }
}
