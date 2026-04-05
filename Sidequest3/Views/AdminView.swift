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
                if viewModel.isLoading && viewModel.serverStatus == nil {
                    ProgressView("Lade Daten...")
                } else if let error = viewModel.errorMessage, viewModel.serverStatus == nil {
                    ContentUnavailableView {
                        Label("Fehler", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Erneut versuchen") {
                            Task { await viewModel.loadAll() }
                        }
                    }
                } else {
                    List {
                        if let status = viewModel.serverStatus {
                            MonitoringSection(status: status)
                        } else if let error = viewModel.monitoringError {
                            Section("Server-Monitoring") {
                                Label(error, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }

                        Section("Benutzer (\(viewModel.users.count))") {
                            if viewModel.users.isEmpty {
                                Text("Keine Benutzer registriert")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(viewModel.users) { user in
                                    UserRow(user: user)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Admin")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.loadAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Aktualisieren")
                }
            }
            .task {
                guard viewModel.serverStatus == nil else { return }
                await viewModel.loadAll()
            }
            .refreshable {
                await viewModel.loadAll()
            }
        }
    }
}

// MARK: - Monitoring

struct MonitoringSection: View {
    let status: ServerStatus

    var body: some View {
        Section("Server-Monitoring") {
            // Status
            HStack {
                Label("Status", systemImage: status.isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(status.isHealthy ? .green : .orange)
                Spacer()
                Text(status.isHealthy ? "Online" : "Eingeschränkt")
                    .foregroundStyle(.secondary)
            }

            // Uptime
            HStack {
                Label("Uptime", systemImage: "clock.fill")
                Spacer()
                Text(status.formattedUptime)
                    .foregroundStyle(.secondary)
            }

            // Node Version
            HStack {
                Label("Node.js", systemImage: "server.rack")
                Spacer()
                Text(status.server.nodeVersion)
                    .foregroundStyle(.secondary)
            }

            // Speicher
            HStack {
                Label("RAM (Heap)", systemImage: "memorychip")
                Spacer()
                Text("\(status.server.memoryMb.heapUsed) / \(status.server.memoryMb.heapTotal) MB")
                    .foregroundStyle(.secondary)
            }
        }

        Section("Datenbank") {
            // DB-Status
            HStack {
                Label("Verbindung", systemImage: status.database.connected ? "bolt.fill" : "bolt.slash.fill")
                    .foregroundStyle(status.database.connected ? .green : .red)
                Spacer()
                if let ms = status.database.responseMs {
                    Text("\(ms) ms")
                        .foregroundStyle(.secondary)
                } else if let error = status.database.error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            // Tabellen-Statistiken
            if let tables = status.tables {
                StatRow(label: "Benutzer", icon: "person.2.fill", count: tables.users)
                StatRow(label: "Locations", icon: "mappin.circle.fill", count: tables.locations)
                StatRow(label: "Bewertungen", icon: "star.fill", count: tables.ratings)
                StatRow(label: "Kommentare", icon: "bubble.left.fill", count: tables.comments)
                StatRow(label: "Freundschaften", icon: "heart.fill", count: tables.friendships)
                StatRow(label: "Benachrichtigungen", icon: "bell.fill", count: tables.notifications)
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let icon: String
    let count: Int

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            Text("\(count)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

// MARK: - User Row

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
