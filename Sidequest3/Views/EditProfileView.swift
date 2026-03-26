//
//  EditProfileView.swift
//  Sidequest
//

import SwiftUI

struct EditProfileView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var displayName: String
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let profileService = ProfileService()
    private let imageUploadService = ImageUploadService()

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        _displayName = State(initialValue: authViewModel.currentUser?.displayName ?? "")
    }

    var body: some View {
        NavigationStack {
            List {
                // Profilbild
                Section {
                    HStack {
                        Spacer()
                        ZStack(alignment: .bottomTrailing) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else if let urlString = authViewModel.currentUser?.profileImageUrl,
                                      let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } placeholder: {
                                    profilePlaceholder
                                }
                            } else {
                                profilePlaceholder
                            }

                            Button {
                                showImagePicker = true
                            } label: {
                                Image(systemName: "camera.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue, .white)
                            }
                        }
                        Spacer()
                    }
                }

                // Anzeigename
                Section("Anzeigename") {
                    TextField("Anzeigename", text: $displayName)
                }

                // Username (nur anzeigen)
                Section("Username") {
                    Text("@\(authViewModel.currentUser?.username ?? "")")
                        .foregroundStyle(.secondary)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Profil bearbeiten")
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
                    .disabled(isSaving || displayName.isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(Color(.systemGray4))
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
            )
    }

    func save() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        isSaving = true
        errorMessage = nil

        var body: [String: Any] = [
            "display_name": displayName
        ]

        // Bild hochladen falls gewählt
        if let image = selectedImage {
            do {
                let imageUrl = try await imageUploadService.upload(image: image)
                body["profile_image_url"] = imageUrl
            } catch {
                errorMessage = "Bild-Upload fehlgeschlagen"
                isSaving = false
                return
            }
        }

        do {
            let updated = try await profileService.updateProfile(userId: userId, body: body)
            authViewModel.currentUser = updated
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
