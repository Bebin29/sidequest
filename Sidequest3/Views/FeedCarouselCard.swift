//
//  FeedCarouselCard.swift
//  Sidequest
//
//  Apple Invitations-style carousel card for the Feed.
//

import SwiftUI

struct FeedCarouselCard: View {
    let location: Location
    var borderColor: Color = .indigo
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
                    .frame(height: geo.size.height * 0.45)
                    .allowsHitTesting(false)
                }
            }

            // Bottom content overlay
            bottomContent
        }
        // Category badge (top-left, subtle)
        .overlay(alignment: .topLeading) {
            TagBadge(
                label: location.category,
                color: categoryColor(for: location.category)
            )
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        // Warm colored border matching dominant/category color
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    borderColor.opacity(0.4),
                    lineWidth: 1.0
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
            // Dot indicator (visual hint for multiple images)
            if location.imageUrls.count > 1 {
                DotIndicator(count: location.imageUrls.count, current: 0)
                    .padding(.bottom, 14)
            }

            // Creator avatar — centered above title
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
                            lineWidth: 2.0
                        )
                }
                .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
                .padding(.bottom, 10)

            // Creator name
            Text(location.creatorDisplayName ?? location.creatorUsername ?? "Unbekannt")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
                .padding(.bottom, 12)

            // Location name — large, centered
            Text(location.name)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.40), radius: 8, y: 3)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Address — centered
            HStack(spacing: 5) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 12, weight: .semibold))
                Text(location.address)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(0.85))
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.bottom, 26)
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
