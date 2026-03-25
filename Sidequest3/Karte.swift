import SwiftUI
import MapKit
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var hasSetInitialPosition = false

    @Published var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first, !hasSetInitialPosition else { return }
        hasSetInitialPosition = true
        manager.stopUpdatingLocation()

        DispatchQueue.main.async {
            self.position = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
}

struct Karte: View {

    @StateObject private var locationManager = LocationManager()
    @State private var mapViewModel = MapViewModel()
    @State private var showSearchSheet = false
    var userId: UUID?

    var body: some View {
        ZStack {
            Map(position: $locationManager.position) {
                UserAnnotation()
                ForEach(mapViewModel.locations) { location in
                    Marker(location.name, coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ))
                }
            }
            .ignoresSafeArea()

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button(action: {
                        showSearchSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showSearchSheet) {
            PlaceSearchView(mapViewModel: mapViewModel, userId: userId) {
                showSearchSheet = false
            }
        }
        .task {
            guard let userId else { return }
            await mapViewModel.loadLocations(userId: userId)
        }
    }
}

// Autocomplete Service
class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {

    @Published var results: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .pointOfInterest
    }

    func update(query: String) {
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }
}

// Suche mit Live Vorschlägen
struct PlaceSearchView: View {

    @State private var searchText = ""
    @StateObject private var completer = SearchCompleter()
    @Bindable var mapViewModel: MapViewModel
    var userId: UUID?
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack {

                TextField("Ort suchen", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onChange(of: searchText) { _, newValue in
                        completer.update(query: newValue)
                    }

                List(completer.results, id: \.self) { completion in
                    VStack(alignment: .leading) {
                        Text(completion.title)
                            .font(.headline)

                        Text(completion.subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)

                        Button("Hinzufügen") {
                            searchAndAdd(completion)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 5)
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Ort suchen")
        }
    }

    func searchAndAdd(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        search.start { response, error in
            guard let item = response?.mapItems.first,
                  let coordinate = item.placemark.location?.coordinate else { return }

            let address = [item.placemark.thoroughfare, item.placemark.subThoroughfare, item.placemark.postalCode, item.placemark.locality]
                .compactMap { $0 }.joined(separator: " ")

            let body: [String: Any] = [
                "name": item.name ?? completion.title,
                "address": address.isEmpty ? completion.subtitle : address,
                "latitude": coordinate.latitude,
                "longitude": coordinate.longitude,
                "category": mapCategory(from: item.pointOfInterestCategory),
                "created_by": userId?.uuidString ?? ""
            ]

            Task {
                let success = await mapViewModel.addLocation(body)
                if success {
                    onDismiss()
                }
            }
        }
    }

    func mapCategory(from category: MKPointOfInterestCategory?) -> String {
        guard let category else { return "Sonstiges" }
        switch category {
        case .restaurant: return "Restaurant"
        case .cafe: return "Café"
        case .nightlife: return "Bar"
        case .bakery: return "Bäckerei"
        case .park: return "Park"
        case .museum: return "Museum"
        case .store: return "Shopping"
        default: return "Sonstiges"
        }
    }
}

#Preview {
    Karte()
}
