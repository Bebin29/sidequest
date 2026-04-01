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
    var cardWidth: CGFloat = 360
    var cardHeight: CGFloat = 520
    var body: some View {
        ZStack {
            // Hintergrund
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.17, blue: 0.45),
                            Color(red: 0.12, green: 0.10, blue: 0.30)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: cardWidth, height: cardHeight)

            VStack(spacing: 12) {
                if let profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(String(user.displayName.prefix(1)).uppercased())
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(.white)
                        )
                }

                VStack(spacing: 2) {
                    Text(user.displayName)
                        .font(.title3.bold())
                        .foregroundStyle(Theme.textPrimary)

                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: cardWidth, height: cardHeight)

            // Branding unten
            VStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "map.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                    Text("Sidequest")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.bottom, 20)
            }
            .frame(width: cardWidth, height: cardHeight, alignment: .bottom)
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

// MARK: - Spot Circle

private struct SpotCircle: View {
    let location: Location

    var body: some View {
        Group {
            if let urlString = location.imageUrls.first,
               let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.5))
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
        .shadow(radius: 3)
    }
}

// MARK: - Share Card Screen

struct ProfileShareCardView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss

    @State private var renderedImage: UIImage?
    @State private var profileImage: UIImage?
    @State private var locations: [Location] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                GeometryReader { geo in
                    let width = min(geo.size.width - 48, 360)
                    let height = width * (520 / 360)

                VStack(spacing: 28) {
                    Spacer()

                    ProfileShareCardContent(
                        user: user,
                        profileImage: profileImage,
                        locations: locations,
                        cardWidth: width,
                        cardHeight: height
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
                                .background(Theme.accent)
                                .foregroundStyle(Theme.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.small))
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
                                .background(Theme.imagePlaceholder)
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.small))
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                } // GeometryReader
            }
            .navigationTitle("Profil teilen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") { dismiss() }
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
            locations = Array(fetched.prefix(8)) // max 8 Spots
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
        guard let image = renderedImage else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.keyWindow?.rootViewController else { return }
        var topController = root
        while let presented = topController.presentedViewController {
            topController = presented
        }
        topController.present(activityVC, animated: true)
    }
}

