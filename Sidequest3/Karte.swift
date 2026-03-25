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
    @State private var selectedLocation: Location?
    var userId: UUID?

    var body: some View {
        NavigationStack {
        ZStack {
            Map(position: $locationManager.position, selection: $selectedLocation) {
                UserAnnotation()
                ForEach(mapViewModel.locations) { location in
                    Marker(location.name, coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ))
                    .tag(location)
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
        .navigationDestination(item: $selectedLocation) { location in
            LocationDetailView(location: location, currentUserId: userId)
        }
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
    @State private var selectedItem: MKMapItem?
    @State private var selectedCategory = ""
    @Bindable var mapViewModel: MapViewModel
    var userId: UUID?
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            if let item = selectedItem {
                AddLocationFormView(
                    mapItem: item,
                    category: selectedCategory,
                    mapViewModel: mapViewModel,
                    userId: userId,
                    onDismiss: onDismiss,
                    onBack: { selectedItem = nil }
                )
            } else {
                VStack {
                    TextField("Ort suchen", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .onChange(of: searchText) { _, newValue in
                            completer.update(query: newValue)
                        }

                    List(completer.results, id: \.self) { completion in
                        Button {
                            resolveAndSelect(completion)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(completion.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(completion.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                .navigationTitle("Ort suchen")
            }
        }
    }

    func resolveAndSelect(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        search.start { response, error in
            guard let item = response?.mapItems.first else { return }
            selectedCategory = mapCategory(from: item.pointOfInterestCategory)
            selectedItem = item
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

struct AddLocationFormView: View {
    let mapItem: MKMapItem
    let category: String
    @Bindable var mapViewModel: MapViewModel
    var userId: UUID?
    var onDismiss: () -> Void
    var onBack: () -> Void

    @State private var description = ""
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var showPreview = false
    @State private var isUploading = false

    private let imageUploadService = ImageUploadService()

    var body: some View {
        List {
            Section("Ort") {
                Text(mapItem.name ?? "Unbekannt")
                    .font(.headline)
                if mapItem.placemark.location != nil {
                    Text(mapItem.placemark.title ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(category)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }

            Section("Beschreibung") {
                TextField("Warum empfiehlst du diesen Ort?", text: $description, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Fotos (\(selectedImages.count))") {
                if !selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    Button {
                                        selectedImages.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white, .red)
                                            .font(.title3)
                                    }
                                    .offset(x: 6, y: -6)
                                }
                            }
                        }
                    }
                }

                Button {
                    showImagePicker = true
                } label: {
                    Label("Foto hinzufügen", systemImage: "camera")
                }
            }

            // Preview Button
            if !selectedImages.isEmpty || !description.isEmpty {
                Section {
                    Button {
                        showPreview = true
                    } label: {
                        Label("Vorschau anzeigen", systemImage: "eye")
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    if isUploading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Ort hinzufügen")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                }
                .disabled(isUploading)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Ort hinzufügen")
        .sheet(isPresented: $showPreview) {
            PostPreviewView(
                name: mapItem.name ?? "Unbekannt",
                address: mapItem.placemark.title ?? "",
                category: category,
                description: description,
                image: selectedImages.first
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Zurück") { onBack() }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerAppend(images: $selectedImages)
        }
    }

    func submit() async {
        guard let coordinate = mapItem.placemark.location?.coordinate else { return }
        isUploading = true

        var imageUrls: [String] = []

        for image in selectedImages {
            do {
                let url = try await imageUploadService.upload(image: image)
                imageUrls.append(url)
            } catch {
                print("Image upload failed:", error)
            }
        }

        let address = [mapItem.placemark.thoroughfare, mapItem.placemark.subThoroughfare, mapItem.placemark.postalCode, mapItem.placemark.locality]
            .compactMap { $0 }.joined(separator: " ")

        var body: [String: Any] = [
            "name": mapItem.name ?? "Unbekannt",
            "address": address.isEmpty ? (mapItem.placemark.title ?? "") : address,
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "category": category,
            "created_by": userId?.uuidString ?? ""
        ]

        if !description.isEmpty {
            body["description"] = description
        }
        if !imageUrls.isEmpty {
            body["image_urls"] = imageUrls
        }

        let success = await mapViewModel.addLocation(body)
        isUploading = false
        if success {
            onDismiss()
        }
    }
}

#Preview {
    Home(authViewModel: AuthViewModel())
}
