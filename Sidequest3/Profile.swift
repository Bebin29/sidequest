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
    @State private var mapViewModel = MapViewModel()
    @State private var showFriends = false
    @State private var showShareCard = false
    @State private var selectedLocation: Location?

    @State private var pendingCount = 0
    
    

    
    var body: some View {
        
        NavigationStack {
            
            
            ScrollView {
                if let user = authViewModel.currentUser {
                    VStack(spacing: 0) {
                        // Profile Header
                        
                        
                        // Stats Bar
                        statsBar(user: user)
                            .padding(.top, 4)
                        if pendingCount > 0 {
                            Text("Freundschaftsanfragen: \(pendingCount)")
                                .foregroundColor(.accentColor)
                                .bold()
                        }
                        // Action Buttons
                        actionButtons
                            .padding(.horizontal)
                            .padding(.top, 16)
                        
                        
                        
                        
                        
                        Spacer(minLength: 32)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)

            .sheet(isPresented: $showFriends) {
                FriendsView(currentUser: authViewModel.currentUser)
            }
            .sheet(isPresented: $showShareCard) {
                if let user = authViewModel.currentUser {
                    ProfileShareCardView(user: user)
                }
            }
            .sheet(item: $selectedLocation) { location in
                NavigationStack {
                    LocationDetailView(location: location, currentUserId: authViewModel.currentUser?.id, onDelete: {
                        selectedLocation = nil
                        if let userId = authViewModel.currentUser?.id {
                            Task { await mapViewModel.loadLocations(userId: userId) }
                        }
                    }, onUpdate: { updated in
                        if let index = mapViewModel.locations.firstIndex(where: { $0.id == updated.id }) {
                            mapViewModel.locations[index] = updated
                        }
                    })
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Fertig") { selectedLocation = nil }
                        }
                    }
                }
            }
            .task {
                guard let userId = authViewModel.currentUser?.id else { return }
                await friendsViewModel.loadFriends(userId: userId)
                await mapViewModel.loadLocations(userId: userId)
                await loadPendingRequests()
            }
            .refreshable {
                guard let userId = authViewModel.currentUser?.id else { return }
                await friendsViewModel.loadFriends(userId: userId)
                await mapViewModel.loadLocations(userId: userId)
                await loadPendingRequests()
            }
        }
        }
    
    
    func loadPendingRequests() async {
            guard let userId = authViewModel.currentUser?.id else { return }
            let viewModel = FriendsViewModel()
            await viewModel.loadPendingRequests(userId: userId)
            pendingCount = viewModel.pendingRequests.count
        }

    // MARK: - Profile Header

  

    // MARK: - Stats

    private func statsBar(user: User) -> some View {
        HStack {
            Button {
                showFriends = true
            } label: {
                statItem(value: "\(friendsViewModel.friends.count)", label: "Freunde")
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 32)

            statItem(value: "\(myLocationCount)", label: "Orte")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 32)
    }

    private var myLocationCount: Int {
        guard let userId = authViewModel.currentUser?.id else { return 0 }
        return mapViewModel.locations.filter { $0.createdBy == userId }.count
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            

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
        }
    }

    // MARK: - My Locations



    private func locationCard(location: Location) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let urlString = location.imageUrls.first,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(ProgressView())
                }
                .frame(width: 140, height: 140)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 140, height: 140)
                    .overlay(
                        Image(systemName: "mappin")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                Text(location.category)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
        }
        .frame(width: 140)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

}

    

    
