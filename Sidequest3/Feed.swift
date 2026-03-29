//
//  Feed.swift
//  Sidequest
//

import SwiftUI
import CoreLocation

struct Feed: View {
    var userId: UUID?
    var currentUserId: UUID?
    var onShowOnMap: ((Location) -> Void)?

    @State private var viewModel = FeedViewModel()
    @State private var selectedLocation: Location?
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                // Custom header (wie InvitationSwiper)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Feed")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if !viewModel.locations.isEmpty {
                        Text("\(viewModel.locations.count) Spots")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.48))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26)
                .padding(.top, 8)
                .padding(.bottom, 4)

                if viewModel.isLoading && viewModel.locations.isEmpty {
                    skeletonList
                } else if let error = viewModel.errorMessage, viewModel.locations.isEmpty {
                    errorState(message: error)
                } else if viewModel.locations.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 24) {
                        ForEach(viewModel.locations) { location in
                            FeedCard(
                                location: location,
                                userLocation: locationManager.lastLocation,
                                onShowOnMap: { onShowOnMap?(location) }
                            ) {
                                selectedLocation = location
                            }
                            .padding(.horizontal, 20)
                            .onAppear {
                                if location.id == viewModel.locations.last?.id {
                                    guard let userId else { return }
                                    Task { await viewModel.loadMore(userId: userId) }
                                }
                            }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .tint(.white.opacity(0.4))
                                .padding()
                        }
                    }
                    .padding(.top, 8)
                }
                Spacer(minLength: 32)
            }
            .background {
                // Adaptiver dunkler Hintergrund mit Ambient-Gradient
                ZStack {
                    Color(red: 0.06, green: 0.05, blue: 0.12)

                    RadialGradient(
                        colors: [Color.indigo.opacity(0.15), .clear],
                        center: .top,
                        startRadius: 0,
                        endRadius: 500
                    )
                }
                .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                guard let userId else { return }
                await viewModel.loadFeed(userId: userId)
            }
            .refreshable {
                guard let userId else { return }
                await viewModel.loadFeed(userId: userId)
            }
            .sheet(item: $selectedLocation) { location in
                NavigationStack {
                    LocationDetailView(location: location, currentUserId: currentUserId)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Fertig") { selectedLocation = nil }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 44, weight: .light, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))

            VStack(spacing: 8) {
                Text("Noch nichts im Feed")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Füge Freunde hinzu, um ihre Spots zu sehen.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 100)
        .frame(maxWidth: .infinity)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 44, weight: .light, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))

            VStack(spacing: 8) {
                Text("Laden fehlgeschlagen")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                guard let userId else { return }
                Task { await viewModel.loadFeed(userId: userId) }
            } label: {
                Text("Erneut versuchen")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 11)
                    .liquidGlassPill()
            }
        }
        .padding(.top, 100)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Skeleton Loading

    private var skeletonList: some View {
        LazyVStack(spacing: 24) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonCard()
                    .padding(.horizontal, 20)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Skeleton Card

struct SkeletonCard: View {
    @State private var shimmer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Creator bar skeleton
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 120, height: 12)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 60, height: 10)
                }

                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 12)

            // Image skeleton (4:5 Ratio)
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .aspectRatio(4.0 / 5.0, contentMode: .fit)

            // Text skeleton
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 180, height: 12)
            }
            .padding(.horizontal, 6)
            .padding(.top, 12)
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.32), radius: 24, y: 12)
        .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
        .opacity(shimmer ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: shimmer)
        .onAppear { shimmer = true }
    }
}

// MARK: - Feed Card

struct FeedCard: View {
    let location: Location
    var userLocation: CLLocation?
    var onShowOnMap: (() -> Void)?
    var onTap: () -> Void

    @State private var currentPage: Int? = 0
    @State private var lastHapticPage: Int? = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Creator Bar mit Avatar-Ring
            HStack(spacing: 10) {
                creatorAvatar
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.indigo, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(location.creatorDisplayName ?? location.creatorUsername ?? "Unbekannt")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(formattedDate(location.createdAt))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 12)

