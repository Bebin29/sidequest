//
//  Home.swift
//  Sidequest3
//
//  Created by ole on 24.03.26.
//

import SwiftUI

enum AppTab: Hashable {
    case home, map, friends, profile, admin
}

struct Home: View {
    @Bindable var authViewModel: AuthViewModel
    var deepLinkRouter: DeepLinkRouter
    @State private var selectedTab: AppTab = .home
    @State private var focusLocation: Location?
    @State private var deepLinkLocationId: UUID?
    @State private var deepLinkLocation: Location?
    @State private var showFriendsFromNotification = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Feed", systemImage: "house.fill", value: .home) {
                Feed(
                    userId: authViewModel.currentUser?.id,
                    currentUserId: authViewModel.currentUser?.id,
                    onShowOnMap: { location in
                        focusLocation = location
                        selectedTab = .map
                    }
                )
            }
            Tab("Map", systemImage: "map.fill", value: .map) {
                Karte(userId: authViewModel.currentUser?.id, focusLocation: $focusLocation)
            }
            /*
            Tab("Friends", systemImage: "person.2.fill", value: .friends) {
                FriendsView(currentUser: authViewModel.currentUser)
            }
             */
            Tab("Profile", systemImage: "person.fill", value: .profile) {
                Profile(authViewModel: authViewModel)
            }
            if let user = authViewModel.currentUser {
                if user.isModerator {
                    Tab("Admin", systemImage: "gearshape.fill", value: .admin) {
                        AdminView()
                    }
                }
            }
        }
        .tint(Color(.systemIndigo))
        .onChange(of: deepLinkRouter.pendingDestination) { _, destination in
            guard let destination else { return }
            handleDeepLink(destination)
        }
        .sheet(item: $deepLinkLocation) { location in
            NavigationStack {
                LocationDetailView(
                    location: location,
                    currentUserId: authViewModel.currentUser?.id
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Fertig") {
                            deepLinkLocation = nil
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showFriendsFromNotification) {
            FriendsView(currentUser: authViewModel.currentUser)
        }
    }

    private func handleDeepLink(_ destination: DeepLinkDestination) {
        switch destination {
        case .friendRequests:
            selectedTab = .profile
            showFriendsFromNotification = true
            deepLinkRouter.clearDestination()

        case .location(let id):
            deepLinkLocationId = id
            deepLinkRouter.clearDestination()
            Task {
                await loadAndShowLocation(id: id)
            }

        case .userProfile:
            deepLinkRouter.clearDestination()
        }
    }

    private func loadAndShowLocation(id: UUID) async {
        do {
            let location = try await LocationService().getLocation(id: id)
            await MainActor.run {
                deepLinkLocation = location
            }
        } catch {
            print("Failed to load location for deep link: \(error.localizedDescription)")
        }
    }
}

#Preview {
    Home(authViewModel: AuthViewModel(), deepLinkRouter: DeepLinkRouter())
}
