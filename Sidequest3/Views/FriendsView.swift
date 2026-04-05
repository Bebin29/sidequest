//
//  FriendsView.swift
//  Sidequest
//

import SwiftUI

// MARK: - FriendsView (Main Container)

struct FriendsView: View {
    @State private var viewModel = FriendsViewModel()
    @State private var showSearch = false
    @State private var friendToRemove: Friendship?
    @State private var showRemoveConfirmation = false
    @State private var myLocationCount: Int = 0
    @Bindable var authViewModel: AuthViewModel
    var currentUser: User?

    private let locationService = LocationService()

    var body: some View {
        NavigationStack {
            Group {
            if viewModel.isLoading && viewModel.friends.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 18) {
                        if let user = currentUser {
                            MyProfileCard(
                                user: user,
                                locationCount: myLocationCount,
                                friendCount: viewModel.friends.count
                            )
                        }

                        if !viewModel.pendingRequests.isEmpty {
                            PendingRequestsSection(
                                requests: viewModel.pendingRequests,
                                onAccept: { id in
                                    guard let userId = currentUser?.id else { return }
                                    await viewModel.acceptRequest(friendshipId: id, userId: userId)
                                },
                                onDecline: { id in
                                    guard let userId = currentUser?.id else { return }
                                    await viewModel.declineRequest(friendshipId: id, userId: userId)
                                }
                            )
                        }

                        if !viewModel.sentRequests.isEmpty {
                            SentRequestsSection(
                                requests: viewModel.sentRequests,
                                onWithdraw: { id in
                                    guard let userId = currentUser?.id else { return }
                                    await viewModel.withdrawRequest(friendshipId: id, userId: userId)
                                }
                            )
                        }

                        if !viewModel.suggestions.isEmpty {
                            FriendSuggestionsSection(
                                suggestions: viewModel.suggestions,
                                onAdd: { username in
                                    guard let requesterId = currentUser?.id else { return }
                                    await viewModel.sendRequest(requesterId: requesterId, receiverUsername: username)
                                }
                            )
                        }

                        FriendsListSection(
                            friends: viewModel.friends,
                            currentUserId: currentUser?.id,
                            onRemove: { friendship in
                                friendToRemove = friendship
                                showRemoveConfirmation = true
                            }
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            } // Group
            .background(Color(UIColor.systemGray6).ignoresSafeArea())
            .navigationTitle("Freunde")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .offset(y: 4)
                    }
                    .accessibilityLabel("Freund hinzufuegen")
                }
            }
            .sheet(isPresented: $showSearch) {
                FriendSearchView(viewModel: viewModel, currentUser: currentUser) {
                    showSearch = false
                }
                .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Freund wirklich entfernen?",
                isPresented: $showRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Freund entfernen", role: .destructive) {
                    guard let friendship = friendToRemove,
                          let userId = currentUser?.id else { return }
                    Task {
                        await viewModel.removeFriend(friendshipId: friendship.id, userId: userId)
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            }
            .task { await loadAll() }
            .refreshable { await loadAll() }
        }
    }

    private func loadAll() async {
        guard let userId = currentUser?.id else { return }
        async let f: () = viewModel.loadFriends(userId: userId)
        async let p: () = viewModel.loadPendingRequests(userId: userId)
        async let sr: () = viewModel.loadSentRequests(userId: userId)
        async let s: () = viewModel.loadSuggestions(userId: userId)
        _ = await (f, p, sr, s)

        if let locations = try? await locationService.fetchLocations(userId: userId) {
            myLocationCount = locations.filter { $0.createdBy == userId }.count
        }
    }
}

// MARK: - MyProfileCard

private struct MyProfileCard: View {
    let user: User
    let locationCount: Int
    let friendCount: Int

