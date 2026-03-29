//
//  CategoryBadge.swift
//  Sidequest
//

import SwiftUI

struct CategoryBadge: View {
    let category: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: CategoryHelper.icon(for: category))
                .font(.caption2)
            Text(category)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.blue.opacity(0.1))
        .foregroundStyle(.blue)
        .clipShape(Capsule())
    }
}
