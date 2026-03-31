//
//  AdminView.swift
//  Sidequest
//

import SwiftUI

struct AdminView: View {
    @State private var viewModel = AdminViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Lade Benutzer...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("Fehler", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Erneut versuchen") {
                            Task { await viewModel.loadUsers() }
                        }
                    }
                } else if viewModel.users.isEmpty {
                    ContentUnavailableView("Keine Benutzer", systemImage: "person.slash",
                        description: Text("Es sind noch keine Benutzer registriert."))
                } else {
                    List(viewModel.users) { user in
                        UserRow(user: user)
                    }
                }
            }
            .navigationTitle("Admin")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.loadUsers() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Aktualisieren")
                }
            }
            .task {
                await viewModel.loadUsers()
            }
        }
    }
}

struct UserRow: View {
    let user: User

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(user.displayName)
                    .font(.headline)
                if user.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                        .accessibilityLabel("Verifiziert")
                }
                if user.isModerator {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
            Text("@\(user.username)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(user.email)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let bio = user.bio {
                Text(bio)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AdminView()
}
