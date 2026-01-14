//
//  Color+Tokens.swift
//  RustMate
//
//  Created by Speckit on 2026-01-02.
//  Feature: 004-glass-ui-refresh
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

extension Color {
    /// Creates a color that adapts to the current appearance.
    /// - Parameters:
    ///   - light: The color to use in light mode.
    ///   - dark: The color to use in dark mode.
    init(light: Color, dark: Color) {
        #if os(macOS)
        self.init(nsColor: NSColor(name: nil) { appearance in
            switch appearance.name {
            case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
                return NSColor(dark)
            default:
                return NSColor(light)
            }
        })
        #else
        self.init(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
        #endif
    }
    // MARK: - Semantic Colors from Tokens

    static var glassBackground: Color {
        GlassTokens.Colors.backgroundPrimary
    }

    static var glassBackgroundSecondary: Color {
        GlassTokens.Colors.backgroundSecondary
    }

    static var glassCard: Color {
        GlassTokens.Colors.cardBackground
    }

    static var glassTextPrimary: Color {
        GlassTokens.Colors.textPrimary
    }

    static var glassTextSecondary: Color {
        GlassTokens.Colors.textSecondary
    }

    static var glassTextTertiary: Color {
        GlassTokens.Colors.textTertiary
    }

    static var glassDivider: Color {
        GlassTokens.Colors.divider
    }

    // MARK: - Status Colors

    static var glassSuccess: Color {
        GlassTokens.Colors.success
    }

    static var glassWarning: Color {
        GlassTokens.Colors.warning
    }

    static var glassError: Color {
        GlassTokens.Colors.error
    }

    static var glassInfo: Color {
        GlassTokens.Colors.info
    }
}
