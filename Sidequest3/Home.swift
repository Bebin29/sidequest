//
//  Home.swift
//  Sidequest3
//
//  Created by ole on 24.03.26.
//

import SwiftUI

enum AppTab: Hashable {
    case home, map, friends, profile, admin, test
}

struct Home: View {
    @Bindable var authViewModel: AuthViewModel
    var deepLinkRouter = DeepLinkRouter()
    @State private var mapViewModel = MapViewModel()
    @State private var selectedTab: AppTab = .home
    @State private var focusLocation: Location?
    @State private var deepLinkLocation: Location?
    @State private var showFriendsFromNotification = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .test) {
                MainView(authViewModel: authViewModel, userId: authViewModel.currentUser?.id,
                         currentUserId: authViewModel.currentUser?.id,
                         mapViewModel: mapViewModel,
                         onShowOnMap: { location in
                    focusLocation = location
                    selectedTab = .map
                }
                )
                
            }
            
            
            Tab("Map", systemImage: "map.fill", value: .map) {
                Karte(mapViewModel: mapViewModel, userId: authViewModel.currentUser?.id, focusLocation: $focusLocation)
            }
            
            Tab("Friends", systemImage: "person.2.fill", value: .friends) {
                FriendsView(authViewModel: authViewModel, currentUser: authViewModel.currentUser)
            }
            
           
            
            if let user = authViewModel.currentUser {
                if(user.isModerator) {
                    Tab("Admin", systemImage: "gearshape.fill", value: .admin) {
                        AdminView()
                    }
                }
            }
        }
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
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
            FriendsView(authViewModel: authViewModel, currentUser: authViewModel.currentUser)
        }
    }

    private func handleDeepLink(_ destination: DeepLinkDestination) {
        switch destination {
        case .friendRequests:
            selectedTab = .profile
            showFriendsFromNotification = true
            deepLinkRouter.clearDestination()

        case .location(let id):
            deepLinkRouter.clearDestination()
            Task {
                do {
                    let location = try await LocationService().getLocation(id: id)
                    await MainActor.run {
                        deepLinkLocation = location
                    }
                } catch {
                    print("Failed to load location for deep link: \(error.localizedDescription)")
                }
            }

        case .userProfile:
            deepLinkRouter.clearDestination()
        }
    }
}

#Preview {
    Home(authViewModel: AuthViewModel(), deepLinkRouter: DeepLinkRouter())
}
