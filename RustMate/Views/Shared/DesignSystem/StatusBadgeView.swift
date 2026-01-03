//
//  StatusBadgeView.swift
//  RustMate
//
//  Created by Speckit on 2026-01-02.
//  Feature: 004-glass-ui-refresh
//

import SwiftUI

/// Status badge for toolchains, components, targets, and tasks
/// Provides consistent visual language for status indication
struct StatusBadgeView: View {
    enum BadgeStatus {
        case `default`
        case installed
        case update
        case running
        case success
        case failed
        case info

        var color: Color {
            switch self {
            case .default: return GlassTokens.Colors.accent
            case .installed: return GlassTokens.Colors.success
            case .update: return GlassTokens.Colors.warning
            case .running: return GlassTokens.Colors.info
            case .success: return GlassTokens.Colors.success
            case .failed: return GlassTokens.Colors.error
            case .info: return GlassTokens.Colors.info
            }
        }

        var backgroundColor: Color {
            switch self {
            case .default: return GlassTokens.Colors.accentSubtle
            case .installed: return GlassTokens.Colors.successSubtle
            case .update: return GlassTokens.Colors.warningSubtle
            case .running: return GlassTokens.Colors.infoSubtle
            case .success: return GlassTokens.Colors.successSubtle
            case .failed: return GlassTokens.Colors.errorSubtle
            case .info: return GlassTokens.Colors.infoSubtle
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .default: return "Default"
            case .installed: return "Installed"
            case .update: return "Update available"
            case .running: return "Running"
            case .success: return "Success"
            case .failed: return "Failed"
            case .info: return "Information"
            }
        }
    }

    let status: BadgeStatus
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
            .foregroundColor(status.color)
            .padding(.horizontal, GlassTokens.Spacing.sm)
            .padding(.vertical, GlassTokens.Spacing.xs)
            .background(status.backgroundColor)
            .cornerRadius(GlassTokens.Radius.sm)
            .accessibilityLabel(status.accessibilityLabel)
            .accessibilityValue(text)
    }
}

// MARK: - Previews

#Preview("Status Badges - All States") {
    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
        StatusBadgeView(status: .default, text: "Default")
        StatusBadgeView(status: .installed, text: "Installed")
        StatusBadgeView(status: .update, text: "Update")
        StatusBadgeView(status: .running, text: "Running")
        StatusBadgeView(status: .success, text: "Success")
        StatusBadgeView(status: .failed, text: "Failed")
        StatusBadgeView(status: .info, text: "Info")
    }
    .padding(GlassTokens.Spacing.xl)
}

#Preview("Status Badges - Dark Mode") {
    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
        StatusBadgeView(status: .default, text: "Default")
        StatusBadgeView(status: .installed, text: "Installed")
        StatusBadgeView(status: .update, text: "Update")
        StatusBadgeView(status: .running, text: "Running")
        StatusBadgeView(status: .success, text: "Success")
        StatusBadgeView(status: .failed, text: "Failed")
        StatusBadgeView(status: .info, text: "Info")
    }
    .padding(GlassTokens.Spacing.xl)
    .preferredColorScheme(.dark)
}
