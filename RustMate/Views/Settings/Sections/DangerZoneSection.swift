//
//  DangerZoneSection.swift
//  RustMate
//
//  Danger zone section for Settings (reset/destructive operations)
//

import SwiftUI

struct DangerZoneSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Header
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: GlassTokens.Typography.headlineSize))
                    .foregroundColor(.red)

                Text("Danger Zone")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            }

            // Reset Application subsection
            HStack(alignment: .top, spacing: GlassTokens.Spacing.lg) {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                    Text("Reset Application")
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    Text("This will delete all local configuration files and reset project defaults to their original state.")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)

                    Text("This action is irreversible.")
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                        .foregroundColor(.red)
                }

                Spacer()

                Button("Reset All Settings") {
                    viewModel.showResetConfirmation = true
                }
                .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, GlassTokens.Spacing.lg)
                .padding(.vertical, GlassTokens.Spacing.md)
                .background(Color.red)
                .cornerRadius(GlassTokens.Radius.md)
                .buttonStyle(.plain)
                .confirmationDialog(
                    "Reset all settings and permissions?",
                    isPresented: $viewModel.showResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset Everything", role: .destructive) {
                        viewModel.resetAllSettings()
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
        }
        .padding(GlassTokens.Spacing.lg)
        .background(Color.red.opacity(0.05))
        .cornerRadius(GlassTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.lg)
                .stroke(Color.red.opacity(0.2), lineWidth: GlassTokens.Stroke.thin)
        )
    }
}
