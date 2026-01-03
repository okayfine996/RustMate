//
//  InlineProgressView.swift
//  RustMate
//
//  Created by Speckit on 2026-01-02.
//  Feature: 004-glass-ui-refresh
//

import SwiftUI

/// Inline progress indicator for running tasks
/// Shows progress without blocking the UI or taking up significant space
struct InlineProgressView: View {
    let message: String?

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        HStack(spacing: GlassTokens.Spacing.sm) {
            if reduceMotion {
                Image(systemName: "arrow.trianglehead.clockwise")
                    .font(.system(size: GlassTokens.Typography.calloutSize))
                    .foregroundColor(GlassTokens.Colors.info)
            } else {
                ProgressView()
                    .controlSize(.small)
            }

            if let message = message {
                Text(message)
                    .font(.system(size: GlassTokens.Typography.calloutSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "In progress")
    }
}

// MARK: - Previews

#Preview("Inline Progress") {
    VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    Text("stable-aarch64-apple-darwin")
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    InlineProgressView(message: "Updating...")
                }

                Spacer()

                Button("Cancel") {}
                    .secondaryButtonStyle()
            }
        }

        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    Text("nightly-aarch64-apple-darwin")
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    InlineProgressView(message: "Installing...")
                }

                Spacer()
            }
        }

        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    Text("Processing")
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    InlineProgressView()
                }

                Spacer()
            }
        }
    }
    .padding(GlassTokens.Spacing.xl)
    .frame(width: 500)
}

#Preview("Inline Progress - Dark") {
    VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    Text("stable-aarch64-apple-darwin")
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    InlineProgressView(message: "Updating...")
                }

                Spacer()

                Button("Cancel") {}
                    .secondaryButtonStyle()
            }
        }
    }
    .padding(GlassTokens.Spacing.xl)
    .frame(width: 500)
    .preferredColorScheme(.dark)
}
