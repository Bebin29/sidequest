//
//  MyProfileView.swift
//  Sidequest
//

import SwiftUI

struct MyProfileView: View {
    let user: User
    var friendCount: Int

    @State private var locations: [Location] = []
    @State private var isLoading = true
    @State private var selectedLocation: Location?

    private let locationService = LocationService()

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding(.top, 60)
            } else {
                VStack(spacing: 0) {
                    profileHeader
                    statsBar
                        .padding(.top, 4)
                    userLocations
                        .padding(.top, 24)
                    Spacer(minLength: 32)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("@\(user.username)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadLocations() }
        .refreshable { await loadLocations() }
        .sheet(item: $selectedLocation) { location in
            NavigationStack {
                LocationDetailView(location: location, currentUserId: user.id)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Fertig") { selectedLocation = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Group {
                if let urlString = user.profileImageUrl,
                   let url = URL(string: urlString) {
                    CachedAsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
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

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.displayName)
                        .font(.title2.bold())
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                            .font(.subheadline)
                    }
                }
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

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

    private var statsBar: some View {
        HStack {
            VStack(spacing: 2) {
                Text("\(friendCount)")
                    .font(.title3.bold())
                Text("Freunde")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 32)

            VStack(spacing: 2) {
                Text("\(locations.count)")
                    .font(.title3.bold())
                Text("Orte")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 32)
    }

    // MARK: - Locations

    private var userLocations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meine Orte")
                .font(.headline)
                .padding(.horizontal)

            if locations.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.slash")
                            .font(.title)
                            .foregroundStyle(.tertiary)
                        Text("Noch keine Orte")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(locations) { location in
                            Button { selectedLocation = location } label: {
                                locationCard(location)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func locationCard(_ location: Location) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let urlString = location.imageUrls.first,
               let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
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

    // MARK: - Helpers

    private var profilePlaceholder: some View {
        Circle()
            .fill(Color(.systemGray4))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
            )
    }

    private func loadLocations() async {
        isLoading = true
        do {
            let fetched = try await locationService.fetchLocations(userId: user.id)
            locations = fetched.filter { $0.createdBy == user.id }
        } catch {}
        isLoading = false
    }
}
