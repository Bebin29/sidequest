//
//  FeedCarouselCard.swift
//  Sidequest
//
//  Apple Invitations-style carousel card for the Feed.
//

import SwiftUI

struct FeedCarouselCard: View {
    let location: Location
    var borderColor: Color = .accentColor
    var onTap: () -> Void
    var onImageLoaded: ((UIImage) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-bleed hero image behind everything
            Color.clear
                .overlay {
                    heroImage
                }
                .clipped()
                .backgroundExtensionIfAvailable()

            // Warm gradient + glass transition at bottom
            VStack(spacing: 0) {
                Spacer()

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: borderColor.opacity(0.3), location: 0.4),
                        .init(color: borderColor.opacity(0.6), location: 0.7),
                        .init(color: borderColor.opacity(0.8), location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)

                Rectangle()
                    .fill(borderColor.opacity(0.7))
                    .frame(height: 140)
            }

            // Glass blur overlay on the bottom portion
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 220)
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black.opacity(0.6), location: 0.2),
                                .init(color: .black, location: 0.45),
                                .init(color: .black, location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }
            .allowsHitTesting(false)

            // Bottom content (avatar, name, title, address)
            bottomContent

            // Category badge (top-left)
            VStack {
                HStack {
                    TagBadge(
                        label: location.category,
                        color: categoryColor(for: location.category)
                    )
                    Spacer()
                }
                .padding(16)
                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        // Warm colored border glow
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    borderColor.opacity(0.45),
                    lineWidth: 1.2
                )
        }
        .shadow(color: .black.opacity(0.35), radius: 32, y: 18)
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture { onTap() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(location.name), \(location.category), \(location.address)")
        .accessibilityHint("Tippe um Details zu sehen")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Bottom Content

    private var bottomContent: some View {
        VStack(spacing: 0) {
            // Creator avatar — centered, sits at transition zone
            creatorAvatar
                .frame(width: 38, height: 38)
                .overlay {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color.white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
                .padding(.bottom, 8)

            // Location name — large, centered
            Text(location.name)
                .font(.title).fontWeight(.bold).fontDesign(.rounded)
                .foregroundStyle(Theme.textPrimary)
                .shadow(color: .black.opacity(0.30), radius: 6, y: 2)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Address — centered
            HStack(spacing: 5) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption).fontWeight(.semibold)
                Text(location.address)
                    .font(.footnote).fontWeight(.medium).fontDesign(.rounded)
                    .lineLimit(2)
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.bottom, 22)
    }

    // MARK: - Hero Image

    @ViewBuilder
    private var heroImage: some View {
        if let firstUrl = location.imageUrls.first,
           let url = URL(string: firstUrl) {
            CachedAsyncImage(url: url, onLoad: { uiImage in
                onImageLoaded?(uiImage)
            }) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                imagePlaceholder
            }
        } else {
            imagePlaceholder
        }
    }

    // MARK: - Creator Avatar

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
            .fill(Theme.skeletonFillMedium)
            .overlay(
                Text(String((location.creatorUsername ?? "?").prefix(1)).uppercased())
                    .font(.caption2).fontWeight(.bold).fontDesign(.rounded)
                    .foregroundStyle(Theme.textSecondary)
            )
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Theme.skeletonFill)
            .overlay(
                Image(systemName: "photo")
                    .font(.largeTitle).fontWeight(.light)
                    .foregroundStyle(Theme.textTertiary)
            )
    }

    // MARK: - Helpers

    private func categoryColor(for category: String) -> Color {
        LocationCategory.color(for: category)
    }
}
