//
//  ErrorCalloutView.swift
//  RustMate
//
//  Created by Speckit on 2026-01-02.
//  Feature: 004-glass-ui-refresh
//

import SwiftUI
import AppKit

/// Error callout with structured error message, suggestion, and actions
/// Provides consistent error presentation across the app
struct ErrorCalloutView: View {
    let title: String
    let message: String
    let suggestion: String?
    let retryAction: (() -> Void)?
    let secondaryActionTitle: String?
    let secondaryAction: (() -> Void)?
    let errorDetails: String?

    init(
        title: String,
        message: String,
        suggestion: String? = nil,
        retryAction: (() -> Void)? = nil,
        secondaryActionTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil,
        errorDetails: String? = nil
    ) {
        self.title = title
        self.message = message
        self.suggestion = suggestion
        self.retryAction = retryAction
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryAction = secondaryAction
        self.errorDetails = errorDetails
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                // Header with icon
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: GlassTokens.Typography.headlineSize))
                        .foregroundColor(GlassTokens.Colors.error)

                    Text(title)
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                }

                // Error message
                Text(message)
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Suggestion if available
                if let suggestion = suggestion {
                    HStack(alignment: .top, spacing: GlassTokens.Spacing.sm) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: GlassTokens.Typography.calloutSize))
                            .foregroundColor(GlassTokens.Colors.warning)

                        Text(suggestion)
                            .font(.system(size: GlassTokens.Typography.calloutSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(GlassTokens.Spacing.sm)
                    .background(GlassTokens.Colors.warningSubtle)
                    .cornerRadius(GlassTokens.Radius.md)
                }

                // Actions
                HStack(spacing: GlassTokens.Spacing.sm) {
                    if let retryAction = retryAction {
                        Button(action: retryAction) {
                            Label("Retry", systemImage: "arrow.clockwise")
                        }
                        .primaryButtonStyle()
                    }

                    if let secondaryActionTitle = secondaryActionTitle,
                       let secondaryAction = secondaryAction {
                        Button(action: secondaryAction) {
                            Text(secondaryActionTitle)
                        }
                        .secondaryButtonStyle()
                    }

                    if let errorDetails = errorDetails {
                        Button {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(errorDetails, forType: .string)
                        } label: {
                            Label("Copy Error", systemImage: "doc.on.doc")
                        }
                        .secondaryButtonStyle()
                    }

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Error Callout - Full") {
    ErrorCalloutView(
        title: "Failed to Update Toolchain",
        message: "The update operation failed due to a network connection issue.",
        suggestion: "Check your internet connection and try again. You can also try updating from the terminal using 'rustup update'.",
        retryAction: { print("Retry tapped") },
        secondaryActionTitle: "Open Settings",
        secondaryAction: { print("Settings tapped") },
        errorDetails: "Error: Failed to download manifest\nExit code: 1\nstderr: connection timeout"
    )
    .padding(GlassTokens.Spacing.xl)
    .frame(width: 600)
}

#Preview("Error Callout - Minimal") {
    ErrorCalloutView(
        title: "Operation Failed",
        message: "An unexpected error occurred while processing your request.",
        retryAction: { print("Retry tapped") }
    )
    .padding(GlassTokens.Spacing.xl)
    .frame(width: 600)
    .preferredColorScheme(.dark)
}

#Preview("Error Callout - With Copy") {
    ErrorCalloutView(
        title: "Installation Failed",
        message: "Unable to install the nightly toolchain.",
        errorDetails: "rustup-init: command not found\nPath: /usr/local/bin/rustup"
    )
    .padding(GlassTokens.Spacing.xl)
    .frame(width: 600)
}
