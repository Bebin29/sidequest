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
                if viewModel.isLoading && viewModel.dashboard == nil {
                    ProgressView("Lade Dashboard...")
                } else if let error = viewModel.errorMessage, viewModel.dashboard == nil {
                    ContentUnavailableView {
                        Label("Fehler", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Erneut versuchen") {
                            Task { await viewModel.loadDashboard() }
                        }
                    }
                } else if let data = viewModel.dashboard {
                    ScrollView {
                        VStack(spacing: 16) {
                            ServerHealthSection(data: data)
                            DatabaseSection(data: data)

                            if let analytics = data.userAnalytics {
                                UserAnalyticsSection(analytics: analytics)
                            }
                            if let analytics = data.locationAnalytics {
                                LocationAnalyticsSection(analytics: analytics)
                            }
                            if let analytics = data.socialAnalytics {
                                SocialAnalyticsSection(analytics: analytics)
                            }
                            if let feed = data.activityFeed, !feed.isEmpty {
                                ActivityFeedSection(items: feed)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.loadDashboard() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                guard viewModel.dashboard == nil else { return }
                await viewModel.loadDashboard()
            }
            .refreshable {
                await viewModel.loadDashboard()
            }
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }
}

// MARK: - Server Health

private struct ServerHealthSection: View {
    let data: DashboardData

    var body: some View {
        SectionHeader(title: "Server", icon: "server.rack")

        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns, spacing: 10) {
            StatCard(
                title: "Status",
                value: data.isHealthy ? "Online" : "Eingeschraenkt",
                icon: data.isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                color: data.isHealthy ? .green : .orange
            )
            StatCard(title: "Uptime", value: data.formattedUptime, icon: "clock.fill", color: .blue)
            StatCard(title: "Node.js", value: data.server.nodeVersion, icon: "cpu", color: .purple)
            StatCard(
                title: "RAM (Heap)",
                value: "\(data.server.memoryMb.heapUsed)/\(data.server.memoryMb.heapTotal) MB",
                icon: "memorychip",
                color: .orange
            )
            StatCard(title: "Abfrage", value: "\(data.queryMs) ms", icon: "bolt.fill", color: .yellow)
        }
    }
}

// MARK: - Database

private struct DatabaseSection: View {
    let data: DashboardData

