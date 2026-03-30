import SwiftUI

struct TagBadge: View {
    let label: String
    var color: Color = .accentColor

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color.opacity(0.9))
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .textCase(.uppercase)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(0.6))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Kategorie: \(label)")
    }
}

#Preview {
    VStack(spacing: 16) {
        TagBadge(label: "Café", color: .brown)
        TagBadge(label: "Restaurant", color: .orange)
        TagBadge(label: "Museum", color: .blue)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
