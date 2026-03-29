//
//  EditLocationView.swift
//  Sidequest
//

import SwiftUI

struct EditLocationView: View {
    let location: Location
    var onSave: (Location) -> Void

    @State private var locationDescription: String
    @State private var category: String
    @State private var existingImageUrls: [String]
    @State private var newImages: [UIImage] = []
    @State private var showImageSourceDialog = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @State private var customCategories: [String] = []
    @State private var isSaving = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let locationService = LocationService()
    private let imageUploadService = ImageUploadService()

    private let maxImages = 5

    private var totalImageCount: Int {
        existingImageUrls.count + newImages.count
    }

    private var canSave: Bool {
        !category.isEmpty && totalImageCount >= 1 && !isSaving
    }

    init(location: Location, onSave: @escaping (Location) -> Void) {
        self.location = location
        self.onSave = onSave
        _locationDescription = State(initialValue: location.description ?? "")
        _category = State(initialValue: location.category)
        _existingImageUrls = State(initialValue: location.imageUrls)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Name") {
                    Text(location.name)
                        .foregroundStyle(.secondary)
                }

                Section("Kategorie") {
                    CategoryPickerField(category: $category, customCategories: customCategories)
                }

                Section("Beschreibung") {
                    TextField("Beschreibung", text: $locationDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Fotos (\(totalImageCount)/\(maxImages))") {
                    if totalImageCount == 0 {
                        Text("Mindestens ein Foto erforderlich")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if !existingImageUrls.isEmpty || !newImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                // Bestehende Bilder (von URLs)
                                ForEach(Array(existingImageUrls.enumerated()), id: \.element) { index, urlString in
                                    ZStack(alignment: .topTrailing) {
                                        AsyncImage(url: URL(string: urlString)) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            case .failure:
                                                Color.gray.overlay {
                                                    Image(systemName: "photo")
                                                        .foregroundStyle(.white)
                                                }
                                            default:
                                                ProgressView()
                                            }
                                        }
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                        Button {
                                            existingImageUrls.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white, .red)
                                                .font(.title3)
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                                }

                                // Neue Bilder (UIImage)
                                ForEach(Array(newImages.enumerated()), id: \.offset) { index, image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        Button {
                                            newImages.remove(at: index)
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

                    if totalImageCount < maxImages {
                        Button {
                            showImageSourceDialog = true
                        } label: {
                            Label("Foto hinzufügen", systemImage: "camera")
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .task {
                do {
                    customCategories = try await locationService.fetchCategories()
                } catch {
                    print("Failed to load categories:", error)
                }
            }
            .navigationTitle("Bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        Task { await save() }
                    }
                    .bold()
                    .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
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
                ImagePickerAppend(images: $newImages)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraImagePicker(image: $cameraImage)
                    .ignoresSafeArea()
            }
            .onChange(of: cameraImage) { _, newImage in
                if let newImage, totalImageCount < maxImages {
                    newImages.append(newImage)
                }
            }
        }
    }

    func save() async {
        isSaving = true
        errorMessage = nil

        // Neue Bilder hochladen
        var uploadedUrls: [String] = []
        for image in newImages {
            do {
                let url = try await imageUploadService.upload(image: image)
                uploadedUrls.append(url)
            } catch {
                print("Image upload failed:", error)
                errorMessage = "Fehler beim Hochladen eines Fotos"
                isSaving = false
                return
            }
        }

        let finalImageUrls = existingImageUrls + uploadedUrls

        let body: [String: Any] = [
            "category": category,
            "description": locationDescription,
            "image_urls": finalImageUrls
        ]

        print("Saving location \(location.id) with body: \(body)")

        do {
            let updated = try await locationService.updateLocation(id: location.id, body: body)
            print("Save success: \(updated.id)")
            onSave(updated)
            dismiss()
        } catch {
            print("Save error: \(error)")
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
