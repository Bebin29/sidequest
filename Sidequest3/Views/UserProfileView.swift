//
//  UserProfileView.swift
//  Sidequest
//

import SwiftUI
import AudioToolbox

struct UserProfileView: View {
    let userId: UUID
    var currentUserId: UUID?

    @State private var user: User?
    @State private var locations: [Location] = []
    @State private var friends: [Friendship] = []
    @State private var isLoading = true
    @State private var selectedLocation: Location?
    @State private var friendActionInProgress = false

    private let profileService = ProfileService()
    private let locationService = LocationService()
    private let friendshipService = FriendshipService()

    // MARK: - Friendship State

    private var friendshipWithMe: Friendship? {
        guard let currentUserId else { return nil }
        return friends.first {
            ($0.requesterId == currentUserId || $0.receiverId == currentUserId)
        }
    }

    private enum FriendStatus {
        case none, pendingSent, pendingReceived, accepted
    }

    private var friendStatus: FriendStatus {
        guard let friendship = friendshipWithMe, let currentUserId else { return .none }
        switch friendship.status {
        case .accepted: return .accepted
        case .pending:
            return friendship.requesterId == currentUserId ? .pendingSent : .pendingReceived
        default: return .none
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding(.top, 60)
            } else if let user {
                VStack(spacing: 0) {
                    profileHeader(user: user)

                    statsBar
                        .padding(.top, 4)

                    if userId != currentUserId {
                        friendActionButton
                            .padding(.horizontal)
                            .padding(.top, 16)
                    }

                    userLocations
                        .padding(.top, 24)

                    memberSince(user: user)
                        .padding(.top, 24)

                    Spacer(minLength: 32)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("@\(user?.username ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadData() }
        .refreshable { await loadData() }
        .sheet(item: $selectedLocation) { location in
            NavigationStack {
                LocationDetailView(location: location, currentUserId: currentUserId)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Fertig") { selectedLocation = nil }
                        }
                    }
            }
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Profile Header

    private func profileHeader(user: User) -> some View {
        VStack(spacing: 12) {
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
            .overlay(Circle().stroke(Theme.imagePlaceholder, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.displayName)
                        .font(.title2.bold())
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                            .font(.subheadline)
                            .accessibilityLabel("Verifiziert")
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
            statItem(
                value: "\(friends.filter { $0.status == .accepted }.count)",
                label: "Freunde"
            )

            Divider()
                .frame(height: 32)

            statItem(value: "\(locations.count)", label: "Orte")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 32)
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

    // MARK: - Friend Action Button

    private var friendActionButton: some View {
        Group {
            switch friendStatus {
            case .none:
                Button {
                    Task { await sendFriendRequest() }
                } label: {
                    Label("Freund hinzufügen", systemImage: "person.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(GlassProminentButtonStyle(color: Theme.accent))
                .disabled(friendActionInProgress)

            case .pendingSent:
                Label("Anfrage gesendet", systemImage: "clock")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .adaptiveGlass(in: Capsule())

            case .pendingReceived:
                HStack(spacing: 8) {
                    Button {
                        Task { await acceptFriendRequest() }
                    } label: {
                        Text("Annehmen")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(GlassProminentButtonStyle(color: Theme.accent))

                    Button {
                        Task { await declineFriendRequest() }
                    } label: {
                        Text("Ablehnen")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(GlassButtonStyle())
                }

            case .accepted:
                Label("Befreundet", systemImage: "person.2.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .adaptiveInteractiveGlass(in: Capsule())
            }
        }
    }

    // MARK: - Locations

    private var userLocations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Orte")
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
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(locations) { location in
                            Button {
                                selectedLocation = location
                            } label: {
                                locationCard(location)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func locationCard(_ location: Location) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let urlString = location.imageUrls.first,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Theme.imagePlaceholder)
                        .overlay(ProgressView())
                }
                .frame(width: 140, height: 140)
                .clipped()
            } else {
                Rectangle()
                    .fill(Theme.imagePlaceholder)
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
                    .lineLimit(2)
                Text(location.category)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
        }
        .frame(width: 140)
        .adaptiveGlass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Member Since

    private func memberSince(user: User) -> some View {
        HStack {
            Spacer()
            Label(memberSinceText(from: user.createdAt), systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }

    private static let parseFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    private func memberSinceText(from dateString: String) -> String {
        if let date = Self.parseFormatter.date(from: String(dateString.prefix(19))) {
            return "Mitglied seit \(Self.displayFormatter.string(from: date))"
        }
        return "Mitglied"
    }

    // MARK: - Placeholder

    private var profilePlaceholder: some View {
        Circle()
            .fill(Theme.imagePlaceholder)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.textPrimary)
            )
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        async let userFetch = profileService.getUser(id: userId)
        async let locationsFetch = locationService.fetchLocations(userId: userId)
        async let friendsFetch = friendshipService.getFriends(userId: userId)

        user = try? await userFetch
        let allLocations = (try? await locationsFetch) ?? []
        locations = allLocations.filter { $0.createdBy == userId }
        friends = (try? await friendsFetch) ?? []
    }

    // MARK: - Friend Actions

    private func sendFriendRequest() async {
        guard let currentUserId, let username = user?.username else { return }
        friendActionInProgress = true
        defer { friendActionInProgress = false }
        do {
            _ = try await friendshipService.sendRequest(requesterId: currentUserId, receiverUsername: username)
            AudioServicesPlaySystemSound(1407)
            await loadData()
        } catch {}
    }

    private func acceptFriendRequest() async {
        guard let friendship = friendshipWithMe, currentUserId != nil else { return }
        do {
            _ = try await friendshipService.updateStatus(friendshipId: friendship.id, status: "accepted")
            await loadData()
        } catch {}
    }

    private func declineFriendRequest() async {
        guard let friendship = friendshipWithMe else { return }
        do {
            _ = try await friendshipService.updateStatus(friendshipId: friendship.id, status: "declined")
            await loadData()
        } catch {}
    }
}
