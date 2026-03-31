//
//  FeedCarouselCard.swift
//  Sidequest
//
//  Apple Invitations-style carousel card for the Feed.
//

import SwiftUI

struct FeedCarouselCard: View {
    let location: Location
    var onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                // Full-bleed hero image behind everything
                Color.clear
                    .overlay {
                        heroImage
                    }
                    .clipped()
                    .backgroundExtensionIfAvailable()

                // Glass overlay on the bottom portion
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .frame(height: 220)
                        .glassEffect(.clear, in: .rect)
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
            .shadow(color: .black.opacity(0.35), radius: 32, y: 18)
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
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
            CachedAsyncImage(url: url) { image in
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

    private var creatorAvatar: some View {
        AvatarView(url: location.creatorProfileImageUrl, fallbackInitial: location.creatorUsername, size: .small)
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
