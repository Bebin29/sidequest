//
//  FriendsView.swift
//  Sidequest
//

import SwiftUI

struct FriendsView: View {
    @State private var viewModel = FriendsViewModel()
    @State private var searchText = ""
    @State private var showSearch = false

    @State private var friendToRemove: Friendship?
    @State private var showRemoveConfirmation = false
    @State private var showScanner = false
    @State private var scannedUser: User?
    @State private var showScannedUserAlert = false

    var currentUser: User?

    var body: some View {
        NavigationStack {
            List {
                // Pending Requests (verbessert)
                if !viewModel.pendingRequests.isEmpty {
                    Section {
                        ForEach(viewModel.pendingRequests) { request in
                            pendingRequestRow(request)
                        }
                    } header: {
                        Text("Anfragen (\(viewModel.pendingRequests.count))")
                    }
                }

                // Freunde-Vorschläge
                if !viewModel.suggestions.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(viewModel.suggestions) { suggestion in
                                    suggestionCard(suggestion)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                    } header: {
                        Text("Vorschläge")
                    }
                }

                // Friends List
                Section("Freunde (\(viewModel.friends.count))") {
                    if viewModel.friends.isEmpty {
                        Text("Noch keine Freunde")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.friends) { friendship in
                            HStack {
                                let friendName = friendship.requesterId == currentUser?.id
                                    ? friendship.receiverUsername
                                    : friendship.requesterUsername

                                Text("@\(friendName)")
                                    .font(.headline)

                                Spacer()

                                Button("Entfernen", role: .destructive) {
                                    friendToRemove = friendship
                                    showRemoveConfirmation = true
                                }
                                .controlSize(.small)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Freunde")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showScanner = true
                        } label: {
                            Image(systemName: "camera")
                        }

                        Button {
                            showSearch = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                FriendSearchView(viewModel: viewModel, currentUser: currentUser) {
                    showSearch = false
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
            .task { await loadAll() }
            .refreshable { await loadAll() }

            // Bestätigungsdialog
            .confirmationDialog(
                "Freund wirklich entfernen?",
                isPresented: $showRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Freund entfernen", role: .destructive) {
                    guard
                        let friendship = friendToRemove,
                        let userId = currentUser?.id
                    else { return }

                    Task {
                        await viewModel.removeFriend(friendshipId: friendship.id, userId: userId)
                    }
                }

                Button("Abbrechen", role: .cancel) { }
            }
        }
    }

    private func loadAll() async {
        guard let userId = currentUser?.id else { return }
        async let f: () = viewModel.loadFriends(userId: userId)
        async let p: () = viewModel.loadPendingRequests(userId: userId)
        async let s: () = viewModel.loadSuggestions(userId: userId)
        _ = await (f, p, s)
    }

    // MARK: - Pending Request Row

    private func pendingRequestRow(_ request: Friendship) -> some View {
        HStack(spacing: 12) {
            // Avatar
            if let urlString = request.requesterProfileImageUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } placeholder: {
                    initialCircle(request.requesterUsername, size: 44)
                }
            } else {
                initialCircle(request.requesterUsername, size: 44)
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
                guard let userId = currentUser?.id else { return }
                Task { await viewModel.acceptRequest(friendshipId: request.id, userId: userId) }
            } label: {
                Text("Annehmen")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.small)

            Button {
                guard let userId = currentUser?.id else { return }
                Task { await viewModel.declineRequest(friendshipId: request.id, userId: userId) }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Suggestion Card

    private func suggestionCard(_ suggestion: FriendSuggestion) -> some View {
        VStack(spacing: 8) {
            // Avatar
            if let urlString = suggestion.profileImageUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } placeholder: {
                    initialCircle(suggestion.username, size: 56)
                }
            } else {
                initialCircle(suggestion.username, size: 56)
            }

            VStack(spacing: 2) {
                if let name = suggestion.displayName {
                    Text(name)
                        .font(.caption.bold())
                        .lineLimit(1)
                }
                Text("@\(suggestion.username)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("\(suggestion.mutualCount) gemeinsame")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }

            Button {
                guard let requesterId = currentUser?.id else { return }
                Task {
                    await viewModel.sendRequest(
                        requesterId: requesterId,
                        receiverUsername: suggestion.username
                    )
                }
            } label: {
                Text("Hinzufügen")
                    .font(.caption2.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(width: 110)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Helpers

    private func initialCircle(_ username: String, size: CGFloat) -> some View {
        Circle()
            .fill(Color(.systemGray4))
            .frame(width: size, height: size)
            .overlay(
                Text(String(username.prefix(1)).uppercased())
                    .font(size > 44 ? .title3.bold() : .caption.bold())
                    .foregroundStyle(.white)
            )
    }
}

struct FriendSearchView: View {
    @Bindable var viewModel: FriendsViewModel
    var currentUser: User?
    var onDismiss: () -> Void
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Username suchen...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onChange(of: searchText) { _, newValue in
                        Task { await viewModel.searchUsers(query: newValue) }
                    }

                if let success = viewModel.successMessage {
                    Text(success)
                        .foregroundStyle(.green)
                        .padding(.horizontal)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
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
            }
            .navigationTitle("Freund hinzufügen")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") { onDismiss() }
                }
            }
        }
    }
}
