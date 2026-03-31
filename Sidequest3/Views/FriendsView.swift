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
    @State private var showShareCard = false
    var currentUser: User?

    private let locationService = LocationService()

    var body: some View {
        NavigationStack {
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
            .background(Color(UIColor.systemGray6).ignoresSafeArea())
            .navigationTitle("Freunde")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareCard = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Teilen")
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "person.badge.plus")
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
            .sheet(isPresented: $showShareCard) {
                if let user = authViewModel.currentUser {
                    ProfileShareCardView(user: user)
                        .presentationDragIndicator(.visible)
                }
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
        async let s: () = viewModel.loadSuggestions(userId: userId)
        _ = await (f, p, s)

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
                Group {
                    if let urlString = user.profileImageUrl,
                       let url = URL(string: urlString) {
                        CachedAsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundStyle(Theme.accent)
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundStyle(Theme.accent)
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())

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
            if let urlString = request.requesterProfileImageUrl,
               let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initialCircle(request.requesterUsername)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                initialCircle(request.requesterUsername)
                    .frame(width: 44, height: 44)
            }

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
                Text("Annehmen")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.small)

            Button {
                Task { await onDecline(request.id) }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
            }
            .accessibilityLabel("Ablehnen")
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func initialCircle(_ username: String) -> some View {
        Circle()
            .fill(Theme.imagePlaceholder)
            .overlay(
                Text(String(username.prefix(1)).uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(Theme.textPrimary)
            )
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
            if let urlString = suggestion.profileImageUrl,
               let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Theme.imagePlaceholder)
                        .overlay(
                            Text(String(suggestion.username.prefix(1)).uppercased())
                                .font(.caption).fontWeight(.bold)
                                .foregroundStyle(Theme.textPrimary)
                        )
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                Circle().fill(Theme.imagePlaceholder)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(suggestion.username.prefix(1)).uppercased())
                            .font(.caption).fontWeight(.bold)
                            .foregroundStyle(Theme.textPrimary)
                    )
            }

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
                if let urlString = friendImageUrl,
                   let url = URL(string: urlString) {
                    CachedAsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Theme.imagePlaceholder)
                            .overlay(
                                Text(String(friendUsername.prefix(1)).uppercased())
                                    .font(.caption.bold())
                                    .foregroundStyle(Theme.textPrimary)
                            )
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Circle().fill(Theme.imagePlaceholder)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(friendUsername.prefix(1)).uppercased())
                                .font(.caption.bold())
                                .foregroundStyle(Theme.textPrimary)
                        )
                }

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
    @State private var showScanner = false
    @State private var scannedUser: User?
    @State private var showScannedUserAlert = false

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

                Button {
                    showScanner = true
                } label: {
                    Label("Ring-Code scannen", systemImage: "camera")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Freund hinzufügen")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") { onDismiss() }
                }
            }
            .fullScreenCover(isPresented: $showScanner) {
                RingCodeScannerView(currentUserId: currentUser?.id) { user in
                    scannedUser = user
                    showScanner = false
                    showScannedUserAlert = true
                }
            }
            .alert("Freund hinzufügen?", isPresented: $showScannedUserAlert) {
                Button("Anfrage senden") {
                    guard let requesterId = currentUser?.id,
                          let receiver = scannedUser else { return }
                    Task {
                        await viewModel.sendRequest(
                            requesterId: requesterId,
                            receiverUsername: receiver.username
                        )
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                if let user = scannedUser {
                    Text("\(user.displayName) (@\(user.username)) gefunden. Freundschaftsanfrage senden?")
                }
            }
        }
    }
}