            // Bild-Bereich mit Bottom-Gradient (wie Apple Invitations)
            ZStack(alignment: .bottom) {
                // Bilder
                if !location.imageUrls.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 0) {
                            ForEach(Array(location.imageUrls.enumerated()), id: \.offset) { _, urlString in
                                CachedAsyncImage(url: URL(string: urlString)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Color.white.opacity(0.05)
                                        .overlay(ProgressView().tint(.white.opacity(0.3)))
                                }
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .aspectRatio(4.0 / 5.0, contentMode: .fill)
                                .clipped()
                                .containerRelativeFrame(.horizontal)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $currentPage)
                    .onChange(of: currentPage) { oldValue, newValue in
                        guard let old = oldValue, let new = newValue, old != new else { return }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        lastHapticPage = new
                    }
                } else {
                    imagePlaceholder
                }

                // Bottom Gradient (wie InvitationCard)
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black.opacity(0.0), location: 0.25),
                        .init(color: .black.opacity(0.45), location: 0.50),
                        .init(color: .black.opacity(0.82), location: 0.78),
                        .init(color: .black.opacity(0.92), location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                // Info-Overlay unten im Bild
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    // Location Name
                    Text(location.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.30), radius: 6, y: 3)

                    Spacer().frame(height: 8)

                    // Category TagBadge + Adresse
                    HStack(spacing: 8) {
                        TagBadge(
                            label: location.category,
                            color: categoryColor(for: location.category)
                        )

                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 10, weight: .semibold))
                            Text(location.address)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white.opacity(0.85))
                    }

                    // Beschreibung (im Overlay, nicht außerhalb)
                    if let description = location.description, !description.isEmpty {
                        Spacer().frame(height: 8)
                        Text(description)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.70))
                            .lineLimit(2)
                    }

                    Spacer().frame(height: 14)

                    // Dots (DotIndicator wiederverwendet)
                    if location.imageUrls.count > 1 {
                        HStack {
                            Spacer()
                            DotIndicator(count: location.imageUrls.count, current: currentPage ?? 0)
                            Spacer()
                        }
                        Spacer().frame(height: 10)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
            .aspectRatio(4.0 / 5.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .onTapGesture { onTap() }

            // Action Row mit Liquid Glass Pill
            HStack(spacing: 12) {
                Button { onShowOnMap?() } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "map")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Karte")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .liquidGlassPill()
                }

                Spacer()

                if let distance = formattedDistance {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text(distance)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.50))
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 12)
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        // Subtle glass border
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.04),
                            Color.white.opacity(0.10),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
        // Double shadow (wie InvitationSwiper)
        .shadow(color: .black.opacity(0.32), radius: 24, y: 12)
        .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var creatorAvatar: some View {
        if let urlString = location.creatorProfileImageUrl,
           let url = URL(string: urlString) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } placeholder: {
                avatarPlaceholder
            }
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.white.opacity(0.10))
            .overlay(
                Text(String((location.creatorUsername ?? "?").prefix(1)).uppercased())
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            )
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .aspectRatio(4.0 / 5.0, contentMode: .fill)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.2))
            )
    }

    // MARK: - Helpers

    private var formattedDistance: String? {
        guard let userLocation else { return nil }
        let spotLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let meters = userLocation.distance(from: spotLocation)

        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            let km = meters / 1000
            return String(format: "%.1f km", km)
        }
    }

    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Restaurant": return .orange
        case "Café": return .brown
        case "Bar": return .purple
        case "Club": return .pink
        case "Bäckerei": return .yellow
        case "Fast Food": return .red
        case "Eisdiele": return .cyan
        case "Park": return .green
        case "Museum": return .blue
        case "Shopping": return .pink
        case "Aussichtspunkt": return .teal
        case "Strand": return .cyan
        default: return .indigo
        }
    }

    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.unitsStyle = .short
        return formatter
    }()

    private func formattedDate(_ dateString: String) -> String {
        guard let date = Self.isoFormatter.date(from: String(dateString.prefix(19))) else {
            return ""
        }
        return Self.relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}
