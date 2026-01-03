//
//  ToolchainDetailView.swift
//  RustMate
//
//  Detail view showing toolchain metadata and operations
//

import SwiftUI

struct ToolchainDetailView: View {
    let toolchain: ToolchainInfo
    let onSetDefault: () -> Void
    let onUpdate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
                // Header
                GlassCard {
                    HStack(spacing: GlassTokens.Spacing.lg) {
                        ZStack {
                            Circle()
                                .fill(
                                    StatusSemantics.toolchainColor(isDefault: toolchain.isDefault, hasUpdate: false)
                                        .opacity(0.15)
                                )
                                .frame(width: 60, height: 60)

                            Image(systemName: StatusSemantics.toolchainIcon(isDefault: toolchain.isDefault))
                                .font(.system(size: 32))
                                .foregroundColor(StatusSemantics.toolchainColor(isDefault: toolchain.isDefault, hasUpdate: false))
                        }

                        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                            HStack(spacing: GlassTokens.Spacing.sm) {
                                Text(toolchain.name)
                                    .font(.system(size: GlassTokens.Typography.titleSize, weight: GlassTokens.Typography.titleWeight))
                                    .foregroundColor(GlassTokens.Colors.textPrimary)

                                if let badge = StatusSemantics.toolchainBadge(isDefault: toolchain.isDefault, hasUpdate: false) {
                                    StatusBadgeView(status: badge.status, text: badge.text)
                                }
                            }

                            if let version = toolchain.version {
                                Text("Version \(version)")
                                    .font(.system(size: GlassTokens.Typography.calloutSize))
                                    .foregroundColor(GlassTokens.Colors.textSecondary)
                            }
                        }
                    }
                }

                // Metadata
                GlassCard {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        Text("Toolchain Information")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        if let host = toolchain.host {
                            metadataRow(label: "Host Triple", value: host, icon: "cpu")
                        }

                        if let date = toolchain.installDate {
                            metadataRow(
                                label: "Installed",
                                value: formatDate(date),
                                icon: "calendar"
                            )
                        }

                        metadataRow(
                            label: "Status",
                            value: toolchain.isDefault ? "Active (Default)" : "Installed",
                            icon: "info.circle"
                        )
                    }
                }

                // Operations
                GlassCard {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        Text("Operations")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        if !toolchain.isDefault {
                            Button {
                                onSetDefault()
                            } label: {
                                HStack {
                                    Label("Set as Default", systemImage: "star.fill")
                                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: GlassTokens.Typography.captionSize))
                                        .foregroundColor(GlassTokens.Colors.textSecondary)
                                }
                                .padding(GlassTokens.Spacing.md)
                                .background(GlassTokens.Colors.accentSubtle)
                                .cornerRadius(GlassTokens.Radius.md)
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            onUpdate()
                        } label: {
                            HStack {
                                Label("Update Toolchain", systemImage: "arrow.clockwise")
                                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: GlassTokens.Typography.captionSize))
                                    .foregroundColor(GlassTokens.Colors.textSecondary)
                            }
                            .padding(GlassTokens.Spacing.md)
                            .background(GlassTokens.Colors.successSubtle)
                            .cornerRadius(GlassTokens.Radius.md)
                        }
                        .buttonStyle(.plain)

                        if !toolchain.isDefault {
                            Button {
                                onDelete()
                            } label: {
                                HStack {
                                    Label("Uninstall Toolchain", systemImage: "trash")
                                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: GlassTokens.Typography.captionSize))
                                        .foregroundColor(GlassTokens.Colors.textSecondary)
                                }
                                .padding(GlassTokens.Spacing.md)
                                .background(GlassTokens.Colors.errorSubtle)
                                .cornerRadius(GlassTokens.Radius.md)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(GlassTokens.Colors.error)
                        }
                    }
                }

                // Usage Info
                GlassCard {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        Text("Usage")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                            Text("Set as project override:")
                                .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                                .foregroundColor(GlassTokens.Colors.textPrimary)

                            Text("rustup override set \(toolchain.name)")
                                .font(.system(size: GlassTokens.Typography.captionSize, design: .monospaced))
                                .padding(GlassTokens.Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(GlassTokens.Colors.cardBackground)
                                .cornerRadius(GlassTokens.Radius.sm)

                            Text("Or add to rust-toolchain.toml:")
                                .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                                .foregroundColor(GlassTokens.Colors.textPrimary)
                                .padding(.top, GlassTokens.Spacing.xs)

                            Text("[toolchain]\nchannel = \"\(toolchain.name)\"")
                                .font(.system(size: GlassTokens.Typography.captionSize, design: .monospaced))
                                .padding(GlassTokens.Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(GlassTokens.Colors.cardBackground)
                                .cornerRadius(GlassTokens.Radius.sm)
                        }
                    }
                }

                Spacer()
            }
            .padding(GlassTokens.Spacing.xl)
        }
        .navigationTitle(toolchain.name)
        .navigationSubtitle(toolchain.isDefault ? "Default Toolchain" : "Installed Toolchain")
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func metadataRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: GlassTokens.Typography.headlineSize))
                .foregroundColor(GlassTokens.Colors.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text(label)
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)

                Text(value)
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            }

            Spacer()
        }
        .padding(GlassTokens.Spacing.md)
        .background(GlassTokens.Colors.cardBackground.opacity(0.5))
        .cornerRadius(GlassTokens.Radius.sm)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview("Default Toolchain") {
    NavigationStack {
        ToolchainDetailView(
            toolchain: ToolchainInfo(
                id: UUID(),
                name: "stable-aarch64-apple-darwin",
                version: "1.75.0",
                isDefault: true,
                installDate: Date().addingTimeInterval(-86400 * 30),
                host: "aarch64-apple-darwin"
            ),
            onSetDefault: {},
            onUpdate: {},
            onDelete: {}
        )
    }
}

#Preview("Non-Default Toolchain") {
    NavigationStack {
        ToolchainDetailView(
            toolchain: ToolchainInfo(
                id: UUID(),
                name: "nightly-aarch64-apple-darwin",
                version: "1.77.0-nightly",
                isDefault: false,
                installDate: Date().addingTimeInterval(-86400 * 7),
                host: "aarch64-apple-darwin"
            ),
            onSetDefault: {},
            onUpdate: {},
            onDelete: {}
        )
    }
}
