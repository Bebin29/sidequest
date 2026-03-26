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
    @State private var showLogoutAlert = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let user = authViewModel.currentUser {
                    VStack(spacing: 0) {
                        // Profile Header
                        profileHeader(user: user)

                        // Stats Bar
                        statsBar(user: user)
                            .padding(.top, 4)

                        // Action Buttons
                        actionButtons
                            .padding(.horizontal)
                            .padding(.top, 16)

                        // Meine Orte
                        myLocations
                            .padding(.top, 24)

                        // Settings Section
                        settingsSection
                            .padding(.top, 24)
                            .padding(.horizontal)

                        Spacer(minLength: 32)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(authViewModel: authViewModel)
            }
            .task {
                guard let userId = authViewModel.currentUser?.id else { return }
                await friendsViewModel.loadFriends(userId: userId)
                await mapViewModel.loadLocations(userId: userId)
            }
            .refreshable {
                guard let userId = authViewModel.currentUser?.id else { return }
                await friendsViewModel.loadFriends(userId: userId)
                await mapViewModel.loadLocations(userId: userId)
            }
        }
    }

    // MARK: - Profile Header

    private func profileHeader(user: User) -> some View {
        VStack(spacing: 12) {
            // Avatar
            Group {
                if let urlString = user.profileImageUrl,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        profilePlaceholder
                    }
                } else {
                    profilePlaceholder
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

            // Name & Username
            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.title2.bold())

                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Bio
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Stats

    private func statsBar(user: User) -> some View {
        HStack {
            statItem(value: "\(friendsViewModel.friends.count)", label: "Freunde")
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
                showEditProfile = true
            } label: {
                Text("Profil bearbeiten")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Button {
                // Share
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - My Locations

    private var myLocations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meine Orte")
                .font(.headline)
                .padding(.horizontal)

            let ownLocations = mapViewModel.locations.filter { $0.createdBy == authViewModel.currentUser?.id }

            if ownLocations.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.slash")
                            .font(.title)
                            .foregroundStyle(.tertiary)
                        Text("Noch keine Orte hinzugefuegt")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(ownLocations) { location in
                            locationCard(location: location)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

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

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "shield", title: "Datenschutz")
            Divider().padding(.leading, 44)
            settingsRow(icon: "info.circle", title: "Impressum")
            Divider().padding(.leading, 44)
            Button {
                showLogoutAlert = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .frame(width: 20)
                        .foregroundStyle(.red)
                    Text("Abmelden")
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Abmelden?", isPresented: $showLogoutAlert) {
            Button("Abmelden", role: .destructive) {
                authViewModel.signOut()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Moechtest du dich wirklich abmelden?")
        }
    }

    private func settingsRow(icon: String, title: String) -> some View {
        Button {
            // Navigation
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundStyle(.primary)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(Color(.systemGray4))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
            )
    }
}

#Preview {
    let viewModel = AuthViewModel()
    viewModel.currentUser = .preview
    return Profile(authViewModel: viewModel)
}

extension User {
    static let preview = User(
        id: UUID(uuidString: "e5f9bcaa-20f7-4296-a7f1-f2caf539d474")!,
        email: "oleboehm4321@icloud.com",
        username: "oleboehm4321",
        displayName: "Ole Boehm",
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
