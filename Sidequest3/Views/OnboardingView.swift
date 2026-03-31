//
//  OnboardingView.swift
//  Sidequest
//

import SwiftUI

struct OnboardingView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var displayName = ""
    @State private var isAvailable: Bool?
    @State private var isChecking = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var checkTask: Task<Void, Never>?

    private let profileService = ProfileService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("Willkommen bei Sidequest!")
                    .font(.title.bold())

                Text("Wähle einen Username und Anzeigenamen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 16) {
                    // Username
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Username")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        HStack {
                            TextField("username", text: $username)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .onChange(of: username) { _, newValue in
                                    isAvailable = nil
                                    checkTask?.cancel()
                                    guard newValue.count >= 3 else { return }
                                    checkTask = Task {
                                        isChecking = true
                                        try? await Task.sleep(for: .milliseconds(500))
                                        guard !Task.isCancelled else { return }
                                        do {
                                            let available = try await profileService.checkUsername(username: newValue)
                                            if !Task.isCancelled {
                                                isAvailable = available
                                            }
                                        } catch {}
                                        isChecking = false
                                    }
                                }

                            if isChecking {
                                ProgressView()
                                    .controlSize(.small)
                            } else if let available = isAvailable {
                                Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(available ? Theme.success : Theme.destructive)
                            }
                        }
                        if let available = isAvailable, !available {
                            Text("Username ist bereits vergeben")
                                .font(.caption)
                                .foregroundStyle(Theme.destructive)
                        }
                        if !username.isEmpty && username.count < 3 {
                            Text("Mindestens 3 Zeichen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Display Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Anzeigename")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        TextField("Dein Name", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.destructive)
                }

                Spacer()

                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Los geht's")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(username.count < 3 || displayName.isEmpty || isAvailable != true || isSaving)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }

    func save() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        isSaving = true
        errorMessage = nil

        let body: [String: Any] = [
            "username": username.lowercased(),
            "display_name": displayName
        ]

        do {
            let updated = try await profileService.updateProfile(userId: userId, body: body)
            authViewModel.currentUser = updated
            authViewModel.needsOnboarding = false
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
