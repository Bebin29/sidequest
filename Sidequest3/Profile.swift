//
//  Profile.swift
//  Sidequest3
//
//  Created by ole on 24.03.26.
//

import SwiftUI

struct Profile: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var viewModel = FriendsViewModel()
    @State private var showLogoutAlert = false
    var currentUser: User?
    
    var body: some View {
        
            NavigationStack {
                VStack(spacing: 20) {
                    if let user = authViewModel.currentUser {
                        
                        
                        VStack {
                            HStack {
                                Text("Profil")
                                Spacer()
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding()
                            HStack(alignment: .center) {
                                Image("Image01")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(.gray.opacity(0.2), lineWidth: 2)
                                    )
                                Spacer()
                                VStack (alignment: .leading) {
                                    HStack {
                                        Spacer()
                                        Text("@\(user.username)")
                                            .fontWeight(.bold)
                                        Spacer()
                                        Spacer()
                                        Spacer()
                                        Spacer()
                                        Spacer()
                                        
                                    }
                                    HStack  {
                                        Spacer()
                                        VStack (alignment: .leading){
                                            Text("\(viewModel.friends.count)")
                                                .fontWeight(.semibold)
                                            Text("Freunde")
                                                .font(.subheadline)
                                        }
                                        Spacer()
                                        VStack (alignment: .leading) {
                                            Text("27")
                                                .fontWeight(.semibold)
                                            Text("Bewertet")
                                                .font(.subheadline)
                                        }
                                        Spacer()
                                        VStack (alignment: .leading) {
                                            Text("XX")
                                                .fontWeight(.semibold)
                                            Text("KPI")
                                                .font(.subheadline)
                                        }
                                        Spacer()
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            HStack(spacing: 8) {
                                Button(action: {
                                    print("Bearbeiten")
                                }) {
                                    Text("Bearbeiten")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(15)
                                        .foregroundStyle(Color(.systemIndigo))
                                }
                                Button(action: {
                                    print("Profil teilen")
                                }) {
                                    Text("Profil teilen")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(15)
                                        .foregroundStyle(Color(.systemIndigo))
                                }
                            }
                            .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemIndigo))
                        .cornerRadius(15)
                        .foregroundStyle(Color(.white))
                        .fontWeight(.semibold)
                        
                        
                        VStack {
                            HStack {
                                Text("Orte")
                                Spacer()
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding()
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    VStack {
                                        Image("IMGSTART01")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    }
                                    VStack {
                                        Image("IMGSTART02")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    }
                                    VStack {
                                        Image("IMGSTART03")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    }
                                    VStack {
                                        Image("IMGSTART04")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    }
                                    VStack {
                                        Image("IMGSTART05")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    }
                                    VStack {
                                        Image("IMGSTART06")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    }
                                    VStack {
                                        Image("IMGSTART07")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    }
                                    VStack {
                                        Image("IMGSTART08")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    }
                                    VStack {
                                        Image("IMGSTART09")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom)
                            }
                            
                            
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemIndigo))
                        .cornerRadius(15)
                        .foregroundStyle(Color(.white))
                        .fontWeight(.semibold)
                     
                        
                        VStack {
                            HStack {
                                Text("Weiteres")
                                Spacer()
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding()
                            
                            VStack {
                                Text("Datenschutz")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.white))
                            .cornerRadius(15)
                            .foregroundStyle(Color(.systemIndigo))
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                            
                            VStack {
                                Text("Impressum")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.white))
                            .cornerRadius(15)
                            .foregroundStyle(Color(.systemIndigo))
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                            
                            HStack {
                                Button(role: .destructive) {
                                    showLogoutAlert = true
                                } label: {
                                    Text("Abmelden")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(.systemRed))
                                        .cornerRadius(15)
                                        .foregroundStyle(Color(.white))
                                        .fontWeight(.semibold)
                                }
                                .alert("Abmelden?", isPresented: $showLogoutAlert) {
                                    
                                    Button("Abmelden", role: .destructive) {
                                        authViewModel.signOut()
                                    }
                                    
                                    Button("Abbrechen", role: .cancel) { }
                                    
                                } message: {
                                    Text("Möchtest du dich wirklich abmelden?")
                                }
                            }
                            .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemIndigo))
                        .cornerRadius(15)
                        .foregroundStyle(Color(.white))
                        .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .padding()
            }
        
        .task {
            guard let userId = authViewModel.currentUser?.id else { return }
            await viewModel.loadFriends(userId: userId)
            await viewModel.loadPendingRequests(userId: userId)
        }
        .refreshable {
            guard let userId = authViewModel.currentUser?.id else { return }
            await viewModel.loadFriends(userId: userId)
            await viewModel.loadPendingRequests(userId: userId)
        }
        
    }
}












#Preview {
    let vm = AuthViewModel()
    vm.currentUser = .preview
    return Profile(authViewModel: vm)
}


extension User {
    static let preview = User(
        id: UUID(uuidString: "e5f9bcaa-20f7-4296-a7f1-f2caf539d474")!,
        email: "oleboehm4321@icloud.com",
        username: "oleboehm4321",
        displayName: "Ole Böhm",
        profileImageUrl: nil,
        createdAt: "2026-01-01T12:00:00Z",
        updatedAt: nil,
        lastSeenAt: nil,
        bio: "This is a preview user",
        preferences: ["theme": "dark"],
        favoriteCategories: ["gaming", "sports"],
        isVerified: true,
        isModerator: false,
        isPrivate: false,
        fcmToken: nil,
        stats: ["quests": 12, "friends": 5]
    )
}

