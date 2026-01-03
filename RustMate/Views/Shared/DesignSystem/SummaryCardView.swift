//
//  SummaryCardView.swift
//  RustMate
//
//  Created by Speckit on 2026-01-02.
//  Feature: 004-glass-ui-refresh
//

import SwiftUI

/// Summary card for displaying key metrics or status at a glance
/// Used in toolchains overview and other summary sections
struct SummaryCardView: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    let accentColor: Color

    init(
        icon: String,
        title: String,
        value: String,
        subtitle: String? = nil,
        accentColor: Color = GlassTokens.Colors.accent
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.accentColor = accentColor
    }

    var body: some View {
        GlassCard(padding: GlassTokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: GlassTokens.Typography.headlineSize))
                        .foregroundColor(accentColor)

                    Text(title)
                        .font(.system(size: GlassTokens.Typography.calloutSize, weight: .medium))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }

                Text(value)
                    .font(.system(size: GlassTokens.Typography.displaySize, weight: GlassTokens.Typography.displayWeight))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Previews

#Preview("Summary Cards") {
    HStack(spacing: GlassTokens.Spacing.md) {
        SummaryCardView(
            icon: "hammer",
            title: "Installed",
            value: "3",
            subtitle: "Toolchains",
            accentColor: GlassTokens.Colors.success
        )

        SummaryCardView(
            icon: "arrow.triangle.2.circlepath",
            title: "Updates",
            value: "1",
            subtitle: "Available",
            accentColor: GlassTokens.Colors.warning
        )

        SummaryCardView(
            icon: "star.fill",
            title: "Default",
            value: "stable",
            accentColor: GlassTokens.Colors.accent
        )
    }
    .padding(GlassTokens.Spacing.xl)
    .frame(width: 700)
}

#Preview("Summary Cards - Dark") {
    HStack(spacing: GlassTokens.Spacing.md) {
        SummaryCardView(
            icon: "hammer",
            title: "Installed",
            value: "3",
            subtitle: "Toolchains",
            accentColor: GlassTokens.Colors.success
        )

        SummaryCardView(
            icon: "arrow.triangle.2.circlepath",
            title: "Updates",
            value: "1",
            subtitle: "Available",
            accentColor: GlassTokens.Colors.warning
        )

        SummaryCardView(
            icon: "star.fill",
            title: "Default",
            value: "stable",
            accentColor: GlassTokens.Colors.accent
        )
    }
    .padding(GlassTokens.Spacing.xl)
    .frame(width: 700)
    .preferredColorScheme(.dark)
}
