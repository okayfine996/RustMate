//
//  GlassCard.swift
//  RustMate
//
//  Created by Speckit on 2026-01-02.
//  Feature: 004-glass-ui-refresh
//

import SwiftUI

/// Glass morphism card container with consistent styling
/// Provides elevation, stroke, and subtle material effects
struct GlassCard<Content: View>: View {
    let content: Content
    let elevation: CGFloat
    let padding: CGFloat

    init(
        elevation: CGFloat = GlassTokens.Elevation.md,
        padding: CGFloat = GlassTokens.Layout.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(GlassTokens.Colors.cardBackground)
            .background(.ultraThinMaterial)
            .cornerRadius(GlassTokens.Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: GlassTokens.Radius.lg)
                    .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
            )
            .shadow(color: .black.opacity(0.1), radius: elevation, x: 0, y: elevation / 2)
    }
}

// MARK: - Previews

#Preview("Glass Card - Light") {
    VStack(spacing: GlassTokens.Spacing.xl) {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                Text("Sample Card")
                    .font(.system(size: GlassTokens.Typography.titleSize, weight: GlassTokens.Typography.titleWeight))
                Text("This is a glass morphism card with consistent styling")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
        }

        GlassCard(elevation: GlassTokens.Elevation.lg) {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                Text("Elevated Card")
                    .font(.system(size: GlassTokens.Typography.titleSize, weight: GlassTokens.Typography.titleWeight))
                Text("This card has higher elevation")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
        }
    }
    .padding(GlassTokens.Spacing.xl)
    .frame(width: 400)
}

#Preview("Glass Card - Dark") {
    VStack(spacing: GlassTokens.Spacing.xl) {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                Text("Sample Card")
                    .font(.system(size: GlassTokens.Typography.titleSize, weight: GlassTokens.Typography.titleWeight))
                Text("This is a glass morphism card with consistent styling")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
        }

        GlassCard(elevation: GlassTokens.Elevation.lg) {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                Text("Elevated Card")
                    .font(.system(size: GlassTokens.Typography.titleSize, weight: GlassTokens.Typography.titleWeight))
                Text("This card has higher elevation")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
        }
    }
    .padding(GlassTokens.Spacing.xl)
    .frame(width: 400)
    .preferredColorScheme(.dark)
}
