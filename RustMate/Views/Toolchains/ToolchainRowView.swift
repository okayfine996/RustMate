//
//  ToolchainRowView.swift
//  RustMate
//
//  Row view for displaying toolchain information
//

import SwiftUI

struct ToolchainRowView: View {
    let toolchain: ToolchainInfo
    let onSetDefault: () -> Void
    let onUpdate: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(
                        StatusSemantics.toolchainColor(isDefault: toolchain.isDefault, hasUpdate: false)
                            .opacity(0.15)
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: StatusSemantics.toolchainIcon(isDefault: toolchain.isDefault))
                    .font(.system(size: GlassTokens.Typography.headlineSize))
                    .foregroundColor(StatusSemantics.toolchainColor(isDefault: toolchain.isDefault, hasUpdate: false))
            }

            // Content
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Text(toolchain.name)
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    if let badge = StatusSemantics.toolchainBadge(isDefault: toolchain.isDefault, hasUpdate: false) {
                        StatusBadgeView(status: badge.status, text: badge.text)
                    }
                }

                HStack(spacing: GlassTokens.Spacing.md) {
                    if let version = toolchain.version {
                        Label(version, systemImage: "tag")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }

                    if let host = toolchain.host {
                        Label(host, systemImage: "cpu")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }

                    if let date = toolchain.installDate {
                        Label(formatDate(date), systemImage: "calendar")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                }
            }

            Spacer()

            // Actions (show on hover)
            if isHovering {
                HStack(spacing: GlassTokens.Spacing.sm) {
                    if !toolchain.isDefault {
                        Button {
                            onSetDefault()
                        } label: {
                            Label("Set Default", systemImage: "star.fill")
                                .font(.system(size: GlassTokens.Typography.captionSize))
                        }
                        .secondaryGlassButtonStyle()
                        .controlSize(.small)
                    }

                    if canUpdateToolchain(toolchain) {
                        Button {
                            onUpdate()
                        } label: {
                            Label("Update", systemImage: "arrow.clockwise")
                                .font(.system(size: GlassTokens.Typography.captionSize))
                        }
                        .secondaryGlassButtonStyle()
                        .controlSize(.small)
                    }

                    if !toolchain.isDefault {
                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: GlassTokens.Typography.captionSize))
                        }
                        .destructiveGlassButtonStyle()
                        .controlSize(.small)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.vertical, GlassTokens.Spacing.sm)
        .padding(.horizontal, GlassTokens.Spacing.md)
        .background(isHovering ? GlassTokens.Colors.cardBackground : Color.clear)
        .cornerRadius(GlassTokens.Radius.md)
        .onHover { hovering in
            withAnimation(GlassTokens.Animation.fast) {
                isHovering = hovering
            }
        }
        .contextMenu {
            if !toolchain.isDefault {
                Button {
                    onSetDefault()
                } label: {
                    Label("Set as Default", systemImage: "star.fill")
                }
            }

            if canUpdateToolchain(toolchain) {
                Button {
                    onUpdate()
                } label: {
                    Label("Update", systemImage: "arrow.clockwise")
                }
            }

            Divider()

            if !toolchain.isDefault {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Uninstall", systemImage: "trash")
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Check if a toolchain can be updated
    /// Fixed version toolchains (e.g., 1.75.0-aarch64-apple-darwin) cannot be updated
    /// Only channel-based toolchains (stable, beta, nightly) can be updated
    private func canUpdateToolchain(_ toolchain: ToolchainInfo) -> Bool {
        let name = toolchain.name
        let components = name.split(separator: "-")
        guard !components.isEmpty else { return false }
        
        let firstComponent = String(components[0])
        
        // If the first component starts with a digit, it's a fixed version toolchain
        // Fixed version toolchains cannot be updated
        if firstComponent.first?.isNumber == true {
            return false
        }
        
        // Channel-based toolchains (stable, beta, nightly) can be updated
        return firstComponent == "stable" || firstComponent == "beta" || firstComponent == "nightly"
    }
}

// MARK: - Previews

#Preview("Default Toolchain") {
    ToolchainRowView(
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
    .padding()
}

#Preview("Non-Default Toolchain") {
    ToolchainRowView(
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
    .padding()
}

#Preview("Minimal Info") {
    ToolchainRowView(
        toolchain: ToolchainInfo(
            id: UUID(),
            name: "beta",
            version: nil,
            isDefault: false,
            installDate: nil,
            host: nil
        ),
        onSetDefault: {},
        onUpdate: {},
        onDelete: {}
    )
    .padding()
}
