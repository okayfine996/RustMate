//
//  RustupConfigurationSection.swift
//  RustMate
//
//  Rustup configuration section for Settings
//  Extracted from SettingsView to reduce complexity
//

import SwiftUI

struct RustupConfigurationSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Header
            Text("Rustup Configuration")
                .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            GlassCard {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                    // Rustup Binary Path
                    rustupBinaryPathRow

                    // Rustup Version and Check for Updates button
                    rustupVersionRow
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var rustupBinaryPathRow: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
            Text("Rustup Binary Path")
                .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            HStack(spacing: GlassTokens.Spacing.sm) {
                TextField("", text: $viewModel.rustupPath)
                    .textFieldStyle(.plain)
                    .padding(GlassTokens.Spacing.sm)
                    .background(GlassTokens.Colors.backgroundSecondary)
                    .cornerRadius(GlassTokens.Radius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                            .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
                    )

                Button {
                    viewModel.browseForRustup()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var rustupVersionRow: some View {
        HStack {
            // Rustup Version
            if let rustupVersion = viewModel.rustupVersion {
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(.green)

                    Text("Rustup: \(rustupVersion)")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                }
            }

            Spacer()

            // Check for Updates button
            Button {
                viewModel.checkForRustupUpdates()
            } label: {
                HStack(spacing: GlassTokens.Spacing.xs) {
                    if viewModel.isCheckingUpdates {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: GlassTokens.Typography.bodySize))
                            .frame(width: 16, height: 16)
                    }
                    Text("Check for Updates")
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, GlassTokens.Spacing.lg)
                .padding(.vertical, GlassTokens.Spacing.md)
                .background(GlassTokens.Colors.accent)
                .cornerRadius(GlassTokens.Radius.md)
                .frame(minWidth: 160)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isCheckingUpdates)
        }
    }
}
