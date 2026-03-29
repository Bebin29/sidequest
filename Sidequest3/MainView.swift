//
//  MainView.swift
//  Sidequest3
//
//  Created by ole on 29.03.26.
//

import SwiftUI

struct MainView: View {
    @State private var showSettings = false
    @Bindable var authViewModel: AuthViewModel
    


    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                
               
                
                
                Button {
                    showSettings = true
                } label: {
                    Label("Einstellungen", systemImage: "gearshape.fill")
                        .font(.headline)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
            }
            
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(authViewModel: authViewModel)
        }
    }
}



struct SettingsView: View {
    
    @Bindable var authViewModel: AuthViewModel
    @State private var friendsViewModel = FriendsViewModel()
    @State private var mapViewModel = MapViewModel()
    @State private var showLogoutAlert = false
    @State private var showEditProfile = false
    @State private var showFriends = false
    @State private var showShareCard = false
    @State private var selectedLocation: Location?
    @State private var pendingCount = 0
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
                                        SettingsRow(title: "Mitteilungen", value: "Aus")
                                    }
                                    NavigationLink {
                                        LocationSettingsView()
                                    } label: {
                                        SettingsRow(title: "Standort", value: "Aus")
                                    }
                                    NavigationLink {
                                        CameraSettingsView()
                                    } label: {
                                        SettingsRow(title: "Fotos & Kamera", value: "Aus")
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
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "checkmark")
                                    
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
    let value: String
    
    var body: some View {
        HStack {
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.gray)
            
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







