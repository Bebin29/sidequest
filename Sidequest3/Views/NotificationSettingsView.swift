//
//  NotificationSettingsView.swift
//  Sidequest
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Bindable var authViewModel: AuthViewModel

    @State private var friendRequest = true
    @State private var friendAccepted = true
    @State private var newComment = true
    @State private var newReaction = true
    @State private var friendNewSpot = true
    @State private var isSaving = false
    @State private var pushAuthStatus: UNAuthorizationStatus = .authorized

    private let profileService = ProfileService()

    var body: some View {
        List {
            if pushAuthStatus == .notDetermined {
                Section {
                    Button {
                        requestPushPermission()
                    } label: {
                        Label("Push-Benachrichtigungen aktivieren", systemImage: "bell.badge")
                    }
                } footer: {
                    Text("Aktiviere Push-Benachrichtigungen, um ueber neue Aktivitaeten informiert zu werden.")
                }
            } else if pushAuthStatus == .denied {
                Section {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("In Einstellungen aktivieren", systemImage: "bell.slash")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Push-Benachrichtigungen sind deaktiviert. Aktiviere sie in den Systemeinstellungen.")
                }
            }

            Section {
                toggleRow(
                    icon: "person.badge.plus",
                    title: "Freundschaftsanfragen",
                    subtitle: "Wenn jemand dir eine Anfrage sendet",
                    isOn: $friendRequest
                )
                toggleRow(
                    icon: "person.2",
                    title: "Freundschaft akzeptiert",
                    subtitle: "Wenn deine Anfrage angenommen wird",
                    isOn: $friendAccepted
                )
                toggleRow(
                    icon: "bubble.left",
                    title: "Neue Kommentare",
                    subtitle: "Wenn jemand deinen Spot kommentiert",
                    isOn: $newComment
                )
                toggleRow(
                    icon: "heart",
                    title: "Neue Reaktionen",
                    subtitle: "Wenn jemand auf deinen Spot reagiert",
                    isOn: $newReaction
                )
                toggleRow(
                    icon: "mappin.and.ellipse",
                    title: "Neue Spots von Freunden",
                    subtitle: "Wenn ein Freund einen neuen Spot teilt",
                    isOn: $friendNewSpot
                )
            } header: {
                Text("Benachrichtigungstypen")
            } footer: {
                Text("Deaktivierte Benachrichtigungen werden weder als Push noch in der App angezeigt.")
            }
        }
        .navigationTitle("Benachrichtigungen")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            pushAuthStatus = settings.authorizationStatus
        }
        .onAppear {
            loadPreferences()
        }
        .onChange(of: friendRequest) { _, _ in savePreferences() }
        .onChange(of: friendAccepted) { _, _ in savePreferences() }
        .onChange(of: newComment) { _, _ in savePreferences() }
        .onChange(of: newReaction) { _, _ in savePreferences() }
        .onChange(of: friendNewSpot) { _, _ in savePreferences() }
    }

    // MARK: - Toggle Row

    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .fontWeight(.regular)
                    .frame(width: 24)
                    .foregroundStyle(.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(.accentColor)
    }

    // MARK: - Push Permission

    private func requestPushPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    pushAuthStatus = granted ? .authorized : .denied
                }
                if granted {
                    await MainActor.run {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            } catch {
                print("Push authorization error: \(error)")
            }
        }
    }

    // MARK: - Preferences

    private func loadPreferences() {
        guard let prefs = authViewModel.currentUser?.preferences else { return }

        friendRequest = prefs["notif_friend_request"] != "false"
        friendAccepted = prefs["notif_friend_accepted"] != "false"
        newComment = prefs["notif_new_comment"] != "false"
        newReaction = prefs["notif_new_reaction"] != "false"
        friendNewSpot = prefs["notif_friend_new_spot"] != "false"
    }

    private func savePreferences() {
        guard !isSaving, let userId = authViewModel.currentUser?.id else { return }
        isSaving = true

        let prefs: [String: String] = [
            "notif_friend_request": friendRequest ? "true" : "false",
            "notif_friend_accepted": friendAccepted ? "true" : "false",
            "notif_new_comment": newComment ? "true" : "false",
            "notif_new_reaction": newReaction ? "true" : "false",
            "notif_friend_new_spot": friendNewSpot ? "true" : "false",
        ]

        // Bestehende Preferences mergen
        var merged = authViewModel.currentUser?.preferences ?? [:]
        for (key, value) in prefs {
            merged[key] = value
        }

        Task {
            do {
                let updatedUser = try await profileService.updateProfile(
                    userId: userId,
                    body: ["preferences": merged]
                )
                await MainActor.run {
                    authViewModel.currentUser = updatedUser
                    isSaving = false
                }
            } catch {
                print("Save notification preferences failed: \(error.localizedDescription)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}