    var body: some View {
        NavigationLink {
            MyProfileView(user: user, friendCount: friendCount)
        } label: {
            HStack(spacing: 16) {
                AvatarView(url: user.profileImageUrl, size: .medium)

                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("@\(user.username) · \(locationCount) Orte")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()
            }
            .padding()
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PendingRequestsSection

private struct PendingRequestsSection: View {
    let requests: [Friendship]
    let onAccept: (UUID) async -> Void
    let onDecline: (UUID) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Anfragen (\(requests.count))")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 4)

            ForEach(requests) { request in
                requestCard(request)
            }
        }
    }

    private func requestCard(_ request: Friendship) -> some View {
        HStack(spacing: 12) {
            AvatarView(url: request.requesterProfileImageUrl, fallbackInitial: request.requesterUsername, size: .medium)

            VStack(alignment: .leading, spacing: 2) {
                if let displayName = request.requesterDisplayName {
                    Text(displayName)
                        .font(.subheadline.bold())
                }
                Text("@\(request.requesterUsername)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let count = request.mutualCount, count > 0 {
                    Text("\(count) gemeinsame Freunde")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }

            Spacer()

            Button {
                Task { await onAccept(request.id) }
            } label: {
                Image(systemName: "checkmark")
                    .font(.subheadline.bold())
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Annehmen")
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.small)

            Button {
                Task { await onDecline(request.id) }
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.bold())
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Ablehnen")
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

}

// MARK: - SentRequestsSection

private struct SentRequestsSection: View {
    let requests: [Friendship]
    let onWithdraw: (UUID) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gesendet (\(requests.count))")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 4)

            ForEach(requests) { request in
                sentCard(request)
            }
        }
    }

    private func sentCard(_ request: Friendship) -> some View {
        HStack(spacing: 12) {
            AvatarView(url: request.receiverProfileImageUrl, fallbackInitial: request.receiverUsername, size: .medium)

            VStack(alignment: .leading, spacing: 2) {
                if let displayName = request.receiverDisplayName {
                    Text(displayName)
                        .font(.subheadline.bold())
                }
                Text("@\(request.receiverUsername)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let count = request.mutualCount, count > 0 {
                    Text("\(count) gemeinsame Freunde")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }

            Spacer()

            Button {
                Task { await onWithdraw(request.id) }
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.bold())
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Zurückziehen")
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.small)
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - FriendSuggestionsSection

private struct FriendSuggestionsSection: View {
    let suggestions: [FriendSuggestion]
    let onAdd: (String) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Vorschläge")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(suggestions) { suggestion in
                        suggestionChip(suggestion)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func suggestionChip(_ suggestion: FriendSuggestion) -> some View {
        HStack(spacing: 8) {
            AvatarView(url: suggestion.profileImageUrl, fallbackInitial: suggestion.username, size: .small)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 0) {
                Text(suggestion.displayName ?? suggestion.username)
                    .font(.caption.bold())
                    .lineLimit(2)
                Text("\(suggestion.mutualCount) gem.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await onAdd(suggestion.username) }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityLabel("Hinzufuegen")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.cardBackground)
        .clipShape(Capsule())
    }
}

// MARK: - FriendsListSection

private struct FriendsListSection: View {
    let friends: [Friendship]
    let currentUserId: UUID?
    let onRemove: (Friendship) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Freunde (\(friends.count))")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 4)

            if friends.isEmpty {
                HStack {
                    Spacer()
                    Text("Noch keine Freunde")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(friends.enumerated()), id: \.element.id) { index, friendship in
                        friendRow(friendship)

                        if index < friends.count - 1 {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }

    private func friendRow(_ friendship: Friendship) -> some View {
        let isRequester = friendship.requesterId == currentUserId
        let friendUsername = isRequester ? friendship.receiverUsername : friendship.requesterUsername
        let friendDisplayName = isRequester ? friendship.receiverDisplayName : friendship.requesterDisplayName
        let friendImageUrl = isRequester ? friendship.receiverProfileImageUrl : friendship.requesterProfileImageUrl
        let friendId = isRequester ? friendship.receiverId : friendship.requesterId
        let spotCount = isRequester ? friendship.receiverSpotCount : friendship.requesterSpotCount

        return NavigationLink {
            UserProfileView(userId: friendId, currentUserId: currentUserId)
        } label: {
            HStack(spacing: 12) {
                AvatarView(url: friendImageUrl, fallbackInitial: friendUsername, size: .medium)

                VStack(alignment: .leading, spacing: 2) {
                    Text(friendDisplayName ?? friendUsername)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    if let count = spotCount {
                        Text("@\(friendUsername) · \(count) Orte")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("@\(friendUsername)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                onRemove(friendship)
            } label: {
                Label("Freund entfernen", systemImage: "person.badge.minus")
            }
        }
    }
}

// MARK: - FriendSearchView

struct FriendSearchView: View {
    @Bindable var viewModel: FriendsViewModel
    var currentUser: User?
    var onDismiss: () -> Void
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Username suchen...", text: $searchText)
                    .autocorrectionDisabled()
                    .padding()
                    .background(
                        // Liquid Glass Effekt
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    )
                    .foregroundStyle(Theme.textPrimary)
                    .font(.headline)
                    .padding()
                    .onChange(of: searchText) { _, newValue in
                        Task { await viewModel.searchUsers(query: newValue) }
                    }
                
                
                
                
                
                
               /*
                TextField("Username suchen...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onChange(of: searchText) { _, newValue in
                        Task { await viewModel.searchUsers(query: newValue) }
                    }
                */

                if let success = viewModel.successMessage {
                    Text(success)
                        .foregroundStyle(Theme.success)
                        .padding(.horizontal)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(Theme.destructive)
                        .padding(.horizontal)
                }

                List(viewModel.searchResults) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.displayName)
                                .font(.headline)
                            Text("@\(user.username)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if user.id != currentUser?.id {
                            Button("Anfrage senden") {
                                guard let requesterId = currentUser?.id else { return }
                                Task {
                                    await viewModel.sendRequest(
                                        requesterId: requesterId,
                                        receiverUsername: user.username
                                    )
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Freund hinzufügen")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") { onDismiss() }
                }
            }
        }
    }
}
