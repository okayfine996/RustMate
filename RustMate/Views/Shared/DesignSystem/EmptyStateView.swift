//
//  EmptyStateView.swift
//  RustMate
//
//  Created by Speckit on 2026-01-02.
//  Feature: 004-glass-ui-refresh
//

import SwiftUI

/// Unified empty state view for consistent messaging across the app
/// Shows icon, title, description, and optional action
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: GlassTokens.Spacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(GlassTokens.Colors.textTertiary)

            VStack(spacing: GlassTokens.Spacing.sm) {
                Text(title)
                    .font(.system(size: GlassTokens.Typography.titleSize, weight: GlassTokens.Typography.titleWeight))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text(description)
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .frame(minWidth: 120)
                }
                .primaryButtonStyle()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(GlassTokens.Spacing.xxl)
    }
}

// MARK: - Previews

#Preview("Empty State - No Toolchains") {
    EmptyStateView(
        icon: "hammer",
        title: "No Toolchains",
        description: "You haven't installed any Rust toolchains yet. Get started by installing your first toolchain.",
        actionTitle: "Install Toolchain",
        action: { print("Install tapped") }
    )
    .frame(width: 600, height: 400)
}

#Preview("Empty State - No Components") {
    EmptyStateView(
        icon: "puzzlepiece.extension",
        title: "No Components",
        description: "No components are installed for this toolchain.",
        actionTitle: "Add Component",
        action: { print("Add tapped") }
    )
    .frame(width: 600, height: 400)
    .preferredColorScheme(.dark)
}

#Preview("Empty State - No Action") {
    EmptyStateView(
        icon: "doc.text.magnifyingglass",
        title: "No Results",
        description: "Try adjusting your search or filter criteria."
    )
    .frame(width: 600, height: 400)
}
