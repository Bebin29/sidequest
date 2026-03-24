//
//  Home.swift
//  Sidequest3
//
//  Created by ole on 24.03.26.
//

import SwiftUI

struct Home: View {
    var body: some View {
        TabView {
            Tab("Feed", systemImage: "house.fill") {
                Feed()
            }
            Tab("Karte", systemImage: "map.fill") {
                Karte()
            }
            Tab("Profil", systemImage: "person.fill") {
                Profile()
            }
        }.tint(Color(.systemIndigo))
    }
}

#Preview {
    Home()
}
