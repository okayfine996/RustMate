//
//  ResolutionPathSection.swift
//  RustMate
//
//  Toolchain resolution path section for diagnostics
//

import SwiftUI

struct ResolutionPathSection: View {
    let diagnostics: ProjectDiagnostics

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Header
            HStack {
                Text("Resolution Path")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Spacer()

                Button("Priority Order") {
                    // Show priority info
                }
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                .foregroundColor(GlassTokens.Colors.accent)
                .padding(.horizontal, GlassTokens.Spacing.sm)
                .padding(.vertical, GlassTokens.Spacing.xs)
                .background(GlassTokens.Colors.accentSubtle)
                .cornerRadius(GlassTokens.Radius.sm)
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 0) {
                // Shell Environment
                resolutionPathItem(
                    title: "Shell Environment",
                    value: diagnostics.toolchainSource == .environment ? (diagnostics.actualToolchainVersion ?? "Set") : "Not set",
                    badge: "RUSTUP_TOOLCHAIN",
                    isActive: diagnostics.toolchainSource == .environment,
                    showDivider: true
                )

                // Directory Override
                resolutionPathItem(
                    title: "Directory Override",
                    value: diagnostics.toolchainSource == .override ? (diagnostics.overrideVersion ?? diagnostics.actualToolchainVersion ?? "Set") : nil,
                    badge: diagnostics.toolchainSource == .override ? "Winning" : nil,
                    isActive: diagnostics.toolchainSource == .override,
                    showDivider: true,
                    isWinning: diagnostics.toolchainSource == .override
                )

                // rust-toolchain.toml
                resolutionPathItem(
                    title: "rust-toolchain.toml",
                    value: diagnostics.configuredVersion != nil ? "\(diagnostics.configuredVersion ?? "")\(diagnostics.toolchainSource == .override ? " (Ignored due to override)" : "")" : nil,
                    badge: "Project Config",
                    isActive: diagnostics.toolchainSource == .toolchainFile,
                    showDivider: true,
                    isIgnored: diagnostics.toolchainSource == .override && diagnostics.configuredVersion != nil
                )

                // Global Default
                resolutionPathItem(
                    title: "Global Default",
                    value: diagnostics.toolchainSource == .default ? "stable" : "stable",
                    badge: "rustup default",
                    isActive: diagnostics.toolchainSource == .default,
                    showDivider: false
                )
            }
        }
        .padding(GlassTokens.Spacing.lg)
        .background(GlassTokens.Colors.cardBackground)
        .cornerRadius(GlassTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.lg)
                .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
        )
    }

    // MARK: - Resolution Path Item

    @ViewBuilder
    private func resolutionPathItem(
        title: String,
        value: String?,
        badge: String?,
        isActive: Bool,
        showDivider: Bool,
        isWinning: Bool = false,
        isIgnored: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: GlassTokens.Spacing.md) {
                // Radio button indicator
                ZStack {
                    Circle()
                        .fill(isActive ? GlassTokens.Colors.accent : Color.clear)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(isActive ? GlassTokens.Colors.accent : GlassTokens.Colors.textTertiary, lineWidth: 2)
                        )

                    if isActive {
                        Circle()
                            .fill(.white)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(width: 20)

                // Content
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    HStack {
                        Text(title)
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                            .foregroundColor(isActive ? GlassTokens.Colors.textPrimary : GlassTokens.Colors.textSecondary)

                        Spacer()

                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                                .foregroundColor(isWinning ? .white : GlassTokens.Colors.textSecondary)
                                .padding(.horizontal, GlassTokens.Spacing.sm)
                                .padding(.vertical, 2)
                                .background(isWinning ? GlassTokens.Colors.accent : GlassTokens.Colors.backgroundSecondary)
                                .cornerRadius(GlassTokens.Radius.sm)
                        }
                    }

                    if let value = value {
                        Text(value)
                            .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                            .foregroundColor(isIgnored ? GlassTokens.Colors.textSecondary : GlassTokens.Colors.textPrimary)
                    }
                }
            }
            .padding(.vertical, GlassTokens.Spacing.md)

            if showDivider {
                Divider()
                    .padding(.leading, 40)
            }
        }
    }
}

// MARK: - Conflict Alert Banner

struct DiagnosticsConflictBanner: View {
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
