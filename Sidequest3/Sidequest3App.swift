//
//  Sidequest3App.swift
//  Sidequest
//
//  Created by ole on 23.03.26.
//

import SwiftUI
import UserNotifications

@main
struct Sidequest3App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var container = DependencyContainer()
    @State private var authViewModel = AuthViewModel()
    @State private var pushService = PushNotificationService()
    @State private var deepLinkFriendUsername: String?

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                Home(authViewModel: authViewModel, deepLinkRouter: pushService.router)
                    .environmentObject(container)
                    .task {
                        await setupPushNotifications()
                    }
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .alert("Freund hinzufuegen?", isPresented: .init(
                        get: { deepLinkFriendUsername != nil },
                        set: { if !$0 { deepLinkFriendUsername = nil } }
                    )) {
                        Button("Anfrage senden") {
                            if let username = deepLinkFriendUsername,
                               let userId = authViewModel.currentUser?.id {
                                Task {
                                    let service = FriendshipService()
                                    _ = try? await service.sendRequest(requesterId: userId, receiverUsername: username)
                                }
                                deepLinkFriendUsername = nil
                            }
                        }
                        Button("Abbrechen", role: .cancel) {
                            deepLinkFriendUsername = nil
                        }
                    } message: {
                        Text("Moechtest du @\(deepLinkFriendUsername ?? "") eine Freundschaftsanfrage senden?")
                    }
            } else {
                LoginView(authViewModel: authViewModel)
                    .task {
                        await authViewModel.checkExistingSession()
                    }
            }
        }
    }

    private func setupPushNotifications() async {
        // Delegate setzen fuer Foreground-Notifications
        UNUserNotificationCenter.current().delegate = pushService

        // Berechtigung anfragen und registrieren
        let granted = await pushService.requestAuthorization()
        guard granted else { return }

        // Callback fuer Device Token setzen
        appDelegate.onTokenReceived = { token in
            pushService.deviceToken = token
            if let userId = authViewModel.currentUser?.id {
                Task {
                    await pushService.uploadToken(userId: userId, token: token)
                }
            }
        }

        // Falls Token bereits vorhanden (App-Neustart)
        if let existingToken = pushService.deviceToken,
           let userId = authViewModel.currentUser?.id {
            await pushService.uploadToken(userId: userId, token: existingToken)
        }
    }

    private func handleDeepLink(_ url: URL) {
        // sidequest://add-friend/{username}
        guard url.scheme == "sidequest",
              url.host == "add-friend",
              let username = url.pathComponents.last,
              username != "/",
              username != authViewModel.currentUser?.username else { return }
        deepLinkFriendUsername = username
    }
}
