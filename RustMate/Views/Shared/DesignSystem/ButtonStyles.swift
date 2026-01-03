//
//  ButtonStyles.swift
//  RustMate
//
//  Created by Speckit on 2026-01-02.
//  Feature: 004-glass-ui-refresh
//

import SwiftUI

/// Custom button styles for consistent button hierarchy across the app
/// Provides primary, secondary, and tertiary button variations

// MARK: - Primary Button Style

struct PrimaryGlassButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, GlassTokens.Spacing.lg)
            .padding(.vertical, GlassTokens.Spacing.sm)
            .background(
                isEnabled
                    ? GlassTokens.Colors.accent
                    : GlassTokens.Colors.accent.opacity(0.5)
            )
            .cornerRadius(GlassTokens.Radius.md)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(reduceMotion ? nil : GlassTokens.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct SecondaryGlassButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
            .foregroundColor(isEnabled ? GlassTokens.Colors.textPrimary : GlassTokens.Colors.textTertiary)
            .padding(.horizontal, GlassTokens.Spacing.lg)
            .padding(.vertical, GlassTokens.Spacing.sm)
            .background(GlassTokens.Colors.cardBackground)
            .cornerRadius(GlassTokens.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                    .stroke(GlassTokens.Colors.divider, lineWidth: GlassTokens.Stroke.regular)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(reduceMotion ? nil : GlassTokens.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - Tertiary Button Style (Text Only)

struct TertiaryGlassButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
            .foregroundColor(isEnabled ? GlassTokens.Colors.accent : GlassTokens.Colors.textTertiary)
            .padding(.horizontal, GlassTokens.Spacing.md)
            .padding(.vertical, GlassTokens.Spacing.sm)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(reduceMotion ? nil : GlassTokens.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - Destructive Button Style

struct DestructiveGlassButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, GlassTokens.Spacing.lg)
            .padding(.vertical, GlassTokens.Spacing.sm)
            .background(
                isEnabled
                    ? GlassTokens.Colors.error
                    : GlassTokens.Colors.error.opacity(0.5)
            )
            .cornerRadius(GlassTokens.Radius.md)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(reduceMotion ? nil : GlassTokens.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply primary glass button style
    func primaryGlassButtonStyle() -> some View {
        self.buttonStyle(PrimaryGlassButtonStyle())
    }

    /// Apply secondary glass button style
    func secondaryGlassButtonStyle() -> some View {
        self.buttonStyle(SecondaryGlassButtonStyle())
    }

    /// Apply tertiary glass button style (text only)
    func tertiaryGlassButtonStyle() -> some View {
        self.buttonStyle(TertiaryGlassButtonStyle())
    }

    /// Apply destructive glass button style
    func destructiveGlassButtonStyle() -> some View {
        self.buttonStyle(DestructiveGlassButtonStyle())
    }
}

// MARK: - Previews

#Preview("Button Styles") {
    VStack(spacing: GlassTokens.Spacing.lg) {
        Button("Primary Button") {}
            .primaryGlassButtonStyle()

        Button("Secondary Button") {}
            .secondaryGlassButtonStyle()

        Button("Tertiary Button") {}
            .tertiaryGlassButtonStyle()

        Button("Destructive Button") {}
            .destructiveGlassButtonStyle()

        Divider()

        Button("Disabled Primary") {}
            .primaryGlassButtonStyle()
            .disabled(true)

        Button("Disabled Secondary") {}
            .secondaryGlassButtonStyle()
            .disabled(true)
    }
    .padding(GlassTokens.Spacing.xl)
    .frame(width: 300)
}

#Preview("Button Styles - Dark") {
    VStack(spacing: GlassTokens.Spacing.lg) {
        Button("Primary Button") {}
            .primaryGlassButtonStyle()

        Button("Secondary Button") {}
            .secondaryGlassButtonStyle()

        Button("Tertiary Button") {}
            .tertiaryGlassButtonStyle()

        Button("Destructive Button") {}
            .destructiveGlassButtonStyle()
    }
    .padding(GlassTokens.Spacing.xl)
    .frame(width: 300)
    .preferredColorScheme(.dark)
}
