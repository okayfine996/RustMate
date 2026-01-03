//
//  GlassTokens.swift
//  RustMate
//
//  Created by Speckit on 2026-01-02.
//  Feature: 004-glass-ui-refresh
//

import SwiftUI

/// Unified design tokens for glass morphism UI refresh
/// Provides consistent spacing, colors, typography, and effects across the app
enum GlassTokens {

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let pill: CGFloat = 999 // For capsule shapes
    }

    // MARK: - Colors

    enum Colors {
        // Background layers
        static let backgroundPrimary = Color(nsColor: .windowBackgroundColor)
        static let backgroundSecondary = Color(nsColor: .controlBackgroundColor)
        static let backgroundTertiary = Color(nsColor: .underPageBackgroundColor)

        // Glass card colors
        static let cardBackground = Color.black.opacity(0.2)
        static let cardStroke = Color.white.opacity(0.1)

        // Text colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(nsColor: .tertiaryLabelColor)

        // Accent and emphasis
        static let accent = Color.accentColor
        static let accentSubtle = Color.accentColor.opacity(0.15)

        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue

        // Status subtle backgrounds
        static let successSubtle = Color.green.opacity(0.15)
        static let warningSubtle = Color.orange.opacity(0.15)
        static let errorSubtle = Color.red.opacity(0.15)
        static let infoSubtle = Color.blue.opacity(0.15)

        // Dividers
        static let divider = Color(nsColor: .separatorColor)
        static let dividerSubtle = Color(nsColor: .separatorColor).opacity(0.5)
    }

    // MARK: - Typography

    enum Typography {
        // Font sizes
        static let displaySize: CGFloat = 28
        static let titleSize: CGFloat = 20
        static let headlineSize: CGFloat = 17
        static let bodySize: CGFloat = 15
        static let calloutSize: CGFloat = 13
        static let captionSize: CGFloat = 11

        // Font weights
        static let displayWeight: Font.Weight = .bold
        static let titleWeight: Font.Weight = .semibold
        static let headlineWeight: Font.Weight = .medium
        static let bodyWeight: Font.Weight = .regular

        // Line heights (multipliers)
        static let tightLineHeight: CGFloat = 1.2
        static let normalLineHeight: CGFloat = 1.4
        static let relaxedLineHeight: CGFloat = 1.6
    }

    // MARK: - Elevation & Shadows

    enum Elevation {
        static let none: CGFloat = 0
        static let sm: CGFloat = 1
        static let md: CGFloat = 2
        static let lg: CGFloat = 4
        static let xl: CGFloat = 8

        static func shadow(level: CGFloat) -> some View {
            EmptyView()
                .shadow(color: .black.opacity(0.1), radius: level, x: 0, y: level / 2)
        }
    }

    // MARK: - Stroke & Border

    enum Stroke {
        static let thin: CGFloat = 0.5
        static let regular: CGFloat = 1.0
        static let thick: CGFloat = 2.0

        static let defaultColor = Colors.cardStroke
    }

    // MARK: - Animation

    enum Animation {
        static let fast: SwiftUI.Animation = .easeInOut(duration: 0.15)
        static let normal: SwiftUI.Animation = .easeInOut(duration: 0.25)
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.35)

        static let spring: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.7)
    }

    // MARK: - Layout Constants

    enum Layout {
        static let minTapTarget: CGFloat = 44
        static let minRowHeight: CGFloat = 44
        static let cardPadding: CGFloat = Spacing.lg
        static let listRowSpacing: CGFloat = Spacing.sm
        static let sectionSpacing: CGFloat = Spacing.xl
    }
}

// MARK: - Convenience View Modifiers

extension View {
    /// Apply glass card styling with optional stroke
    func glassCard(elevation: CGFloat = GlassTokens.Elevation.md) -> some View {
        self
            .background(GlassTokens.Colors.cardBackground)
            .background(.ultraThinMaterial)
            .cornerRadius(GlassTokens.Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: GlassTokens.Radius.lg)
                    .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
            )
            .shadow(color: .black.opacity(0.1), radius: elevation, x: 0, y: elevation / 2)
    }

    /// Apply primary button styling
    func primaryButtonStyle() -> some View {
        self
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
    }

    /// Apply secondary button styling
    func secondaryButtonStyle() -> some View {
        self
            .buttonStyle(.bordered)
            .controlSize(.large)
    }
}
