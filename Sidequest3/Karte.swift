import SwiftUI
import MapKit
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var hasSetInitialPosition = false
    var positionOverridden = false
    @Published var lastLocation: CLLocation?
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
            self.lastLocation = location
            if !self.positionOverridden {
                self.position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
    }
    func centerOnUser() {
        guard let location = lastLocation else { return }

        withAnimation(.easeInOut(duration: 0.6)) {
            self.position = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                )
            )
        }
    }
}

struct Karte: View {

    @StateObject private var locationManager = LocationManager()
    @State private var mapViewModel = MapViewModel()
    @State private var showFilterSheet = false
    @State private var selectedLocationId: UUID?
    @State private var showDetail = false
    
    var userId: UUID?
    @Binding var focusLocation: Location?

    var body: some View {
        ZStack {
            Map(position: $locationManager.position, selection: $selectedLocationId) {
                UserAnnotation()
                ForEach(mapViewModel.locations) { location in
                    Annotation(location.name, coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                            
                    )) {
                        LocationPin(imageUrl: location.imageUrls.first)
                            .tag(location.id)
                    }
                }
            }
            .ignoresSafeArea(.container)
            .onChange(of: selectedLocationId) { _, newValue in
                if newValue != nil {
                    showDetail = true
                }
            }
            .onChange(of: focusLocation, initial: true) { _, location in
                guard let location else { return }
                locationManager.positionOverridden = true
                withAnimation(.easeInOut(duration: 0.6)) {
                    locationManager.position = .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                    selectedLocationId = location.id
                }
                focusLocation = nil
            }

            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                  
                    VStack(spacing: 12) {

                        
                        
                        
                        
                        
                        Button {
                            showFilterSheet = true
                        } label: {
                            Image(systemName: mapViewModel.filter.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(0.25), lineWidth: 1)
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .white.opacity(0.35),
                                                    .clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .blendMode(.overlay)
                                )
                                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                        }
                        
                        Button {
                            locationManager.centerOnUser()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.indigo)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(0.25), lineWidth: 1)
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .white.opacity(0.35),
                                                    .clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .blendMode(.overlay)
                                )
                                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                        }
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        /*
                         Button(action: {
                             
                         }) {
                             Image(systemName: mapViewModel.filter.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                                 .font(.title2)
                                 .foregroundColor(mapViewModel.filter.isEmpty ? Color.indigo : .white)
                                 .frame(width: 50, height: 50)
                                 .background(mapViewModel.filter.isEmpty ? Color.white : Color.indigo)
                                 .clipShape(Circle())
                                 .shadow(radius: 5)
                                 .fontWeight(.semibold)
                         }

                         Button(action: {
                             
                         }) {
                             Image(systemName: "location.fill")
                                 .font(.title2)
                                 .foregroundColor(Color.indigo)
                                 .frame(width: 50, height: 50)
                                 .background(Color.white)
                                 .clipShape(Circle())
                                 .shadow(radius: 5)
                                 .fontWeight(.semibold)
                         }
                         */

                        
                    }.padding()
                    
                }
            }
        }
     
        .sheet(isPresented: $showFilterSheet) {
            LocationFilterView(
                mapViewModel: mapViewModel,
                userLatitude: locationManager.lastLocation?.coordinate.latitude,
                userLongitude: locationManager.lastLocation?.coordinate.longitude,
                onApply: {
                    guard let userId else { return }
                    Task { await mapViewModel.loadLocations(userId: userId) }
                }
            )
        }
        .task {
            guard let userId else { return }
            await mapViewModel.loadLocations(userId: userId)
        }
        .sheet(isPresented: $showDetail, onDismiss: {
            selectedLocationId = nil
            guard let userId else { return }
            Task { await mapViewModel.loadLocations(userId: userId) }
        }) {
            if let location = mapViewModel.locations.first(where: { $0.id == selectedLocationId }) {
                NavigationStack {
                    LocationDetailView(location: location, currentUserId: userId, onDelete: {
                        mapViewModel.locations.removeAll { $0.id == location.id }
                        showDetail = false
                    }, onUpdate: { updated in
                        if let index = mapViewModel.locations.firstIndex(where: { $0.id == updated.id }) {
                            mapViewModel.locations[index] = updated
                        }
                    })
                }
            }
        }
    }
}

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

// Suche mit Live Vorschlägen


