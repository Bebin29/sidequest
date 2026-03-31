import SwiftUI
import MapKit

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
    @State private var isUploading = false
    @Environment(\.dismiss) var dismiss
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
                    .padding(.vertical, 6)
                    .background(Theme.accent)
                    .foregroundStyle(Theme.textPrimary)
                    .clipShape(Capsule())
            }

            Section("Beschreibung") {
                TextField("Warum empfiehlst du diesen Ort?", text: $description, axis: .vertical)
                    .lineLimit(3...6)
                    .autocorrectionDisabled()
            }

            Section("Fotos (\(selectedImages.count))") {
                if !selectedImages.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(radius: 4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Theme.borderLight, lineWidth: 1)
                                        )

                                    Button {
                                        selectedImages.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white, .red)
                                            .font(.title3)
                                    }
                                    .accessibilityLabel("Bild entfernen")
                                    .offset(x: 6, y: -6)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .scrollIndicators(.hidden)
                }

                Button {
                    showImageSourceDialog = true
                } label: {
                    Label("Foto hinzufügen", systemImage: "camera")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Theme.textPrimary)
                        .background(
                            Theme.accent,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Zurück") { onBack() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await submit() }
                } label: {
                    if isUploading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Speichern")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                }
                // Pflicht: Mindestens 1 Foto
                .disabled(isUploading || selectedImages.isEmpty)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                } label: {
                    Image(systemName: "checkmark")
                    
                }
            }
            
        }
        .navigationTitle("Ort hinzufügen")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Foto auswählen", isPresented: $showImageSourceDialog) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Foto aufnehmen") { showCamera = true }
            }
            Button("Aus Galerie wählen") { showImagePicker = true }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Bitte wähle, wie du ein Foto hinzufügen möchtest.")
        }

        .sheet(isPresented: $showImagePicker) {
            ImagePickerAppend(images: $selectedImages)
                .presentationDragIndicator(.visible)
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
        guard !selectedImages.isEmpty else { return } // Sicherstellen, dass mindestens ein Bild vorhanden ist
        guard let coordinate = mapItem.placemark.location?.coordinate else { return }
        isUploading = true

        let indexedImages = Array(selectedImages.enumerated())
        var imageUrls: [String] = await withTaskGroup(of: (Int, String?).self) { group in
            for (index, image) in indexedImages {
                group.addTask {
                    let url = try? await imageUploadService.upload(image: image)
                    return (index, url)
                }
            }
            var results = [(Int, String)]()
            for await (index, url) in group {
                if let url { results.append((index, url)) }
            }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
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

