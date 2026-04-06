//
//  DesignTokens.swift
//  Sidequest
//
//  Central design token system. Single source of truth for all style values.
//  Dark-only app — tokens optimized for dark backgrounds.
//

import SwiftUI
import UIKit

// MARK: - Colors

enum Theme {
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.4)

    // Accent
    static let accent = Color.accentColor // systemIndigo via Asset Catalog

    // Backgrounds
    static let cardBackground = Color(UIColor.systemGray).opacity(0.2)
    static let imagePlaceholder = Color(UIColor.systemGray4)
    static let skeletonFill = Color.white.opacity(0.06)
    static let skeletonFillLight = Color.white.opacity(0.08)
    static let skeletonFillMedium = Color.white.opacity(0.10)

    // Borders & Dividers
    static let border = Color.white.opacity(0.08)
    static let borderLight = Color.white.opacity(0.25)
    static let divider = Color.white.opacity(0.06)

    // Semantic
    static let destructive = Color.red
    static let success = Color.green

    // Base background (for views like MainView adaptive BG)
    static let darkBase = Color(red: 0.06, green: 0.05, blue: 0.12)
}

// MARK: - Spacing (8pt Grid)

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radii

enum Radius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let card: CGFloat = 20
    static let carousel: CGFloat = 28
}

