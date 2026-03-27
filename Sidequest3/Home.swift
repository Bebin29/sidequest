//
//  Home.swift
//  Sidequest3
//
//  Created by ole on 24.03.26.
//

import SwiftUI

struct Home: View {
    @Bindable var authViewModel: AuthViewModel

    var body: some View {
        
            TabView {
                Tab("Home", systemImage: "house.fill") {
                    Feed(userId: authViewModel.currentUser?.id, currentUserId: authViewModel.currentUser?.id)
                }
                Tab("Map", systemImage: "map.fill") {
                    Karte(userId: authViewModel.currentUser?.id)
                }
                Tab("Friends", systemImage: "person.2.fill") {
                    FriendsView(currentUser: authViewModel.currentUser)
                }
                Tab("Profile", systemImage: "person.fill") {
                    Profile(authViewModel: authViewModel)
                }
                if let user = authViewModel.currentUser {
                    if(user.isModerator) {
                        Tab("Admin", systemImage: "gearshape.fill") {
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
