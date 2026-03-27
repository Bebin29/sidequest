//
//  ProfileShareCardView.swift
//  Sidequest
//

import SwiftUI

// MARK: - Share Card Layout

struct ProfileShareCardContent: View {
    let user: User
    let profileImage: UIImage?
    let locations: [Location]

    private let cardWidth: CGFloat = 360
    private let cardHeight: CGFloat = 520

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Spacer().frame(height: 24)

                // Ring Code + Profile Image
                RingCodeView(
                    code: user.ringCode ?? String(repeating: "0", count: 72),
                    profileImage: profileImage,
                    initial: String(user.displayName.prefix(1)).uppercased(),
                    size: 130
                )

                // Name + Username
                VStack(spacing: 4) {
                    Text(user.displayName)
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                // Spots
                if !locations.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(locations.prefix(3)) { location in
                            SpotMiniCard(location: location)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }

                Spacer()

                // Branding
                HStack(spacing: 6) {
                    Image(systemName: "map.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Sidequest")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.bottom, 20)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.17, blue: 0.45),
                    Color(red: 0.12, green: 0.10, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Spot Mini Card

private struct SpotMiniCard: View {
    let location: Location

    var body: some View {
        VStack(spacing: 0) {
            // Image
            if let urlString = location.imageUrls.first,
               let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.white.opacity(0.1)
                }
                .frame(height: 70)
                .clipped()
            } else {
                Color.white.opacity(0.1)
                    .frame(height: 70)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                    )
            }

            // Name + Category
            VStack(spacing: 2) {
                Text(location.name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(location.category)
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Share Card Screen

struct ProfileShareCardView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss

    @State private var renderedImage: UIImage?
    @State private var showShareSheet = false
    @State private var profileImage: UIImage?
    @State private var locations: [Location] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    ProfileShareCardContent(
                        user: user,
                        profileImage: profileImage,
                        locations: locations
                    )
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)

                    // Action buttons
                    HStack(spacing: 12) {
                        Button {
                            renderAndShare()
                        } label: {
                            Label("Teilen", systemImage: "square.and.arrow.up")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemIndigo))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            renderImage()
                            if let image = renderedImage {
                                UIPasteboard.general.image = image
                            }
                        } label: {
                            Label("Kopieren", systemImage: "doc.on.doc")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray5))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
            }
            .navigationTitle("Profil teilen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = renderedImage {
                    ShareSheetView(items: [image])
                }
            }
            .task {
                await loadProfileImage()
                await loadLocations()
            }
        }
    }

    private func loadProfileImage() async {
        guard let urlString = user.profileImageUrl,
              let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            profileImage = UIImage(data: data)
        } catch {}
    }

    private func loadLocations() async {
        do {
            let fetched = try await LocationService().fetchLocations(userId: user.id)
            locations = Array(fetched.prefix(3))
        } catch {}
    }

    @MainActor
    private func renderImage() {
        let content = ProfileShareCardContent(
            user: user,
            profileImage: profileImage,
            locations: locations
        )
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        renderedImage = renderer.uiImage
    }

    @MainActor
    private func renderAndShare() {
        renderImage()
        if renderedImage != nil {
            showShareSheet = true
        }
    }
}

// MARK: - UIKit Share Sheet wrapper

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
