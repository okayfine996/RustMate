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
        // Background layers - Adaptive for light/dark mode
        static var backgroundPrimary: Color {
            Color(light: Color(white: 0.98), dark: Color(white: 0.1))
        }
        static var backgroundSecondary: Color {
            Color(light: Color(white: 0.95), dark: Color(white: 0.15))
        }
        static var backgroundTertiary: Color {
            Color(light: Color(white: 0.92), dark: Color(white: 0.2))
        }

        // Card colors - Adaptive white/dark cards
        static var cardBackground: Color {
            Color(light: Color.white, dark: Color(white: 0.15))
        }
        static var cardStroke: Color {
            Color(light: Color(white: 0.85), dark: Color(white: 0.3))
        }

        // Text colors - Adaptive for contrast
        static var textPrimary: Color {
            Color(light: Color(white: 0.1), dark: Color(white: 0.95))
        }
        static var textSecondary: Color {
            Color(light: Color(white: 0.4), dark: Color(white: 0.65))
        }
        static var textTertiary: Color {
            Color(light: Color(white: 0.6), dark: Color(white: 0.5))
        }

        // Accent and emphasis - Blue theme (works in both modes)
        static let accent = Color(red: 0.0, green: 0.478, blue: 1.0)  // System blue
        static var accentSubtle: Color {
            Color(light: Color(red: 0.0, green: 0.478, blue: 1.0, opacity: 0.1),
                  dark: Color(red: 0.0, green: 0.478, blue: 1.0, opacity: 0.2))
        }
        static let accentHover = Color(red: 0.0, green: 0.4, blue: 0.9)  // Darker blue for hover

        // Status colors - Vibrant but not too bright (work in both modes)
        static let success = Color(red: 0.2, green: 0.7, blue: 0.3)  // Green
        static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)  // Orange
        static let error = Color(red: 0.9, green: 0.2, blue: 0.2)  // Red
        static let info = Color(red: 0.0, green: 0.478, blue: 1.0)  // Blue

        // Status subtle backgrounds - Adaptive opacity
        static var successSubtle: Color {
            Color(light: Color(red: 0.2, green: 0.7, blue: 0.3, opacity: 0.1),
                  dark: Color(red: 0.2, green: 0.7, blue: 0.3, opacity: 0.2))
        }
        static var warningSubtle: Color {
            Color(light: Color(red: 1.0, green: 0.6, blue: 0.0, opacity: 0.1),
                  dark: Color(red: 1.0, green: 0.6, blue: 0.0, opacity: 0.2))
        }
        static var errorSubtle: Color {
            Color(light: Color(red: 0.9, green: 0.2, blue: 0.2, opacity: 0.1),
                  dark: Color(red: 0.9, green: 0.2, blue: 0.2, opacity: 0.2))
        }
        static var infoSubtle: Color {
            Color(light: Color(red: 0.0, green: 0.478, blue: 1.0, opacity: 0.1),
                  dark: Color(red: 0.0, green: 0.478, blue: 1.0, opacity: 0.2))
        }

        // Dividers - Adaptive gray dividers
        static var divider: Color {
            Color(light: Color(white: 0.85), dark: Color(white: 0.3))
        }
        static var dividerSubtle: Color {
            Color(light: Color(white: 0.9), dark: Color(white: 0.25))
        }
        
        // Selection and active states
        static var selectionBackground: Color {
            Color(light: Color(red: 0.0, green: 0.478, blue: 1.0, opacity: 0.1),
                  dark: Color(red: 0.0, green: 0.478, blue: 1.0, opacity: 0.2))
        }
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
