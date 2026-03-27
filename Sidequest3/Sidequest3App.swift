//
//  Sidequest3App.swift
//  Sidequest
//
//  Created by ole on 23.03.26.
//

import SwiftUI

@main
struct Sidequest3App: App {
    @StateObject private var container = DependencyContainer()
    @State private var authViewModel = AuthViewModel()
    @State private var deepLinkFriendUsername: String?

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                Home(authViewModel: authViewModel)
                    .environmentObject(container)
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
