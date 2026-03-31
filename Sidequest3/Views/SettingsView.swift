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


                                        Group {
                                            if let urlString = user.profileImageUrl,
                                               let url = URL(string: urlString) {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 50, height: 50)
                                                        .clipShape(Circle())
                                                } placeholder: {
                                                    Image(systemName: "person.crop.circle.fill")
                                                        .resizable()
                                                        .frame(width: 50, height: 50)
                                                        .foregroundColor(.indigo)
                                                }
                                            } else {
                                                Image(systemName: "person.crop.circle.fill")
                                                    .resizable()
                                                    .frame(width: 50, height: 50)
                                                    .foregroundColor(.indigo)
                                            }
                                        }

                                        VStack(alignment: .leading, spacing: 4) {

                                            Text(user.displayName)
                                                .foregroundColor(.white)
                                                .font(.headline)

                                            Text("@\(user.username)")
                                                .foregroundColor(.gray)
                                                .font(.subheadline)
                                        }

                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color(UIColor.systemGray).opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 30))
                                    .padding(.horizontal)

                                }

                                Text("Du bist mit deinem Apple Account angemeldet. Du kannst deinen Namen und dein Profilbild ändern, wenn du auf dein Profil klickst.")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
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
                                            .foregroundColor(.gray)
                                            .font(.footnote)
                                            .padding(.horizontal)

                                        VStack(spacing: 0) {

                                            LinkRow(title: "Datenschutz")

                                            Divider()
                                                .background(Color.gray.opacity(0.3))

                                            LinkRow(title: "Impressum")

                                            Divider()
                                                .background(Color.gray.opacity(0.3))

                                            LinkRow(title: "Hilfe")

                                        }
                                        .background(Color(UIColor.systemGray).opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 30))
                                        .padding(.horizontal)

                                    }
                                









                                    VStack(alignment: .leading, spacing: 8) {
                                        Button {
                                            showLogoutAlert = true
                                        } label: {
                                            VStack{
                                                HStack {
                                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                                        .foregroundColor(.red)
                                                        .font(.system(size: 14))
                                                    Text("Abmelden")
                                                        .foregroundColor(.red)

                                                    Spacer()




                                                }
                                                .padding()
                                                .background(Color(UIColor.systemGray).opacity(0.2))
                                                .clipShape(RoundedRectangle(cornerRadius: 30))
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
                                                    .foregroundColor(.red)
                                                    .font(.system(size: 14))
                                                Text("Account löschen")
                                                    .foregroundColor(.red)
                                                Spacer()
                                            }
                                            .padding()
                                            .background(Color(UIColor.systemGray).opacity(0.2))
                                            .clipShape(RoundedRectangle(cornerRadius: 30))
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
                                        .foregroundColor(.gray)
                                        .font(.footnote)
                                    Text("sidequest")
                                        .foregroundColor(.gray)
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
        HStack {
            Text(title)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding()
        .background(Color(UIColor.systemGray).opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

struct LinkRow: View {

    let title: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.blue)

            Spacer()
        }
        .padding()
    }
}
