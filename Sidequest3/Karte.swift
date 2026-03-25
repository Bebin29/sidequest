import SwiftUI
import MapKit
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

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
        guard let location = locations.first else { return }

        DispatchQueue.main.async {
            self.position = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
}

struct PlaceMarker: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct Karte: View {

    @StateObject private var locationManager = LocationManager()
    @State private var showSearchSheet = false

    let places = [
        PlaceMarker(coordinate: CLLocationCoordinate2D(latitude: 53.49987, longitude: 10.00258)),
        PlaceMarker(coordinate: CLLocationCoordinate2D(latitude: 53.49987, longitude: 10.00268)),
        PlaceMarker(coordinate: CLLocationCoordinate2D(latitude: 53.49987, longitude: 10.00278))
    ]

    var body: some View {
        ZStack {

            Map(position: $locationManager.position) {
                UserAnnotation()
                ForEach(places) { place in
                    Marker("", coordinate: place.coordinate)
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
            PlaceSearchView()
        }
    }
}

// 🔥 NEU: Autocomplete Service
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

// 🔍 Suche mit Live Vorschlägen
struct PlaceSearchView: View {

    @State private var searchText = ""
    @StateObject private var completer = SearchCompleter()

    var body: some View {
        NavigationStack {
            VStack {

                TextField("Ort suchen", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onChange(of: searchText) { newValue in
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

    // 🔁 wandelt Vorschlag → echte Location
    func searchAndAdd(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        search.start { response, error in
            guard let item = response?.mapItems.first else { return }
            print("Selected:", item.name ?? "")
        }
    }
}

#Preview {
    Home(authViewModel: AuthViewModel())
}
