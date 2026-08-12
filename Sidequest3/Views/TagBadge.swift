import SwiftUI

struct TagBadge: View {
    let label: String
    var color: Color = .accentColor

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption).fontWeight(.semibold).fontDesign(.rounded)
                .textCase(.uppercase)
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(0.6))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Theme.borderLight, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Kategorie: \(label)")
    }
}
