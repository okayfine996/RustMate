//
//  ChannelSelectionSection.swift
//  RustMate
//
//  Channel selection section for project toolchain settings
//

import SwiftUI

struct ChannelSelectionSection: View {
    @ObservedObject var viewModel: ProjectToolchainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Header
            HStack {
                Text("Channel")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Spacer()

                Button {
                    openDistributionHistory()
                } label: {
                    Text("View distribution history")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.accent)
                }
                .buttonStyle(.plain)
            }

            // Channel cards
            HStack(spacing: GlassTokens.Spacing.md) {
                channelCard(
                    channel: .stable,
                    title: "Stable",
                    description: "Recommended for production",
                    icon: "checkmark.circle.fill"
                )

                channelCard(
                    channel: .beta,
                    title: "Beta",
                    description: "Preview upcoming features",
                    icon: "flask.fill"
                )

                channelCard(
                    channel: .nightly,
                    title: "Nightly",
                    description: "Experimental daily builds",
                    icon: "moon.fill"
                )
            }
        }
    }

    // MARK: - Channel Card

    @ViewBuilder
    private func channelCard(
        channel: ProjectToolchainConfig.ToolchainChannel,
        title: String,
        description: String,
        icon: String
    ) -> some View {
        let isSelected = viewModel.config?.channel == channel

        Button {
            viewModel.updateChannel(channel)
        } label: {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                // Top right checkmark for selected state
                HStack {
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: GlassTokens.Typography.headlineSize))
                            .foregroundColor(GlassTokens.Colors.accent)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: GlassTokens.Typography.headlineSize))
                            .foregroundColor(.clear)
                    }
                }

                // Icon
                HStack {
                    ZStack {
                        Circle()
                            .fill(isSelected ? GlassTokens.Colors.accent.opacity(0.2) : GlassTokens.Colors.backgroundSecondary)
                            .frame(width: 48, height: 48)

                        Image(systemName: icon)
                            .font(.system(size: GlassTokens.Typography.titleSize))
                            .foregroundColor(isSelected ? GlassTokens.Colors.accent : GlassTokens.Colors.textSecondary)
                    }

                    Spacer()
                }

                // Title
                Text(title)
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                // Description
                Text(description)
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(GlassTokens.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
            .background(
                isSelected
                    ? GlassTokens.Colors.selectionBackground
                    : GlassTokens.Colors.cardBackground
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

    // MARK: - Helper

    private func openDistributionHistory() {
        guard let url = URL(string: "https://doc.rust-lang.org/beta/releases.html") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
