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
    /// Dominant colors extracted/approximated per image for the background gradient
    let bgColors: [Color]
}

extension Invitation {
    static let samples: [Invitation] = [
        Invitation(
            imageName: "IMGSTART01", title: "Sommernacht am See",
            date: "Sa, 12. Jul · 20:00 Uhr", location: "Strandbad Wannsee, Berlin",
            host: "Von Jonas & Mia", tag: "Party", tagColor: .purple,
            bgColors: [Color(red:0.10,green:0.05,blue:0.28), Color(red:0.05,green:0.10,blue:0.35)]
        ),
        Invitation(
            imageName: "IMGSTART02", title: "Hochzeit Müller",
            date: "Fr, 18. Jul · 14:00 Uhr", location: "Schloss Neuschwanstein",
            host: "Von Familie Müller", tag: "Hochzeit", tagColor: .pink,
            bgColors: [Color(red:0.28,green:0.08,blue:0.18), Color(red:0.15,green:0.05,blue:0.22)]
        ),
        Invitation(
            imageName: "IMGSTART03", title: "Geburtstag 30!",
            date: "Sa, 26. Jul · 19:00 Uhr", location: "Rooftop Bar, Hamburg",
            host: "Von Lena Bauer", tag: "Geburtstag", tagColor: .orange,
            bgColors: [Color(red:0.30,green:0.12,blue:0.04), Color(red:0.18,green:0.08,blue:0.02)]
        ),
        Invitation(
            imageName: "IMGSTART04", title: "BBQ & Chill",
            date: "So, 3. Aug · 14:00 Uhr", location: "Stadtpark München",
            host: "Von Tim Krause", tag: "Grillen", tagColor: .green,
            bgColors: [Color(red:0.04,green:0.20,blue:0.08), Color(red:0.02,green:0.12,blue:0.06)]
        ),
        Invitation(
            imageName: "IMGSTART05", title: "Galerie Opening",
            date: "Do, 7. Aug · 18:30 Uhr", location: "Galerie am Ku'damm, Berlin",
            host: "Von Sophia Art", tag: "Kunst", tagColor: .cyan,
            bgColors: [Color(red:0.04,green:0.20,blue:0.28), Color(red:0.02,green:0.12,blue:0.20)]
        ),
        Invitation(
            imageName: "IMGSTART06", title: "Wine & Dine",
            date: "Fr, 15. Aug · 19:00 Uhr", location: "Vinothek Schumann, Köln",
            host: "Von Markus Wein", tag: "Dinner", tagColor: .red,
            bgColors: [Color(red:0.28,green:0.05,blue:0.05), Color(red:0.18,green:0.03,blue:0.06)]
        ),
        Invitation(
            imageName: "IMGSTART07", title: "Yoga Retreat",
            date: "Mo, 18. Aug · 08:00 Uhr", location: "Schwarzwald Lodge",
            host: "Von Clara Zen", tag: "Wellness", tagColor: .teal,
            bgColors: [Color(red:0.04,green:0.18,blue:0.18), Color(red:0.03,green:0.10,blue:0.14)]
        ),
        Invitation(
            imageName: "IMGSTART08", title: "Startup Pitch Night",
            date: "Mi, 20. Aug · 18:00 Uhr", location: "Factory Berlin",
            host: "Von TechHub Berlin", tag: "Business", tagColor: .blue,
            bgColors: [Color(red:0.05,green:0.08,blue:0.30), Color(red:0.03,green:0.05,blue:0.20)]
        ),
        Invitation(
            imageName: "IMGSTART09", title: "Herbstfest",
            date: "Sa, 27. Sep · 15:00 Uhr", location: "Marktplatz Heidelberg",
            host: "Von Stadt Heidelberg", tag: "Festival", tagColor: .yellow,
            bgColors: [Color(red:0.25,green:0.16,blue:0.03), Color(red:0.15,green:0.08,blue:0.02)]
        ),
    ]
}

// MARK: - Liquid Glass Edge Effect
//
// Applied DIRECTLY on the image: feathered frosted-glass vignette on all
// four edges that fades toward the centre — the image stays fully visible
// in the middle, while the perimeter gets a translucent glass shimmer.

