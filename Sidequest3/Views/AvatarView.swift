//
//  AvatarView.swift
//  Sidequest
//
//  Reusable avatar component. Displays a user's profile image
//  with consistent sizing, placeholder, and caching.
//

import SwiftUI

enum AvatarSize {
    case small   // 32pt — compact lists
    case medium  // 44pt — standard list rows
    case large   // 96pt — profile headers

    var points: CGFloat {
        switch self {
        case .small: 32
        case .medium: 44
        case .large: 96
        }
    }
}

struct AvatarView: View {
    let url: String?
    var fallbackInitial: String?
    var size: AvatarSize = .medium

    var body: some View {
        Group {
            if let urlString = url, let imageUrl = URL(string: urlString) {
                CachedAsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholderView
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size.points, height: size.points)
        .clipShape(Circle())
    }

    private var placeholderView: some View {
        Circle()
            .fill(Theme.imagePlaceholder)
            .overlay {
                if let initial = fallbackInitial?.prefix(1).uppercased(), !initial.isEmpty {
                    Text(initial)
                        .font(initialFont)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Image(systemName: "person.fill")
                        .font(iconFont)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
    }

    private var initialFont: Font {
        switch size {
        case .small: .caption2
        case .medium: .subheadline
        case .large: .title
        }
    }

    private var iconFont: Font {
        switch size {
        case .small: .caption
        case .medium: .body
        case .large: .largeTitle
        }
    }
}
