//
//  ProfileSelectionSection.swift
//  RustMate
//
//  Profile selection section for project toolchain settings
//

import SwiftUI

struct ProfileSelectionSection: View {
    @ObservedObject var viewModel: ProjectToolchainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            Text("Profile")
                .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            HStack(spacing: GlassTokens.Spacing.md) {
                profileCard(.minimal)
                profileCard(.default)
                profileCard(.complete)
            }
        }
    }

    // MARK: - Profile Card

    @ViewBuilder
    private func profileCard(_ profile: ProjectToolchainConfig.ToolchainProfile) -> some View {
        let isSelected = viewModel.config?.profile == profile

        Button {
            viewModel.updateProfile(profile)
        } label: {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                // Top row: icon and selection indicator
                HStack {
                    Image(systemName: profile.icon)
                        .font(.system(size: GlassTokens.Typography.titleSize))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    Spacer()

                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: GlassTokens.Typography.headlineSize))
                            .foregroundColor(GlassTokens.Colors.accent)
                    } else {
                        Circle()
                            .stroke(GlassTokens.Colors.textTertiary, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                    }
                }

                // Title
                Text(profile.displayText)
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                // Description
                Text(profile.description)
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(isSelected ? GlassTokens.Colors.accent : GlassTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(GlassTokens.Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(
                isSelected
                    ? GlassTokens.Colors.accent.opacity(0.15)
                    : GlassTokens.Colors.backgroundSecondary
            )
            .cornerRadius(GlassTokens.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                    .stroke(
                        isSelected ? GlassTokens.Colors.accent : GlassTokens.Colors.divider,
                        lineWidth: isSelected ? 2 : GlassTokens.Stroke.thin
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
