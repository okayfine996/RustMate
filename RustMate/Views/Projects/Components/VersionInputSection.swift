//
//  VersionInputSection.swift
//  RustMate
//
//  Version input section for project toolchain settings
//

import SwiftUI

struct VersionInputSection: View {
    @ObservedObject var viewModel: ProjectToolchainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            Text("Specific Version (Optional)")
                .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            Text("The toolchain version to use. Leave empty to use the latest version of the selected channel.")
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textSecondary)

            TextField("1.75.0", text: Binding(
                get: { viewModel.config?.version ?? "" },
                set: { newValue in
                    viewModel.updateVersion(newValue.isEmpty ? nil : newValue)
                    if !newValue.isEmpty && !viewModel.validateVersion(newValue) {
                        // Validation error will be handled by viewModel.saveConfig()
                    }
                }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
            .padding(GlassTokens.Spacing.md)
            .background(GlassTokens.Colors.backgroundSecondary)
            .cornerRadius(GlassTokens.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: GlassTokens.Radius.sm)
                    .stroke(
                        viewModel.config?.version != nil && !viewModel.validateVersion(viewModel.config?.version ?? "")
                            ? GlassTokens.Colors.error
                            : GlassTokens.Colors.divider,
                        lineWidth: GlassTokens.Stroke.thin
                    )
            )
        }
    }
}
