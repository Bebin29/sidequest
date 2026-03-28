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
    @State private var selectedTab: AppTab = .home
    @State private var focusLocation: Location?

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
                if(user.isModerator) {
                    Tab("Admin", systemImage: "gearshape.fill", value: .admin) {
                        AdminView()
                    }
                }
            }
        }.tint(Color(.systemIndigo))
    }
}

#Preview {
    Home(authViewModel: AuthViewModel())
}
