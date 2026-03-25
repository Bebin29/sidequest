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
            Tab("Feed", systemImage: "house.fill") {
                Feed()
            }
            Tab("Karte", systemImage: "map.fill") {
                Karte()
            }
            Tab("Profil", systemImage: "person.fill") {
                Profile(authViewModel: authViewModel)
            }
            Tab("Admin", systemImage: "gearshape.fill") {
                AdminView()
            }
        }.tint(Color(.systemIndigo))
    }
}

#Preview {
    Home(authViewModel: AuthViewModel())
}
