//
//  CargoAliasesSection.swift
//  RustMate
//
//  Cargo aliases section for Cargo settings
//

import SwiftUI

struct CargoAliasesSection: View {
    @ObservedObject var viewModel: ProjectCargoViewModel
    let onAddAlias: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Header
            HStack {
                Text("Cargo Aliases")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Spacer()

                Button("+ Add Alias") {
                    onAddAlias()
                }
                .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                .foregroundColor(GlassTokens.Colors.accent)
                .buttonStyle(.plain)
            }

            // Aliases list
            aliasesContent
        }
    }

    // MARK: - Aliases Content

    @ViewBuilder
    private var aliasesContent: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            if let aliases = viewModel.config?.aliases, !aliases.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    // Table headers
                    HStack(spacing: GlassTokens.Spacing.md) {
                        Text("ALIAS")
                            .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                            .frame(width: 100, alignment: .leading)

                        Text("COMMAND")
                            .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                            .foregroundColor(GlassTokens.Colors.textSecondary)

                        Spacer()
                    }
                    .padding(.horizontal, GlassTokens.Spacing.md)
                    .padding(.vertical, GlassTokens.Spacing.sm)
                    .background(GlassTokens.Colors.backgroundSecondary)

                    // Table rows
                    ForEach(Array(aliases.keys.sorted()), id: \.self) { alias in
                        aliasRow(alias: alias, command: aliases[alias] ?? "")
                    }
                }
                .cornerRadius(GlassTokens.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                        .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
                )
            } else {
                Text("No aliases configured")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .padding(GlassTokens.Spacing.md)
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

    // MARK: - Alias Row

    @ViewBuilder
    private func aliasRow(alias: String, command: String) -> some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            Text(alias)
                .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                .foregroundColor(GlassTokens.Colors.accent)
                .frame(width: 100, alignment: .leading)

            Text(command)
                .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            Spacer()

            Button {
                viewModel.removeAlias(alias)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, GlassTokens.Spacing.md)
        .padding(.vertical, GlassTokens.Spacing.sm)
        .background(GlassTokens.Colors.cardBackground)
    }
}
