//
//  SettingsView.swift
//  Sidequest3
//
//  Created by ole on 29.03.26.
//

import SwiftUI

struct SettingsView: View {

    @Bindable var authViewModel: AuthViewModel
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        if let user = authViewModel.currentUser {
            NavigationStack {
                ZStack {
                    Color(UIColor.systemGray6).ignoresSafeArea()

                    VStack(spacing: 20) {




                        ScrollView {
                            Spacer(minLength: 32)
                            VStack(spacing: 18) {
                                NavigationLink {
                                    EditProfileView(authViewModel: authViewModel)
                                } label: {
                                    HStack(spacing: 16) {


                                        AvatarView(url: user.profileImageUrl, size: .medium)

                                        VStack(alignment: .leading, spacing: 4) {

                                            Text(user.displayName)
                                                .foregroundStyle(Theme.textPrimary)
                                                .font(.headline)

                                            Text("@\(user.username)")
                                                .foregroundStyle(Theme.textSecondary)
                                                .font(.subheadline)
                                        }

                                        Spacer()
                                    }
                                    .padding()
                                    .background(Theme.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                                    .padding(.horizontal)

                                }

                                Text("Du bist mit deinem Apple Account angemeldet. Du kannst deinen Namen und dein Profilbild ändern, wenn du auf dein Profil klickst.")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.textSecondary)
                                    .padding(.horizontal)



                                VStack(spacing: 12) {
                                    NavigationLink {
                                        NotificationSettingsView(authViewModel: authViewModel)
                                    } label: {
                                        SettingsRow(title: "Mitteilungen")
                                    }
                                    NavigationLink {
                                        LocationSettingsView()
                                    } label: {
                                        SettingsRow(title: "Standort")
                                    }
                                    NavigationLink {
                                        CameraSettingsView()
                                    } label: {
                                        SettingsRow(title: "Fotos & Kamera")
                                    }
                                }
                                .padding(.horizontal)







                               
                                    VStack(alignment: .leading, spacing: 8) {

                                        Text("Datenschutz & Informationen")
                                            .foregroundStyle(Theme.textSecondary)
                                            .font(.footnote)
                                            .padding(.horizontal)

                                        VStack(spacing: 0) {

                                            LinkRow(title: "Datenschutz")

                                            Divider()
                                                .background(Theme.divider)

                                            LinkRow(title: "Impressum")

                                            Divider()
                                                .background(Theme.divider)

                                            LinkRow(title: "Hilfe")

                                        }
                                        .background(Theme.cardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                                        .padding(.horizontal)

                                    }
                                









                                    VStack(alignment: .leading, spacing: 8) {
                                        Button {
                                            showLogoutAlert = true
                                        } label: {
                                            VStack{
                                                HStack {
                                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                                        .foregroundStyle(Theme.destructive)
                                                        .font(.subheadline)
                                                        .frame(width: 20)
                                                    Text("Abmelden")
                                                        .foregroundStyle(Theme.destructive)

                                                    Spacer()




                                                }
                                                .padding()
                                                .background(Theme.cardBackground)
                                                .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                                            }
                                            .padding(.horizontal)
                                        }
                                    }

                                    .alert("Abmelden?", isPresented: $showLogoutAlert) {
                                        Button("Abmelden", role: .destructive) {
                                            authViewModel.signOut()
                                        }
                                        Button("Abbrechen", role: .cancel) {}
                                    } message: {
                                        Text("Moechtest du dich wirklich abmelden?")
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Button {
                                            showDeleteAlert = true
                                        } label: {
                                            HStack {
                                                Image(systemName: "trash")
                                                    .foregroundStyle(Theme.destructive)
                                                    .font(.subheadline)
                                                    .frame(width: 20)
                                                Text("Account löschen")
                                                    .foregroundStyle(Theme.destructive)
                                                Spacer()
                                            }
                                            .padding()
                                            .background(Theme.cardBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                                            .padding(.horizontal)
                                        }
                                    }
                                    .alert("Account loeschen?", isPresented: $showDeleteAlert) {
                                        Button("Loeschen", role: .destructive) {
                                            Task { await authViewModel.deleteAccount() }
                                        }
                                        Button("Abbrechen", role: .cancel) {}
                                    } message: {
                                        Text("Dein Account und alle deine Daten werden unwiderruflich geloescht. Diese Aktion kann nicht rueckgaengig gemacht werden.")
                                    }

                                HStack(spacing: 4) {
                                    Image(systemName: "map.fill")
                                        .foregroundStyle(Theme.textSecondary)
                                        .font(.footnote)
                                    Text("sidequest")
                                        .foregroundStyle(Theme.textSecondary)
                                        .font(.footnote)


                                }
                                .padding(.top, 10)

                            }
                        }
                        .navigationTitle("Einstellungen")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")

                                }
                                .accessibilityLabel("Schliessen")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct LocationSettingsView: View {

    var body: some View {
        Text("Standort Einstellungen")
            .navigationTitle("Standort")
    }
}

struct CameraSettingsView: View {

    var body: some View {
        Text("Foto & Kamera Einstellungen")
            .navigationTitle("Foto & Kamera")
    }
}

struct SettingsRow: View {

    let title: String

    var body: some View {
        Text(title)
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }
}

struct LinkRow: View {

    let title: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.blue)

            Spacer()
        }
        .padding()
    }
}
