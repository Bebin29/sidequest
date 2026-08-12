//
//  GlassModifiers.swift
//  Sidequest
//
//  Single source of truth for Liquid Glass styling.
//  iOS 18: simulates glass with materials + specular chrome.
//  iOS 26: swap to native .glassEffect() in this file only.
//

import SwiftUI

// MARK: - Liquid Glass Visual Simulation (iOS 18)

private struct LiquidGlassChrome<S: InsettableShape>: ViewModifier {
    let shape: S
    let intensity: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.45 * intensity),
                                .white.opacity(0.15 * intensity),
                                .white.opacity(0.05 * intensity)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.75
                    )
                    .allowsHitTesting(false)
            }
            .overlay {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.12 * intensity),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .allowsHitTesting(false)
            }
    }
}

// MARK: - Glass Background Modifiers

extension View {
    func adaptiveGlass(in shape: some InsettableShape = RoundedRectangle(cornerRadius: 16, style: .continuous)) -> some View {
        self
            .background(.ultraThinMaterial, in: shape)
            .modifier(LiquidGlassChrome(shape: shape, intensity: 1.0))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }

    func adaptiveClearGlass(in shape: some InsettableShape = RoundedRectangle(cornerRadius: 16, style: .continuous)) -> some View {
        self
            .background(.ultraThinMaterial.opacity(0.5), in: shape)
            .modifier(LiquidGlassChrome(shape: shape, intensity: 0.6))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    func adaptiveInteractiveGlass(in shape: some InsettableShape = RoundedRectangle(cornerRadius: 16, style: .continuous)) -> some View {
        self
            .background(.ultraThinMaterial, in: shape)
            .modifier(LiquidGlassChrome(shape: shape, intensity: 1.2))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }

    func adaptiveTintedGlass(_ color: Color, in shape: some InsettableShape = RoundedRectangle(cornerRadius: 16, style: .continuous)) -> some View {
        self
            .background(color.opacity(0.5), in: shape)
            .background(.ultraThinMaterial, in: shape)
            .modifier(LiquidGlassChrome(shape: shape, intensity: 0.8))
            .shadow(color: color.opacity(0.15), radius: 8, y: 3)
    }
}

// MARK: - Glass Group (future GlassEffectContainer)

struct GlassGroup<Content: View>: View {
    let spacing: CGFloat?
    @ViewBuilder let content: () -> Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        content()
    }
}

// MARK: - Glass Button Styles

struct GlassButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .adaptiveInteractiveGlass(in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GlassProminentButtonStyle: ButtonStyle {
    var color: Color = .accentColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .adaptiveTintedGlass(color, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