struct LiquidGlassEdges: ViewModifier {
    var cornerRadius: CGFloat = 32
    /// Controls how far inward the frosted edge extends (0–1 relative to shortest side)
    var edgeFade: CGFloat = 0.18

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                // Frosted material + specular, masked so only the perimeter shows
                ZStack {
                    // Base material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    // Specular gradient (light source: top-left)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.55), location: 0.00),
                                    .init(color: Color.white.opacity(0.20), location: 0.25),
                                    .init(color: Color.white.opacity(0.03), location: 0.55),
                                    .init(color: Color.white.opacity(0.28), location: 1.00),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                // Mask: keep only a ring around the edges by subtracting a
                // soft-edged ellipse from the centre.
                .mask {
                    GeometryReader { g in
                        let w = g.size.width
                        let h = g.size.height
                        let insetX = w * edgeFade * 1.6
                        let insetY = h * edgeFade * 1.6
                        ZStack {
                            // Full card shape (white = visible)
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(Color.white)
                            // Centre knock-out (black = hidden), with soft gradient edges
                            LinearGradient(
                                colors: [.black, .clear],
                                startPoint: .leading,
                                endPoint: UnitPoint(x: edgeFade * 2.5, y: 0.5)
                            )
                            .blendMode(.destinationOut)

                            LinearGradient(
                                colors: [.black, .clear],
                                startPoint: .trailing,
                                endPoint: UnitPoint(x: 1 - edgeFade * 2.5, y: 0.5)
                            )
                            .blendMode(.destinationOut)

                            LinearGradient(
                                colors: [.black, .clear],
                                startPoint: .top,
                                endPoint: UnitPoint(x: 0.5, y: edgeFade * 2.2)
                            )
                            .blendMode(.destinationOut)

                            LinearGradient(
                                colors: [.black, .clear],
                                startPoint: .bottom,
                                endPoint: UnitPoint(x: 0.5, y: 1 - edgeFade * 2.2)
                            )
                            .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                    }
                }
                .compositingGroup()
            }
            // Outer rim stroke
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.70),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.38),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            }
            .shadow(color: .black.opacity(0.32), radius: 32, x: 0, y: 18)
            .shadow(color: .black.opacity(0.12), radius:  6, x: 0, y:  3)
    }
}

extension View {
    func liquidGlassEdges(cornerRadius: CGFloat = 32, edgeFade: CGFloat = 0.18) -> some View {
        modifier(LiquidGlassEdges(cornerRadius: cornerRadius, edgeFade: edgeFade))
    }
}

// MARK: - Liquid Glass Pill

extension View {
    func liquidGlassPill() -> some View {
        background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule().fill(LinearGradient(
                        colors: [Color.white.opacity(0.36), Color.white.opacity(0.06)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                }
                .overlay {
                    Capsule().strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.62), Color.white.opacity(0.10)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
                }
        }
    }
}

// MARK: - Tag Badge

struct TagBadge: View {
    let label: String
    let color: Color
    var body: some View {
        Text(label.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(LinearGradient(
                        colors: [color, color.opacity(0.65)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .overlay { Capsule().strokeBorder(Color.white.opacity(0.28), lineWidth: 0.8) }
                    .shadow(color: color.opacity(0.55), radius: 8, y: 4)
            }
    }
}

// MARK: - Dot Indicator

struct DotIndicator: View {
    let count: Int
    let current: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<min(count, 12), id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.white : Color.white.opacity(0.28))
                    .frame(width: i == current ? 22 : 7, height: 7)
                    .animation(.spring(response: 0.35, dampingFraction: 0.72), value: current)
            }
        }
    }
}

// MARK: - InfoRow

private struct InfoRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 16)
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.90))
    }
}

// MARK: - Invitation Card

struct InvitationCard: View {
    let invitation: Invitation

