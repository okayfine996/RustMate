//
//  RustflagsSection.swift
//  RustMate
//
//  Rustflags section for Cargo settings
//

import SwiftUI

struct RustflagsSection: View {
    @ObservedObject var viewModel: ProjectCargoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            Text("Rustflags")
                .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                Text("Custom compiler flags passed to rustc. Separate multiple flags with spaces.")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)

                TextEditor(text: Binding(
                    get: { viewModel.config?.rustflags ?? "" },
                    set: { viewModel.updateRustflags($0.isEmpty ? nil : $0) }
                ))
                .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                .frame(height: 120)
                .padding(GlassTokens.Spacing.sm)
                .background(GlassTokens.Colors.backgroundSecondary)
                .cornerRadius(GlassTokens.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                        .stroke(GlassTokens.Colors.divider, lineWidth: GlassTokens.Stroke.thin)
                )
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
}
