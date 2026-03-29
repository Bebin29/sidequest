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
    var onImageLoaded: ((UIImage) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            // Hero image — Color.clear accepts proposed size,
            // overlay fills it, clipped prevents layout overflow
            Color.clear
                .overlay {
                    heroImage
                }
                .clipped()

            // Gradient ONLY on bottom portion for text readability
            // Uses GeometryReader to be proportional to card height
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black.opacity(0.20), location: 0.15),
                            .init(color: .black.opacity(0.60), location: 0.45),
                            .init(color: .black.opacity(0.85), location: 0.75),
                            .init(color: .black.opacity(0.95), location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.40)
                    .allowsHitTesting(false)
                }
            }

            // Bottom content overlay
            bottomContent
        }
        // Creator badge (top-left)
        .overlay(alignment: .topLeading) {
            creatorBadge
                .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        // Subtle glass border
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.20),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
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
        VStack(alignment: .leading, spacing: 0) {
            // Dot indicator (visual hint for multiple images)
            if location.imageUrls.count > 1 {
                HStack {
                    Spacer()
                    DotIndicator(count: location.imageUrls.count, current: 0)
                    Spacer()
                }
                .padding(.bottom, 14)
            }

            // Category badge
            TagBadge(
                label: location.category,
                color: categoryColor(for: location.category)
            )
            .padding(.bottom, 10)

            // Location name
            Text(location.name)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.40), radius: 8, y: 3)
                .lineLimit(2)

            // Address
            HStack(spacing: 5) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 11, weight: .semibold))
                Text(location.address)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(0.85))
            .padding(.top, 8)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 24)
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

    // MARK: - Creator Badge

    private var creatorBadge: some View {
        HStack(spacing: 7) {
            creatorAvatar
                .frame(width: 26, height: 26)
                .overlay {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.indigo, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }

            Text(location.creatorDisplayName ?? location.creatorUsername ?? "Unbekannt")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.leading, 5)
        .padding(.trailing, 12)
        .padding(.vertical, 5)
        .liquidGlassPill()
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
            .fill(Color.white.opacity(0.10))
            .overlay(
                Text(String((location.creatorUsername ?? "?").prefix(1)).uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            )
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.white.opacity(0.2))
            )
    }

    // MARK: - Helpers

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
}
