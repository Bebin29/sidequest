//
//  Feed.swift
//  Sidequest
//

import SwiftUI

struct Feed: View {
    var userId: UUID?
    var currentUserId: UUID?

    @State private var viewModel = FeedViewModel()
    @State private var selectedLocation: Location?

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading && viewModel.locations.isEmpty {
                    ProgressView()
                        .padding(.top, 60)
                } else if viewModel.locations.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.locations) { location in
                            FeedCard(location: location) {
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
}

// MARK: - Feed Card

struct FeedCard: View {
    let location: Location
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Creator Bar — clean, no background
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
                            ForEach(location.imageUrls, id: \.self) { urlString in
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
                } else {
                    imagePlaceholder
                }

                // Gradient overlay with name + category
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(location.name)
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    HStack(spacing: 8) {
                        Text(location.category)
                            .font(.caption.weight(.semibold))
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

            // Description + Actions
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

                Spacer()

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
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture { onTap() }
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

#Preview {
    let vm = AuthViewModel()
    Home(authViewModel: vm)
}
