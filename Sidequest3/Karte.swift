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
    @State private var showSearchSheet = false
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

                        Button(action: {
                            showFilterSheet = true
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
                            locationManager.centerOnUser()
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

                        Button(action: {
                            showSearchSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.indigo)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                                .fontWeight(.semibold)
                        }

                    }.padding()
                    
                }
            }
        }
        .sheet(isPresented: $showSearchSheet) {
            PlaceSearchView(mapViewModel: mapViewModel, userId: userId) {
                showSearchSheet = false
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
struct PlaceSearchView: View {

    @State private var searchText = ""
    @StateObject private var completer = SearchCompleter()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedItem: MKMapItem?
    @State private var selectedCategory = ""
    @State private var searchDebounceTask: Task<Void, Never>?
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
                            searchDebounceTask?.cancel()
                            searchDebounceTask = Task {
                                try? await Task.sleep(for: .milliseconds(300))
                                guard !Task.isCancelled else { return }
                                completer.userLocation = locationManager.lastLocation
                                completer.update(query: newValue)
                            }
                        }

                    List(completer.results) { result in
                        Button {
                            resolveAndSelect(result.completion)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(result.completion.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(result.completion.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                if let distance = result.formattedDistance {
                                    Text(distance)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
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

        search.start { response, _ in
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
    @State private var showCamera = false
    @State private var showImageSourceDialog = false
    @State private var cameraImage: UIImage?
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
                    showImageSourceDialog = true
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
        .scrollDismissesKeyboard(.immediately)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .navigationTitle("Ort hinzufügen")
        .sheet(isPresented: $showPreview) {
            PostPreviewView(
                name: mapItem.name ?? "Unbekannt",
                address: mapItem.placemark.title ?? "",
                category: category,
                description: description,
                images: selectedImages
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Zurück") { onBack() }
            }
        }
        .confirmationDialog("Foto auswählen", isPresented: $showImageSourceDialog) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Foto aufnehmen") { showCamera = true }
            }
            Button("Aus Galerie wählen") { showImagePicker = true }
            Button("Abbrechen", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerAppend(images: $selectedImages)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker(image: $cameraImage)
                .ignoresSafeArea()
        }
        .onChange(of: cameraImage) { _, newImage in
            if let newImage { selectedImages.append(newImage) }
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
<<<<<<< HEAD

#Preview {
    Home(authViewModel: {
        let vm = AuthViewModel()
        vm.currentUser = .preview2
        return vm
    }())
}


extension User {
    static let preview2 = User(
        id: UUID(uuidString: "e5f9bcaa-20f7-4296-a7f1-f2caf539d474")!,
        email: "oleboehm4321@icloud.com",
        username: "oleboehm4321",
        displayName: "Ole Böhm",
        profileImageUrl: nil,
        createdAt: "2026-01-01T12:00:00Z",
        updatedAt: nil,
        lastSeenAt: nil,
        bio: "This is a preview user",
        preferences: ["theme": "dark"],
        favoriteCategories: ["gaming", "sports"],
        isVerified: true,
        isModerator: false,
        isPrivate: false,
        fcmToken: nil,
        stats: ["quests": 12, "friends": 5],
        ringCode: "101100110010110011001011100110010110011001011001100101100"
    )
}




=======
>>>>>>> 627cb20 (ui)
