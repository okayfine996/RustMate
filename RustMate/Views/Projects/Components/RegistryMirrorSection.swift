//
//  RegistryMirrorSection.swift
//  RustMate
//
//  Registry mirror selection section for Cargo settings
//

import SwiftUI

struct RegistryMirrorSection: View {
    @ObservedObject var viewModel: ProjectCargoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            Text("Registry Mirror")
                .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                Text("Select the crate source registry to optimize download speeds.")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)

                HStack(spacing: GlassTokens.Spacing.md) {
                    ForEach([
                        ProjectCargoConfig.RegistryMirror.cratesIo,
                        .tsinghua,
                        .ustc,
                        .byteDance
                    ], id: \.self) { mirror in
                        registryMirrorButton(mirror: mirror)
                    }
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
    }

    // MARK: - Registry Mirror Button

    @ViewBuilder
    private func registryMirrorButton(mirror: ProjectCargoConfig.RegistryMirror) -> some View {
        let isSelected = viewModel.config?.registryMirror == mirror ||
                        (mirror == .cratesIo && viewModel.config?.registryMirror == nil)

        Button {
            viewModel.updateRegistryMirror(mirror == .cratesIo ? nil : mirror)
        } label: {
            VStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: mirror.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : GlassTokens.Colors.textPrimary)

                Text(mirror.displayText)
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    .foregroundColor(isSelected ? .white : GlassTokens.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(GlassTokens.Spacing.md)
            .background(isSelected ? GlassTokens.Colors.accent : GlassTokens.Colors.backgroundSecondary)
            .cornerRadius(GlassTokens.Radius.md)
        }
        .buttonStyle(.plain)
    }
}
