import SwiftUI

// MARK: - Models

struct Invitation: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let date: String
    let location: String
    let host: String
    let tag: String
    let tagColor: Color
}

// MARK: - Sample Data

extension Invitation {
    static let samples: [Invitation] = [
        Invitation(imageName: "IMGSTART01", title: "Sommernacht am See", date: "Sa, 12. Jul · 20:00 Uhr", location: "Strandbad Wannsee, Berlin", host: "Von Jonas & Mia", tag: "Party", tagColor: .purple),
        Invitation(imageName: "IMGSTART02", title: "Hochzeit Müller", date: "Fr, 18. Jul · 14:00 Uhr", location: "Schloss Neuschwanstein", host: "Von Familie Müller", tag: "Hochzeit", tagColor: .pink),
        Invitation(imageName: "IMGSTART03", title: "Geburtstag 30!", date: "Sa, 26. Jul · 19:00 Uhr", location: "Rooftop Bar, Hamburg", host: "Von Lena Bauer", tag: "Geburtstag", tagColor: .orange),
        Invitation(imageName: "IMGSTART04", title: "BBQ & Chill", date: "So, 3. Aug · 14:00 Uhr", location: "Stadtpark München", host: "Von Tim Krause", tag: "Grillen", tagColor: .green),
        Invitation(imageName: "IMGSTART05", title: "Galerie Opening", date: "Do, 7. Aug · 18:30 Uhr", location: "Galerie am Ku'damm", host: "Von Sophia Art", tag: "Kunst", tagColor: .cyan),
        Invitation(imageName: "IMGSTART06", title: "Wine & Dine", date: "Fr, 15. Aug · 19:00 Uhr", location: "Vinothek Schumann, Köln", host: "Von Markus Wein", tag: "Dinner", tagColor: .red),
        Invitation(imageName: "IMGSTART07", title: "Yoga Retreat", date: "Mo, 18. Aug · 08:00 Uhr", location: "Schwarzwald Lodge", host: "Von Clara Zen", tag: "Wellness", tagColor: .teal),
        Invitation(imageName: "IMGSTART08", title: "Startup Pitch Night", date: "Mi, 20. Aug · 18:00 Uhr", location: "Factory Berlin", host: "Von TechHub Berlin", tag: "Business", tagColor: .blue),
        Invitation(imageName: "IMGSTART09", title: "Herbstfest", date: "Sa, 27. Sep · 15:00 Uhr", location: "Marktplatz Heidelberg", host: "Von Stadt Heidelberg", tag: "Festival", tagColor: .yellow),
    ]
}

// MARK: - Liquid Glass Modifier (iOS 26 / visionOS style)

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 28
    var opacity: Double = 0.18

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.35),
                                        Color.white.opacity(0.08),
                                        Color.white.opacity(0.20)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.7),
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    }
                    .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 28) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Tag Pill

struct TagPill: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .tracking(0.4)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.gradient)
                    .shadow(color: color.opacity(0.5), radius: 6, y: 3)
            )
    }
}

// MARK: - Invitation Card