    var body: some View {
        // We need a fixed-size container — GeometryReader inside causes centering drift,
        // so we use a ZStack that fills its parent naturally.
        ZStack(alignment: .bottom) {

            // ── Hero image ───────────────────────────────────────────────────
            Image(invitation.imageName)
                .resizable()
                .scaledToFill()
                .layoutPriority(-1)

            // ── Tag (top-right) ──────────────────────────────────────────────
            VStack {
                HStack {
                    Spacer()
                    TagBadge(label: invitation.tag, color: invitation.tagColor)
                        .padding(.top, 24)
                        .padding(.trailing, 22)
                }
                Spacer()
            }

            // ── Info area: pure gradient, no box ────────────────────────────
            // A tall gradient fades the image to dark from ~40% height.
            // Text floats directly on top — no background shape at all.
            VStack(alignment: .leading, spacing: 0) {
                // Push content to bottom
                Spacer()

                Text(invitation.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.30), radius: 6, y: 3)

                Spacer().frame(height: 10)

                InfoRow(icon: "calendar",           text: invitation.date)
                Spacer().frame(height: 5)
                InfoRow(icon: "mappin.and.ellipse",  text: invitation.location)
                Spacer().frame(height: 5)
                InfoRow(icon: "person.crop.circle",  text: invitation.host)

                Spacer().frame(height: 20)

                // CTA
                HStack {
                    Spacer()
                    Text("Einladung öffnen")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 11)
                        .liquidGlassPill()
                    Spacer()
                }

                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 22)
            // The gradient is part of the card overlay, not the info panel
            .background(alignment: .bottom) {
                LinearGradient(
                    stops: [
                        .init(color: .clear,                   location: 0.0),
                        .init(color: .black.opacity(0.0),      location: 0.20),
                        .init(color: .black.opacity(0.45),     location: 0.48),
                        .init(color: .black.opacity(0.82),     location: 0.75),
                        .init(color: .black.opacity(0.92),     location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 380) // tall enough to cover info area + breathing room
            }
        }
        .clipped()
        // Liquid Glass edge shimmer applied directly to the image card
        .liquidGlassEdges(cornerRadius: 32, edgeFade: 0.16)
    }
}

// MARK: - Main Swiper

struct InvitationSwiper: View {

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    private let invitations = Invitation.samples
    // Only one haptic generator — fires only when a new card is actually committed
    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    private let swipeThreshold: CGFloat = 85

    var body: some View {
        GeometryReader { geo in
            // ── Card dimensions ──────────────────────────────────────────────
            // Use the FULL available width minus equal margins on both sides
            // so the card is truly centered in the screen.
            let hPad: CGFloat  = 20
            let cardW: CGFloat = geo.size.width - hPad * 2
            let cardH: CGFloat = min(geo.size.height * 0.67, 570.0)

            ZStack {
                // ── Animated background gradient matching current card ────────
                adaptiveBackground(size: geo.size)

                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.top, geo.safeAreaInsets.top + 10)
                        .padding(.horizontal, hPad + 6)

                    Spacer().frame(height: 24)

                    // ── Card stack ───────────────────────────────────────────
                    // ZStack is given EXACT size and positioned in center.
                    // All card offsets are computed relative to that center.
                    ZStack {
                        ForEach(visibleIndices, id: \.self) { idx in
                            InvitationCard(invitation: invitations[idx])
                                .frame(width: cardW, height: cardH)
                                // Offset: each card is spaced by cardW + gap
                                .offset(x: xOffset(for: idx, cardWidth: cardW))
                                .scaleEffect(scaleFor(idx))
                                .opacity(idx == currentIndex ? 1.0 : 0.60)
                                .zIndex(idx == currentIndex ? 10 : 5)
                                .animation(
                                    isDragging
                                    ? .interactiveSpring(response: 0.25, dampingFraction: 0.88)
                                    : .spring(response: 0.44, dampingFraction: 0.82),
                                    value: dragOffset
                                )
                        }
                    }
                    // The ZStack is exactly cardW wide and centered — NO extra width
                    .frame(width: cardW, height: cardH)
                    // Expand hit-test area to full screen width so swiping anywhere works
                    .contentShape(Rectangle().size(CGSize(width: geo.size.width, height: cardH)))
                    .frame(width: geo.size.width) // expand frame for gesture without shifting cards
                    .gesture(dragGesture(cardWidth: cardW))
                    // Clip so neighbouring cards peek in from the edges but don't overflow
                    .clipped()

                    Spacer().frame(height: 26)

                    DotIndicator(count: invitations.count, current: currentIndex)

                    Spacer()
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Background

    @ViewBuilder
    private func adaptiveBackground(size: CGSize) -> some View {
        let inv = invitations[currentIndex]
        ZStack {
            // Dark base
            Color(red: 0.04, green: 0.03, blue: 0.10)

            // Primary color blob (top)
            RadialGradient(
                colors: [inv.bgColors[0].opacity(0.85), .clear],
                center: .center, startRadius: 0, endRadius: 300
            )
            .frame(width: 600)
            .offset(x: -60, y: -size.height * 0.30)
            .blur(radius: 60)

            // Secondary color blob (bottom)
            RadialGradient(
                colors: [inv.bgColors.count > 1 ? inv.bgColors[1].opacity(0.70) : inv.bgColors[0].opacity(0.50), .clear],
                center: .center, startRadius: 0, endRadius: 280
            )
            .frame(width: 560)
            .offset(x: 100, y: size.height * 0.30)
            .blur(radius: 55)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.55), value: currentIndex)
    }

    // MARK: - Gesture

    private func dragGesture(cardWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                // Only allow horizontal drag
                isDragging = true
                dragOffset = value.translation.width
                // No haptic during drag — only on commit
            }
            .onEnded { value in
                isDragging = false
                let velocity = value.predictedEndTranslation.width

                if dragOffset < -swipeThreshold || velocity < -260 {
                    goToNext()
                } else if dragOffset > swipeThreshold || velocity > 260 {
                    goToPrev()
                } else {
                    snapBack()
                }
            }
    }

