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
        VStack(spacing: 0) {
            // Top Bar — Creator Info
            HStack(spacing: 12) {
                if let urlString = location.creatorProfileImageUrl,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    } placeholder: {
                        avatarPlaceholder
                    }
                } else {
                    avatarPlaceholder
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(location.creatorDisplayName ?? location.creatorUsername ?? "Unbekannt")
                        .font(.subheadline.bold())
                    Text(formattedDate(location.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(location.category)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))

            // Image
            if let urlString = location.imageUrls.first,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 300)
                            .clipped()
                    case .failure:
                        imagePlaceholder
                    case .empty:
                        ProgressView()
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                imagePlaceholder
            }

            // Bottom Bar — Location Info + Actions
            VStack(alignment: .leading, spacing: 8) {
                Text(location.name)
                    .font(.headline)

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(location.address)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)

                if let description = location.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture { onTap() }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color(.systemGray4))
            .frame(width: 44, height: 44)
            .overlay(
                Text(String((location.creatorUsername ?? "?").prefix(1)).uppercased())
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            )
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 200)
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
