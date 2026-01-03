//
//  Color+Tokens.swift
//  RustMate
//
//  Created by Speckit on 2026-01-02.
//  Feature: 004-glass-ui-refresh
//

import SwiftUI

extension Color {
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