    private func goToNext() {
        guard currentIndex < invitations.count - 1 else { return bounceBack() }
        // ── Haptic fires ONLY here, when a new card is committed ──
        hapticImpact.impactOccurred(intensity: 0.80)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            currentIndex += 1
            dragOffset = 0
        }
    }

    private func goToPrev() {
        guard currentIndex > 0 else { return bounceBack() }
        // ── Haptic fires ONLY here ──
        hapticImpact.impactOccurred(intensity: 0.80)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            currentIndex -= 1
            dragOffset = 0
        }
    }

    private func snapBack() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) { dragOffset = 0 }
    }

    private func bounceBack() {
        hapticImpact.impactOccurred(intensity: 0.45)
        withAnimation(.spring(response: 0.30, dampingFraction: 0.44)) {
            dragOffset = dragOffset > 0 ? 16 : -16
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.68)) { dragOffset = 0 }
        }
    }

    // MARK: - Layout

    private var visibleIndices: [Int] {
        var r = [currentIndex]
        if currentIndex > 0                      { r.append(currentIndex - 1) }
        if currentIndex < invitations.count - 1  { r.append(currentIndex + 1) }
        return r
    }

    /// X offset: cards sit to the left/right of center based on their relative position.
    /// dragOffset shifts all of them together so the centre card moves under the finger.
    private func xOffset(for idx: Int, cardWidth: CGFloat) -> CGFloat {
        let gap: CGFloat = 18
        let relative = CGFloat(idx - currentIndex)
        return relative * (cardWidth + gap) + dragOffset
    }

    private func scaleFor(_ idx: Int) -> CGFloat {
        guard idx != currentIndex else { return 1.0 }
        // Slightly scale up neighbouring cards as they approach center during drag
        let progress = min(abs(dragOffset) / 160, 1.0)
        return 0.93 + progress * 0.04
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Einladungen")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(currentIndex + 1) von \(invitations.count)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
            }
            Spacer()
            HStack(spacing: -9) {
                ForEach(Array([Color.purple, Color.pink, Color.orange].enumerated()), id: \.offset) { i, color in
                    Circle()
                        .fill(color.gradient)
                        .frame(width: 30, height: 30)
                        .overlay { Circle().strokeBorder(Color.black.opacity(0.4), lineWidth: 1.5) }
                        .zIndex(Double(3 - i))
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: currentIndex)
    }
}

// MARK: - Preview

#Preview {
    InvitationSwiper()
        .preferredColorScheme(.dark)
}