    var body: some View {
        SectionHeader(title: "Datenbank", icon: "cylinder")

        VStack(spacing: 0) {
            // Connection + DB Size
            HStack {
                Label("Verbindung", systemImage: data.database.connected ? "bolt.fill" : "bolt.slash.fill")
                    .foregroundStyle(data.database.connected ? .green : .red)
                Spacer()
                if let ms = data.database.responseMs {
                    Text("\(ms) ms")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if let dbSize = data.database.dbSize {
                Divider().padding(.horizontal, 14)
                HStack {
                    Label("Gesamtgroesse", systemImage: "internaldrive")
                    Spacer()
                    Text(dbSize).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }

            // Table rows + sizes
            if let tables = data.tables {
                let sizes = data.database.tableSizes
                Divider().padding(.horizontal, 14)
                TableRow(label: "Benutzer", icon: "person.2.fill", count: tables.users, size: sizes?.users)
                Divider().padding(.horizontal, 14)
                TableRow(label: "Locations", icon: "mappin.circle.fill", count: tables.locations, size: sizes?.locations)
                Divider().padding(.horizontal, 14)
                TableRow(label: "Kommentare", icon: "bubble.left.fill", count: tables.comments, size: sizes?.comments)
                Divider().padding(.horizontal, 14)
                TableRow(label: "Freundschaften", icon: "heart.fill", count: tables.friendships, size: sizes?.friendships)
                Divider().padding(.horizontal, 14)
                TableRow(label: "Benachrichtigungen", icon: "bell.fill", count: tables.notifications, size: sizes?.notifications)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }
}

private struct TableRow: View {
    let label: String
    let icon: String
    let count: Int
    let size: String?

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
            Spacer()
            Text("\(count) Zeilen")
                .monospacedDigit()
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let size {
                Text("(\(size))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

// MARK: - User Analytics

private struct UserAnalyticsSection: View {
    let analytics: UserAnalytics

    var body: some View {
        SectionHeader(title: "Benutzer-Analyse", icon: "person.2")

        // Growth chart
        VStack(alignment: .leading, spacing: 8) {
            Text("Registrierungen (30 Tage)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            MiniBarChart(data: analytics.growth, color: .blue)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))

        // Engagement grid
        let eng = analytics.engagement
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns, spacing: 10) {
            StatCard(title: "Gesamt", value: "\(eng.total)", icon: "person.fill", color: .blue)
            StatCard(title: "Aktiv (24h)", value: "\(eng.active24h)", icon: "bolt.heart.fill", color: .green)
            StatCard(title: "Aktiv (7 Tage)", value: "\(eng.active7d)", icon: "calendar", color: .teal)
            StatCard(title: "Mit Profilbild", value: "\(eng.withAvatar)", icon: "camera.fill", color: .purple)
            StatCard(title: "Mit Bio", value: "\(eng.withBio)", icon: "text.quote", color: .orange)
            StatCard(title: "Verifiziert", value: "\(eng.verifiedCount)", icon: "checkmark.seal.fill", color: .blue)
        }

        // Top contributors
        if !analytics.topContributors.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Top Beitragende")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(analytics.topContributors) { user in
                    HStack {
                        Text(user.displayName)
                            .font(.subheadline)
                        Text("@\(user.username)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Label("\(user.spotCount)", systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Label("\(user.commentCount)", systemImage: "bubble.left")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        }
    }
}

// MARK: - Location Analytics

private struct LocationAnalyticsSection: View {
    let analytics: LocationAnalytics

    var body: some View {
        SectionHeader(title: "Location-Analyse", icon: "mappin.and.ellipse")

        // Growth chart
        VStack(alignment: .leading, spacing: 8) {
            Text("Neue Spots (30 Tage)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            MiniBarChart(data: analytics.growth, color: .orange)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))

        // Category distribution
        if !analytics.categories.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Kategorien")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                let maxCount = analytics.categories.map(\.count).max() ?? 1
                ForEach(analytics.categories) { cat in
                    HStack(spacing: 8) {
                        Text(cat.category)
                            .font(.caption)
                            .frame(width: 100, alignment: .leading)
                            .lineLimit(1)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LocationCategory.color(for: cat.category))
                                .frame(width: max(4, geo.size.width * CGFloat(cat.count) / CGFloat(maxCount)))
                        }
                        .frame(height: 16)
                        Text("\(cat.count)")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        }
    }
}

// MARK: - Social Analytics

private struct SocialAnalyticsSection: View {
    let analytics: SocialAnalytics

    var body: some View {
        SectionHeader(title: "Soziales Netzwerk", icon: "heart.circle")

        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns, spacing: 10) {
            StatCard(title: "Freundschaften", value: "\(analytics.friendships.accepted)", icon: "heart.fill", color: .pink)
            StatCard(title: "Ausstehend", value: "\(analytics.friendships.pending)", icon: "hourglass", color: .orange)
            if let avg = analytics.network.avgFriendsPerUser {
                StatCard(title: "Freunde/User", value: String(format: "%.1f", avg), icon: "person.2", color: .blue)
            }
            StatCard(title: "Max. Freunde", value: "\(analytics.network.maxFriends)", icon: "star.fill", color: .yellow)
        }

        if let avgHours = analytics.friendships.avgAcceptHours {
            let columns2 = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns2, spacing: 10) {
                StatCard(title: "Annahmezeit", value: String(format: "%.1fh", avgHours), icon: "clock.arrow.circlepath", color: .teal)
                StatCard(title: "Kommentare", value: "\(analytics.comments.totalComments)", icon: "bubble.left.fill", color: .blue)
            }
        }

        let columns3 = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns3, spacing: 10) {
            StatCard(title: "Kommentierer", value: "\(analytics.comments.uniqueCommenters)", icon: "person.bubble", color: .purple)
            if let avg = analytics.comments.avgPerLocation {
                StatCard(title: "Kommentare/Spot", value: String(format: "%.1f", avg), icon: "chart.bar", color: .green)
            }
        }
    }
}

// MARK: - Activity Feed

private struct ActivityFeedSection: View {
    let items: [ActivityItem]

    var body: some View {
        SectionHeader(title: "Letzte Aktivitaeten", icon: "clock.arrow.circlepath")

        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Divider().padding(.horizontal, 14)
                }
                HStack(spacing: 10) {
                    Image(systemName: iconFor(item.type))
                        .foregroundStyle(colorFor(item.type))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("@\(item.actor)")
                                .font(.subheadline)
                                .bold()
                            Text(labelFor(item.type))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let detail = item.detail {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Text(formatTime(item.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }

    private func iconFor(_ type: String) -> String {
        switch type {
        case "signup": return "person.badge.plus"
        case "spot": return "mappin.circle.fill"
        case "comment": return "bubble.left.fill"
        case "friendship": return "heart.fill"
        default: return "circle.fill"
        }
    }

    private func colorFor(_ type: String) -> Color {
        switch type {
        case "signup": return .green
        case "spot": return .orange
        case "comment": return .blue
        case "friendship": return .pink
        default: return .gray
        }
    }

    private func labelFor(_ type: String) -> String {
        switch type {
        case "signup": return "hat sich registriert"
        case "spot": return "neuer Spot"
        case "comment": return "hat kommentiert"
        case "friendship": return "Freundschaft"
        default: return ""
        }
    }

    private func formatTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else {
            return ""
        }
        let diff = Date().timeIntervalSince(date)
        if diff < 3600 { return "\(Int(diff / 60))m" }
        if diff < 86400 { return "\(Int(diff / 3600))h" }
        return "\(Int(diff / 86400))d"
    }
}

// MARK: - Reusable Components

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            Text(value)
                .font(.title3)
                .bold()
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }
}

private struct MiniBarChart: View {
    let data: [DayCount]
    var color: Color = .accentColor

    var body: some View {
        let maxVal = max(data.map(\.count).max() ?? 1, 1)
        let total = data.reduce(0) { $0 + $1.count }

        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(data) { point in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(point.count > 0 ? color : color.opacity(0.15))
                        .frame(height: max(2, CGFloat(point.count) / CGFloat(maxVal) * 50))
                }
            }
            .frame(height: 54)

            HStack {
                Text("Gesamt: \(total)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("letzte 30 Tage")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    AdminView()
}
