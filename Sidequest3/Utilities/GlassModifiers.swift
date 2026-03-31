//
//  GlassModifiers.swift
//  Sidequest
//
//  Single source of truth for Liquid Glass styling.
//  iOS 26: native .glassEffect() APIs.
//

import SwiftUI

// MARK: - Glass Background Modifiers

extension View {
    func adaptiveGlass(in shape: some Shape = RoundedRectangle(cornerRadius: 16, style: .continuous)) -> some View {
        self.glassEffect(.regular, in: shape)
    }

    func adaptiveClearGlass(in shape: some Shape = RoundedRectangle(cornerRadius: 16, style: .continuous)) -> some View {
        self.glassEffect(.clear, in: shape)
    }

    func adaptiveInteractiveGlass(in shape: some Shape = RoundedRectangle(cornerRadius: 16, style: .continuous)) -> some View {
        self.glassEffect(.regular.interactive(), in: shape)
    }

    func adaptiveTintedGlass(_ color: Color, in shape: some Shape = RoundedRectangle(cornerRadius: 16, style: .continuous)) -> some View {
        self.glassEffect(.regular.tint(color), in: shape)
    }
}

// MARK: - Glass Group

struct GlassGroup<Content: View>: View {
    let spacing: CGFloat?
    @ViewBuilder let content: () -> Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GlassEffectContainer(spacing: spacing ?? 0) {
            content()
        }
    }
}
