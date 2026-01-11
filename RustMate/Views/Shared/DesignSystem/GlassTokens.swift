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
        // Background layers - Light theme optimized
        static let backgroundPrimary = Color(white: 0.98)  // Very light gray/white
        static let backgroundSecondary = Color(white: 0.95)  // Light gray
        static let backgroundTertiary = Color(white: 0.92)  // Slightly darker gray

        // Card colors - Clean white cards with subtle borders
        static let cardBackground = Color.white
        static let cardStroke = Color(white: 0.85)  // Light gray border

        // Text colors
        static let textPrimary = Color(white: 0.1)  // Almost black
        static let textSecondary = Color(white: 0.4)  // Medium gray
        static let textTertiary = Color(white: 0.6)  // Light gray

        // Accent and emphasis - Blue theme
        static let accent = Color(red: 0.0, green: 0.478, blue: 1.0)  // System blue
        static let accentSubtle = Color(red: 0.0, green: 0.478, blue: 1.0, opacity: 0.1)  // Light blue background
        static let accentHover = Color(red: 0.0, green: 0.4, blue: 0.9)  // Darker blue for hover

        // Status colors - Vibrant but not too bright
        static let success = Color(red: 0.2, green: 0.7, blue: 0.3)  // Green
        static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)  // Orange
        static let error = Color(red: 0.9, green: 0.2, blue: 0.2)  // Red
        static let info = Color(red: 0.0, green: 0.478, blue: 1.0)  // Blue

        // Status subtle backgrounds - Light backgrounds for status indicators
        static let successSubtle = Color(red: 0.2, green: 0.7, blue: 0.3, opacity: 0.1)
        static let warningSubtle = Color(red: 1.0, green: 0.6, blue: 0.0, opacity: 0.1)
        static let errorSubtle = Color(red: 0.9, green: 0.2, blue: 0.2, opacity: 0.1)
        static let infoSubtle = Color(red: 0.0, green: 0.478, blue: 1.0, opacity: 0.1)

        // Dividers - Light gray dividers
        static let divider = Color(white: 0.85)
        static let dividerSubtle = Color(white: 0.9)
        
        // Selection and active states
        static let selectionBackground = Color(red: 0.0, green: 0.478, blue: 1.0, opacity: 0.1)  // Light blue for selected items
        static let selectionBorder = Color(red: 0.0, green: 0.478, blue: 1.0)  // Blue border for selected items
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
