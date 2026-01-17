//
//  ProjectBanners.swift
//  RustMate
//
//  Error and warning banners for project views
//

import SwiftUI

// MARK: - Error Banner

struct ProjectErrorBanner: View {
    let error: Error
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: GlassTokens.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(GlassTokens.Colors.error)

            VStack(alignment: .leading, spacing: 2) {
                Text("Error")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text(error.localizedDescription)
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(GlassTokens.Spacing.md)
        .background(GlassTokens.Colors.errorSubtle)
        .cornerRadius(GlassTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                .stroke(GlassTokens.Colors.error.opacity(0.3), lineWidth: GlassTokens.Stroke.thin)
        )
    }
}

// MARK: - Version Mismatch Banner

struct VersionMismatchBanner: View {
    let diagnostics: ProjectDiagnostics
    let projectPath: String
    let onFix: () async -> Void

    var body: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: GlassTokens.Typography.headlineSize))
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Version Mismatch")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                if let configured = diagnostics.configuredVersion,
                   let override = diagnostics.overrideVersion {
                    Text("Project requests \(configured), but local override is set to \(override).")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                } else if let configured = diagnostics.configuredVersion,
                          let actual = diagnostics.actualToolchainVersion {
                    Text("Project requests \(configured), but local override is set to \(actual).")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
            }

            Spacer()

            Button {
                Task {
                    await onFix()
                }
            } label: {
                Text("Fix Mismatch")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, GlassTokens.Spacing.md)
                    .padding(.vertical, GlassTokens.Spacing.sm)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(GlassTokens.Radius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(GlassTokens.Spacing.md)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(GlassTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                .stroke(Color.yellow.opacity(0.3), lineWidth: GlassTokens.Stroke.thin)
        )
    }
}
