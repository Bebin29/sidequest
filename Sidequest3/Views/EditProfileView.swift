//
//  EditProfileView.swift
//  Sidequest
//

import SwiftUI

struct EditProfileView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var displayName: String
    @State private var username: String
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showImageSourceDialog = false
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var isUsernameAvailable: Bool?
    @State private var isCheckingUsername = false
    @State private var usernameCheckTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss

    private let profileService = ProfileService()
    private let imageUploadService = ImageUploadService()

    /// Ob der Username geändert wurde
    private var usernameChanged: Bool {
        username.lowercased() != (authViewModel.currentUser?.username ?? "").lowercased()
    }

    /// Speichern nur erlaubt wenn Username valid ist
    private var canSave: Bool {
        guard !isSaving && !displayName.isEmpty else { return false }
        if usernameChanged {
            return username.count >= 3 && isUsernameAvailable == true
        }
        return true
    }

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        _displayName = State(initialValue: authViewModel.currentUser?.displayName ?? "")
        _username = State(initialValue: authViewModel.currentUser?.username ?? "")
    }

    var body: some View {
        NavigationStack {
            List {
                // Profilbild
                Section ("Profilbild") {
                    HStack {
                        Spacer()
                        ZStack {
                            
                            // Profilbild
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else if let urlString = authViewModel.currentUser?.profileImageUrl,
                                      let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    profilePlaceholder
                                }
                            } else {
                                profilePlaceholder
                            }
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())

                        .overlay {
                            Button {
                                showImageSourceDialog = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(.black.opacity(0.35))   // leichter dunkler Overlay
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        Spacer()
                    }
                }

                // Anzeigename
                Section("Anzeigename") {
                    TextField("Anzeigename", text: $displayName)
                }

                // Username
                Section("Username") {
                    HStack {
                        Text("@")
                            .foregroundStyle(.secondary)
                        TextField("username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: username) { _, newValue in
                                isUsernameAvailable = nil
                                usernameCheckTask?.cancel()

                                // Wenn Username unverändert → kein Check nötig
                                guard usernameChanged else { return }
                                guard newValue.count >= 3 else { return }

                                usernameCheckTask = Task {
                                    isCheckingUsername = true
                                    try? await Task.sleep(for: .milliseconds(500))
                                    guard !Task.isCancelled else { return }
                                    do {
                                        let available = try await profileService.checkUsername(username: newValue)
                                        if !Task.isCancelled {
                                            isUsernameAvailable = available
                                        }
                                    } catch {}
                                    isCheckingUsername = false
                                }
                            }

                        if isCheckingUsername {
                            ProgressView()
                                .controlSize(.small)
                        } else if usernameChanged, let available = isUsernameAvailable {
                            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(available ? .green : .red)
                        }
                    }

                    if usernameChanged {
                        if !username.isEmpty && username.count < 3 {
                            Text("Mindestens 3 Zeichen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if isUsernameAvailable == false {
                            Text("Username ist bereits vergeben")
                                .font(.caption)
                                .foregroundStyle(.red)
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
            .navigationTitle("Profil bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")

                    }
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
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Image(systemName: "checkmark")
                        
                    }
                }
                
            }
            .alert("Foto auswählen", isPresented: $showImageSourceDialog) {
                
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Foto aufnehmen") {
                        showCamera = true
                    }
                }
                
                Button("Aus Galerie wählen") {
                    showImagePicker = true
                }
                
                Button("Abbrechen", role: .cancel) { }
            }
            /*
            .confirmationDialog("Foto auswählen", isPresented: $showImageSourceDialog) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Foto aufnehmen") { showCamera = true }
                }
                Button("Aus Galerie wählen") { showImagePicker = true }
                Button("Abbrechen", role: .cancel) {}
            }
             */
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraImagePicker(image: $selectedImage)
                    .ignoresSafeArea()
            }
            .overlay {
                if showSuccess {
                    VStack {
                        Spacer()
                        Label("Profil gespeichert", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.green, in: Capsule())
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                            .padding(.bottom, 32)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSuccess)
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

        // Username nur mitsenden wenn geändert
        if usernameChanged {
            body["username"] = username.lowercased()
        }

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
            isSaving = false
            showSuccess = true
            try? await Task.sleep(for: .seconds(1.2))
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}
