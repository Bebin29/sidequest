//
//  FriendsView.swift
//  Sidequest
//

import SwiftUI

struct FriendsView: View {
    @State private var viewModel = FriendsViewModel()
    @State private var searchText = ""
    @State private var showSearch = false
    
    // NEU: für Bestätigung
    @State private var friendToRemove: Friendship?
    @State private var showRemoveConfirmation = false
    
    var currentUser: User?

    var body: some View {
        NavigationStack {
            List {
                // Pending Requests
                if !viewModel.pendingRequests.isEmpty {
                    Section("Anfragen (\(viewModel.pendingRequests.count))") {
                        ForEach(viewModel.pendingRequests) { request in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("@\(request.requesterUsername)")
                                        .font(.headline)
                                }
                                Spacer()
                                Button("Annehmen") {
                                    guard let userId = currentUser?.id else { return }
                                    Task { await viewModel.acceptRequest(friendshipId: request.id, userId: userId) }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)

                                Button("Ablehnen") {
                                    guard let userId = currentUser?.id else { return }
                                    Task { await viewModel.declineRequest(friendshipId: request.id, userId: userId) }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
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
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                FriendSearchView(viewModel: viewModel, currentUser: currentUser) {
                    showSearch = false
                }
            }
            .task {
                guard let userId = currentUser?.id else { return }
                await viewModel.loadFriends(userId: userId)
                await viewModel.loadPendingRequests(userId: userId)
            }
            .refreshable {
                guard let userId = currentUser?.id else { return }
                await viewModel.loadFriends(userId: userId)
                await viewModel.loadPendingRequests(userId: userId)
            }
            
            // NEU: Bestätigungsdialog
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

#Preview {
    Home(authViewModel: AuthViewModel())
}
