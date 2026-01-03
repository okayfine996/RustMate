//
//  Typography.swift
//  RustMate
//
//  Created by Speckit on 2026-01-02.
//  Feature: 004-glass-ui-refresh
//

import SwiftUI

extension View {
    // MARK: - Typography Modifiers

    func displayText() -> some View {
        self.font(.system(size: GlassTokens.Typography.displaySize, weight: GlassTokens.Typography.displayWeight))
    }

    func titleText() -> some View {
        self.font(.system(size: GlassTokens.Typography.titleSize, weight: GlassTokens.Typography.titleWeight))
    }

    func headlineText() -> some View {
        self.font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
    }

    func bodyText() -> some View {
        self.font(.system(size: GlassTokens.Typography.bodySize, weight: GlassTokens.Typography.bodyWeight))
    }

    func calloutText() -> some View {
        self.font(.system(size: GlassTokens.Typography.calloutSize))
    }

    func captionText() -> some View {
        self.font(.system(size: GlassTokens.Typography.captionSize))
    }

    // MARK: - Combined Typography & Color

    func primaryLabel() -> some View {
        self
            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
            .foregroundColor(GlassTokens.Colors.textPrimary)
    }

    func secondaryLabel() -> some View {
        self
            .font(.system(size: GlassTokens.Typography.calloutSize))
            .foregroundColor(GlassTokens.Colors.textSecondary)
    }

    func tertiaryLabel() -> some View {
        self
            .font(.system(size: GlassTokens.Typography.captionSize))
            .foregroundColor(GlassTokens.Colors.textTertiary)
    }
}