struct InvitationCard: View {
    let invitation: Invitation
    var dragOffset: CGSize = .zero
    var rotation: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .bottom) {

                // Background image
                Image(invitation.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()

                // Gradient overlay for readability
                LinearGradient(
                    colors: [
                        .clear,
                        .clear,
                        .black.opacity(0.2),
                        .black.opacity(0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Tag top-right
                VStack {
                    HStack {
                        Spacer()
                        TagPill(label: invitation.tag, color: invitation.tagColor)
                            .padding(.top, 20)
                            .padding(.trailing, 20)
                    }
                    Spacer()
                }

                // Bottom info card (Liquid Glass)
                VStack(alignment: .leading, spacing: 0) {
                    // Title
                    Text(invitation.title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                    Spacer().frame(height: 10)

                    // Date row
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                        Text(invitation.date)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    Spacer().frame(height: 6)

                    // Location row
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                        Text(invitation.location)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                    }

                    Spacer().frame(height: 6)

                    // Host row
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                        Text(invitation.host)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    Spacer().frame(height: 18)

                    // Action buttons
                    HStack(spacing: 12) {
                        // Decline
                        Label("Ablehnen", systemImage: "xmark")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .liquidGlass(cornerRadius: 18)

                        // Accept
                        Label("Zusagen", systemImage: "checkmark")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [invitation.tagColor, invitation.tagColor.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                                    }
                                    .shadow(color: invitation.tagColor.opacity(0.5), radius: 8, y: 4)
                            }
                    }
                }
                .padding(22)
                .liquidGlass(cornerRadius: 28)
                .padding(.horizontal, 14)
                .padding(.bottom, 22)

                // Swipe direction overlays
                swipeOverlay
            }
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 14)
        }
    }

    // MARK: Swipe hint overlay
    @ViewBuilder
    private var swipeOverlay: some View {
        let threshold: CGFloat = 40

        ZStack {
            // Accept overlay (swipe right)
            if dragOffset.width > threshold {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.green.opacity(min(Double(dragOffset.width - threshold) / 100.0, 0.55)))
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 54, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .green.opacity(0.6), radius: 12, y: 4)
                            .opacity(min(Double(dragOffset.width - threshold) / 80.0, 1.0))
                            .scaleEffect(min(0.6 + Double(dragOffset.width - threshold) / 200.0, 1.1))
                        Spacer()
                    }
                    .padding(.leading, 32)
                    Spacer()
                }
            }

            // Decline overlay (swipe left)
            if dragOffset.width < -threshold {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.red.opacity(min(Double(-dragOffset.width - threshold) / 100.0, 0.55)))
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 54, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .red.opacity(0.6), radius: 12, y: 4)
                            .opacity(min(Double(-dragOffset.width - threshold) / 80.0, 1.0))
                            .scaleEffect(min(0.6 + Double(-dragOffset.width - threshold) / 200.0, 1.1))
                        Spacer().frame(width: 32)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Swiper Stack

struct InvitationSwiper: View {
    @State private var invitations: [Invitation] = Invitation.samples
    @State private var topCardOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var lastSwipeDirection: SwipeDirection? = nil
    @State private var removedCount = 0

    private let haptic = UIImpactFeedbackGenerator(style: .medium)
    private let notificationHaptic = UINotificationFeedbackGenerator()
    private let selectionHaptic = UISelectionFeedbackGenerator()

    enum SwipeDirection { case left, right }

    private var swipeThreshold: CGFloat { 100 }

