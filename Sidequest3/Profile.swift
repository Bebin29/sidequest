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
            ScrollView {
                VStack(spacing: 20) {

                    if let user = authViewModel.currentUser {

                        // 🔵 HEADER (Profilbild + Name)
                        VStack(spacing: 12) {

                            // Profilbild (Platzhalter)
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 90, height: 90)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 35))
                                    .foregroundColor(.gray)
                            }

                            // Name + Username
                            VStack(spacing: 4) {
                                Text(user.displayName)
                                    .font(.title2)
                                    .fontWeight(.semibold)

                                Text("@\(user.username)")
                                    .foregroundStyle(.secondary)
                            }

                            // ✏️ Bearbeiten Button
                            Button(action: {
                                print("Profil bearbeiten")
                            }) {
                                Text("Profil bearbeiten")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 5)

                        // 📄 USER INFOS
                        VStack(alignment: .leading, spacing: 10) {

                            Label(user.email, systemImage: "envelope")

                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 5)

                        // 👥 KONTAKTE BOX
                        VStack(alignment: .leading, spacing: 12) {

                            HStack {
                                Text("Kontakte")
                                    .font(.headline)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }

                            Text("Hier kannst du später Freunde verwalten")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 5)

                        // 🚪 LOGOUT BUTTON
                        Button(role: .destructive) {
                            authViewModel.signOut()
                        } label: {
                            Text("Abmelden")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Profil")
        }
    }

    // 📅 Datum formatieren
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
