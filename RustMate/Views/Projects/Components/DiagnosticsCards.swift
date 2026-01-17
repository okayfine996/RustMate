//
//  DiagnosticsCards.swift
//  RustMate
//
//  Diagnostic cards for project diagnostics view
//

import SwiftUI

// MARK: - Project Config Card

struct ProjectConfigCard: View {
    let diagnostics: ProjectDiagnostics

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.accent)
                Text("PROJECT CONFIG")
                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .tracking(0.5)
            }

            if let version = diagnostics.configuredVersion {
                Text(version)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            } else {
                Text("Not configured")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }

            HStack(spacing: GlassTokens.Spacing.xs) {
                Text("Source:")
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)

                Button {
                    // Open rust-toolchain.toml
                } label: {
                    Text("rust-toolchain.toml")
                        .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                        .foregroundColor(GlassTokens.Colors.accent)
                        .padding(.horizontal, GlassTokens.Spacing.sm)
                        .padding(.vertical, GlassTokens.Spacing.xs)
                        .background(GlassTokens.Colors.accentSubtle)
                        .cornerRadius(GlassTokens.Radius.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlassTokens.Spacing.xl)
        .background(GlassTokens.Colors.cardBackground)
        .cornerRadius(GlassTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.lg)
                .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
        )
        .overlay(
            Image(systemName: "doc.text.fill")
                .font(.system(size: 80))
                .foregroundColor(GlassTokens.Colors.backgroundSecondary)
                .opacity(0.3),
            alignment: .trailing
        )
    }
}

// MARK: - Active Environment Card

struct ActiveEnvironmentCard: View {
    let diagnostics: ProjectDiagnostics

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(.orange)
                Text("ACTIVE ENVIRONMENT")
                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .tracking(0.5)
            }

            HStack(alignment: .firstTextBaseline, spacing: GlassTokens.Spacing.xs) {
                if let version = diagnostics.actualToolchainVersion ?? diagnostics.overrideVersion {
                    Text(version)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                } else {
                    Text("Not set")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }

                if diagnostics.hasMismatch {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                }
            }

            HStack(spacing: GlassTokens.Spacing.xs) {
                Text("Source:")
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)

                Button {
                    // Show source info
                } label: {
                    Text(diagnostics.toolchainSource.displayText)
                        .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                        .foregroundColor(GlassTokens.Colors.accent)
                        .padding(.horizontal, GlassTokens.Spacing.sm)
                        .padding(.vertical, GlassTokens.Spacing.xs)
                        .background(GlassTokens.Colors.accentSubtle)
                        .cornerRadius(GlassTokens.Radius.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlassTokens.Spacing.xl)
        .background(GlassTokens.Colors.cardBackground)
        .cornerRadius(GlassTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.lg)
                .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
        )
        .overlay(
            Image(systemName: "terminal.fill")
                .font(.system(size: 80))
                .foregroundColor(GlassTokens.Colors.backgroundSecondary)
                .opacity(0.3),
            alignment: .trailing
        )
    }
}

// MARK: - Conflict Alert Banner

struct ConflictAlertBanner: View {
    @Binding var isVisible: Bool

    var body: some View {
        HStack(alignment: .top, spacing: GlassTokens.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text("Environment Conflict Detected")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text("The active toolchain in your environment does not match the project configuration defined in `rust-toolchain.toml`. This may lead to inconsistent build artifacts.")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }

            Spacer()

            Button {
                withAnimation {
                    isVisible = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(GlassTokens.Spacing.lg)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(GlassTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                .stroke(Color.yellow.opacity(0.3), lineWidth: GlassTokens.Stroke.thin)
        )
    }
}

// MARK: - Override Alert Banner

struct OverrideAlertBanner: View {
    let diagnostics: ProjectDiagnostics
    let isLoading: Bool
    let onFix: () async -> Void

    var body: some View {
        HStack(alignment: .top, spacing: GlassTokens.Spacing.md) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 20))
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text("Directory override active")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text("A manual `rustup override` is forcing a nightly toolchain.")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }

            Spacer()

            Button {
                Task {
                    await onFix()
                }
            } label: {
                HStack(spacing: GlassTokens.Spacing.xs) {
                    Image(systemName: "trash")
                    Text("Clear Override")
                }
                .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, GlassTokens.Spacing.md)
                .padding(.vertical, GlassTokens.Spacing.sm)
                .background(Color.red)
                .cornerRadius(GlassTokens.Radius.md)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(GlassTokens.Spacing.lg)
        .background(Color.red.opacity(0.1))
        .cornerRadius(GlassTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                .stroke(Color.red.opacity(0.3), lineWidth: GlassTokens.Stroke.thin)
        )
    }
}
