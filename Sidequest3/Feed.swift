//
//  Feed.swift
//  Sidequest
//

import SwiftUI
import CoreLocation
import MapKit

struct Feed: View {
    var userId: UUID?
    var currentUserId: UUID?

    @State private var viewModel = FeedViewModel()
    @State private var selectedLocation: Location?
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading && viewModel.locations.isEmpty {
                    skeletonList
                } else if let error = viewModel.errorMessage, viewModel.locations.isEmpty {
                    errorState(message: error)
                } else if viewModel.locations.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.locations) { location in
                            FeedCard(
                                location: location,
                                userLocation: locationManager.lastLocation
                            ) {
                                selectedLocation = location
                            }
                            .padding(.horizontal)
                            .onAppear {
                                if location.id == viewModel.locations.last?.id {
                                    guard let userId else { return }
                                    Task { await viewModel.loadMore(userId: userId) }
                                }
                            }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Feed")
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
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("Noch nichts im Feed")
                .font(.title3.bold())

            Text("Füge Freunde hinzu, um ihre Spots zu sehen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 80)
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("Laden fehlgeschlagen")
                .font(.title3.bold())

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                guard let userId else { return }
                Task { await viewModel.loadFeed(userId: userId) }
            } label: {
                Label("Erneut versuchen", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.indigo)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 80)
    }

    // MARK: - Skeleton Loading

    private var skeletonList: some View {
        LazyVStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonCard()
                    .padding(.horizontal)
            }
        }
        .padding(.top)
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
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 120, height: 12)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 60, height: 10)
                }

                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 10)

            // Image skeleton
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
                .aspectRatio(1, contentMode: .fit)

            // Text skeleton
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 180, height: 12)
            }
            .padding(.horizontal, 4)
            .padding(.top, 10)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .opacity(shimmer ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: shimmer)
        .onAppear { shimmer = true }
    }
}

// MARK: - Feed Card

struct FeedCard: View {
    let location: Location
    var userLocation: CLLocation?
    var onTap: () -> Void

    @State private var currentPage: Int? = 0
    @State private var showMap = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Creator Bar
            HStack(spacing: 10) {
                creatorAvatar
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 1) {
                    Text(location.creatorDisplayName ?? location.creatorUsername ?? "Unbekannt")
                        .font(.subheadline.bold())
                    Text(formattedDate(location.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 10)

            // Image carousel with gradient overlay
            ZStack(alignment: .bottomLeading) {
                if !location.imageUrls.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 0) {
                            ForEach(Array(location.imageUrls.enumerated()), id: \.offset) { index, urlString in
                                CachedAsyncImage(url: URL(string: urlString)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Color(.systemGray6)
                                        .overlay(ProgressView())
                                }
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                                .containerRelativeFrame(.horizontal)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $currentPage)
                } else {
                    imagePlaceholder
                }

                // Page indicator dots
                if location.imageUrls.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<location.imageUrls.count, id: \.self) { index in
                            Circle()
                                .fill(index == (currentPage ?? 0) ? .white : .white.opacity(0.4))
                                .frame(width: 7, height: 7)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.3))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 72)
                }

                // Gradient overlay with name + category
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 6) {
                    Text(location.name)
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: categoryIcon(for: location.category))
                                .font(.caption2)
                            Text(location.category)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())

                        HStack(spacing: 3) {
                            Image(systemName: "mappin")
                                .font(.caption2)
                            Text(location.address)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .opacity(0.8)
                    }
                    .foregroundStyle(.white)
                }
                .padding()
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Description
            if let description = location.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal, 4)
                    .padding(.top, 10)
            }

            // Action row
            HStack(spacing: 16) {
                Button { onTap() } label: {
                    Label("Details", systemImage: "arrow.right.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.indigo)
                }

                Button { showMap = true } label: {
                    Label("Karte", systemImage: "map")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.indigo)
                }

                Spacer()

                if let distance = formattedDistance {
                    HStack(spacing: 3) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(distance)
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                }

                if location.imageUrls.count > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.caption2)
                        Text("\(location.imageUrls.count) Fotos")
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 10)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .sheet(isPresented: $showMap) {
            SpotMapSheet(location: location)
                .presentationDetents([.medium])
        }
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
            .fill(Color(.systemGray4))
            .overlay(
                Text(String((location.creatorUsername ?? "?").prefix(1)).uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            )
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .aspectRatio(1, contentMode: .fill)
            .overlay(
                Image(systemName: "photo")
                    .font(.title)
                    .foregroundStyle(.tertiary)
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

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Restaurant": return "fork.knife"
        case "Café": return "cup.and.saucer.fill"
        case "Bar": return "wineglass.fill"
        case "Club": return "music.note.house.fill"
        case "Bäckerei": return "birthday.cake.fill"
        case "Fast Food": return "takeoutbag.and.cup.and.straw.fill"
        case "Eisdiele": return "snowflake"
        case "Park": return "leaf.fill"
        case "Museum": return "building.columns.fill"
        case "Shopping": return "bag.fill"
        case "Aussichtspunkt": return "binoculars.fill"
        case "Strand": return "beach.umbrella.fill"
        default: return "mappin.circle.fill"
        }
    }

    private func formattedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "de_DE")
        guard let date = formatter.date(from: String(dateString.prefix(19))) else {
            return ""
        }
        let relative = RelativeDateTimeFormatter()
        relative.locale = Locale(identifier: "de_DE")
        relative.unitsStyle = .short
        return relative.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Spot Map Sheet

struct SpotMapSheet: View {
    let location: Location

    @State private var position: MapCameraPosition

    init(location: Location) {
        self.location = location
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        _position = State(initialValue: .region(region))
    }

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                Marker(location.name, coordinate: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                ))
                .tint(.indigo)
            }
            .navigationTitle(location.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        openInMaps()
                    } label: {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.indigo)
                    }
                }
            }
        }
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        ))
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

#Preview {
    let vm = AuthViewModel()
    Home(authViewModel: vm)
}
