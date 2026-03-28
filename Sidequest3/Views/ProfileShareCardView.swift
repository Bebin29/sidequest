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
    private let centerSafeRadius: CGFloat = 100 // Radius um Ring Code + Name, keine Spots hier

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

            // Ring + Locations
            ZStack {
                // Ring Code in der Mitte
                VStack(spacing: 8) {
                    RingCodeView(
                        code: user.ringCode ?? String(repeating: "0", count: 72),
                        profileImage: profileImage,
                        initial: String(user.displayName.prefix(1)).uppercased(),
                        size: 130
                    )

                    VStack(spacing: 2) {
                        Text(user.displayName)
                            .font(.title3.bold())
                            .foregroundStyle(.white)

                        Text("@\(user.username)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

             
                // Locations nur oben (Dreiviertelkreis)
                /*GeometryReader { geo in
                    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    let ringRadius: CGFloat = 65      // Radius des Ring Codes
                    let spotRadius: CGFloat = 25      // Radius eines Spots
                    let minDistance = ringRadius + spotRadius + 8
                    let maxDistance: CGFloat = min(geo.size.width, geo.size.height)/2 - spotRadius - 8

                    let maxSpots = min(locations.count, 8)
                    
                    // Dreiviertelkreis von -150° bis -30° (oben links bis oben rechts)
                    let startAngle = -150.0
                    let endAngle = -30.0
                    let angleStep = (endAngle - startAngle) / Double(max(maxSpots - 1, 1))
                    let baseAngles = (0..<maxSpots).map { startAngle + Double($0) * angleStep }

                    ForEach(Array(locations.prefix(maxSpots).enumerated()), id: \.offset) { index, location in
                        let angleDeg = baseAngles[index] + Double.random(in: -5...5) // kleine Abweichung
                        let angle = angleDeg * .pi / 180
                        let radius = CGFloat.random(in: minDistance...maxDistance)

                        let x = cos(angle) * radius
                        let y = sin(angle) * radius

                        SpotCircle(location: location)
                            .frame(width: spotRadius * 2, height: spotRadius * 2)
                            .position(x: center.x + x,
                                      y: center.y + y)
                    }
                }
                .frame(width: cardWidth, height: cardHeight)*/
                 }
            .frame(width: cardWidth, height: cardHeight)

            // Branding unten
            VStack {
                Spacer()
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
