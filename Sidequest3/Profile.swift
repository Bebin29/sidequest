//
//  Profile.swift
//  Sidequest3
//
//  Created by ole on 24.03.26.
//

import SwiftUI

struct Profile: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var friendsViewModel = FriendsViewModel()
    var mapViewModel: MapViewModel
    @State private var showFriends = false
    @State private var showShareCard = false
    @State private var selectedLocation: Location?

    
    var body: some View {
        
        NavigationStack {
            
            
            ScrollView {
                if let user = authViewModel.currentUser {
                    VStack(spacing: 0) {
                        // Profile Header
                        
                        
                        
                        
                        Button {
                            showShareCard = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 44, height: 36)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)                        
                        Spacer(minLength: 32)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            
       
            .sheet(isPresented: $showShareCard) {
                if let user = authViewModel.currentUser {
                    ProfileShareCardView(user: user)
                }
            }

            
        }
    }
    
    

    
}
