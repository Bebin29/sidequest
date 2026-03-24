//
//  Profile.swift
//  Sidequest3
//
//  Created by ole on 24.03.26.
//

import SwiftUI

struct Profile: View {
    @Bindable var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                if let user = authViewModel.currentUser {
                    Section("Account") {
                        Text(user.displayName)
                        Text("@\(user.username)")
                            .foregroundStyle(.secondary)
                        Text(user.email)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Abmelden", role: .destructive) {
                        authViewModel.signOut()
                    }
                }
            }
            .navigationTitle("Profil")
        }
    }
}
