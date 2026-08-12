import SwiftUI
import MapKit
import CoreLocation
import Combine

class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {

    @Published var results: [SearchResult] = []

    private let completer = MKLocalSearchCompleter()

    struct SearchResult: Identifiable, Hashable {
        let id = UUID()
        let completion: MKLocalSearchCompletion

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
        results = completer.results.map { SearchResult(completion: $0) }
    }
}
