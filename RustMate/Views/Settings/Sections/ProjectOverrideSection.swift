//
//  ProjectOverrideSection.swift
//  RustMate
//
//  Project override strategy section for Settings
//

import SwiftUI

struct ProjectOverrideSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                Text("Project Override Strategy")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Picker("Method:", selection: $viewModel.overrideStrategy) {
                    Text("rust-toolchain.toml file").tag(AppSettings.OverrideStrategy.toolchainFile)
                    Text("rustup override command").tag(AppSettings.OverrideStrategy.rustupOverride)
                }
                .pickerStyle(.radioGroup)

                Text(viewModel.overrideStrategy == .toolchainFile
                    ? "Creates rust-toolchain.toml in project directory (can be committed to repo)"
                    : "Uses rustup override set/unset (doesn't modify project files)")
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
        }
    }
}