    var body: some View {
        ZStack {
            // Background mesh gradient
            backgroundGradient

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 12)

                Spacer().frame(height: 20)

                // Card stack
                ZStack {
                    if invitations.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(Array(invitations.prefix(3).enumerated().reversed()), id: \.element.id) { index, invitation in
                            let isTop = index == 0
                            InvitationCard(
                                invitation: invitation,
                                dragOffset: isTop ? topCardOffset : .zero,
                                rotation: isTop ? cardRotation : 0
                            )
                            .frame(
                                width: cardWidth(index: index),
                                height: cardHeight(index: index)
                            )
                            .offset(y: cardYOffset(index: index))
                            .scaleEffect(cardScale(index: index))
                            .offset(x: isTop ? topCardOffset.width : 0,
                                    y: isTop ? topCardOffset.height * 0.15 : 0)
                            .rotationEffect(.degrees(isTop ? cardRotation : 0))
                            .zIndex(Double(3 - index))
                            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: topCardOffset)
                            .gesture(isTop ? dragGesture : nil)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.58)

                Spacer()

                // Bottom action bar
                if !invitations.isEmpty {
                    actionBar
                        .padding(.bottom, 36)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                topCardOffset = value.translation
                isDragging = true

                // Haptic tick at threshold
                if abs(value.translation.width) > swipeThreshold {
                    if lastSwipeDirection == nil {
                        selectionHaptic.selectionChanged()
                        lastSwipeDirection = value.translation.width > 0 ? .right : .left
                    }
                } else {
                    lastSwipeDirection = nil
                }
            }
            .onEnded { value in
                isDragging = false
                lastSwipeDirection = nil

                if value.translation.width > swipeThreshold {
                    acceptCard()
                } else if value.translation.width < -swipeThreshold {
                    declineCard()
                } else {
                    // Snap back
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        topCardOffset = .zero
                    }
                    haptic.impactOccurred(intensity: 0.4)
                }
            }
    }

    // MARK: - Card Actions

    private func acceptCard() {
        notificationHaptic.notificationOccurred(.success)
        flyCard(toRight: true)
    }

    private func declineCard() {
        notificationHaptic.notificationOccurred(.warning)
        flyCard(toRight: false)
    }

    private func flyCard(toRight: Bool) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
            topCardOffset = CGSize(
                width: toRight ? 800 : -800,
                height: topCardOffset.height
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            if !invitations.isEmpty {
                invitations.removeFirst()
                removedCount += 1
            }
            withAnimation(.none) {
                topCardOffset = .zero
            }
        }
    }

    // MARK: - Card Layout Helpers

    private var cardRotation: Double {
        let factor = topCardOffset.width / 22
        return min(max(factor, -18), 18)
    }

    private let screenWidth = UIScreen.main.bounds.width

    private func cardWidth(index: Int) -> CGFloat {
        let base = screenWidth - 44
        return base - CGFloat(index) * 10
    }

    private func cardHeight(index: Int) -> CGFloat {
        let base: CGFloat = UIScreen.main.bounds.height * 0.56
        return base - CGFloat(index) * 14
    }

    private func cardYOffset(index: Int) -> CGFloat {
        return CGFloat(index) * 14
    }

    private func cardScale(index: Int) -> CGFloat {
        return 1.0 - CGFloat(index) * 0.035
    }

    // MARK: - Sub Views

    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.05, blue: 0.12),
                    Color(red: 0.10, green: 0.08, blue: 0.22),
                    Color(red: 0.08, green: 0.12, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Ambient blobs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.35), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                )
                .frame(width: 380)
                .offset(x: -80, y: -200)
                .blur(radius: 60)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.28), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 340)
                .offset(x: 140, y: 300)
                .blur(radius: 55)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.pink.opacity(0.2), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 300)
                .offset(x: -60, y: 500)
                .blur(radius: 50)
        }
        .ignoresSafeArea()
    }

    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Einladungen")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(invitations.count) offen · \(removedCount) beantwortet")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            // Progress pills
            HStack(spacing: 5) {
                ForEach(0..<min(invitations.count, 5), id: \.self) { i in
                    Capsule()
                        .fill(i == 0 ? Color.white : Color.white.opacity(0.25))
                        .frame(width: i == 0 ? 20 : 6, height: 6)
                        .animation(.spring(response: 0.3), value: invitations.count)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var actionBar: some View {
        HStack(spacing: 28) {
            // Decline button
            Button { declineCard() } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 62, height: 62)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.4), Color.red.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.red.opacity(0.9))
                }
            }
            .disabled(invitations.isEmpty)

            // Superlike / Info button
            Button { } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red:0.4,green:0.3,blue:1.0), Color(red:0.7,green:0.3,blue:1.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 78, height: 78)
                        .shadow(color: Color.purple.opacity(0.55), radius: 16, y: 8)
                    Image(systemName: "star.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .disabled(invitations.isEmpty)

            // Accept button
            Button { acceptCard() } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 62, height: 62)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.4), Color.green.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.green.opacity(0.9))
                }
            }
            .disabled(invitations.isEmpty)
        }
        .padding(.horizontal, 48)
    }

    private var emptyStateView: some View {
        VStack(spacing: 18) {
            Image(systemName: "envelope.open.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .purple.opacity(0.4), radius: 16, y: 8)

            Text("Alles erledigt!")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Du hast alle Einladungen\nbeantwortet.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(36)
        .liquidGlass(cornerRadius: 32)
        .padding(.horizontal, 36)
    }
}

// MARK: - Preview

#Preview {
    InvitationSwiper()
        .preferredColorScheme(.dark)
}
