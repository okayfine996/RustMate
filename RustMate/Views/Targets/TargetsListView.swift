//
//  TargetsListView.swift
//  RustMate
//
//  View for displaying and managing compilation targets for a toolchain
//  Feature: 004-glass-ui-refresh - Table layout redesign
//  Refactored to use ToolchainContextListView
//

import SwiftUI

struct TargetsListView: View {
    @StateObject private var viewModel = TargetsViewModel()
    @Binding var selectedToolchain: ToolchainInfo?

    var body: some View {
        ToolchainContextListView(
            viewModel: viewModel,
            selectedToolchain: $selectedToolchain,
            configuration: TargetsListConfiguration.configuration,
            rowBuilder: { target, onInstall, onUninstall in
                TargetTableRow(
                    target: target,
                    onInstall: onInstall,
                    onUninstall: onUninstall
                )
            },
            searchFilter: { target, searchText in
                target.triple.localizedCaseInsensitiveContains(searchText) ||
                (target.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            },
            onInstall: { target in
                await viewModel.installTarget(target)
            },
            onUninstall: { target in
                await viewModel.uninstallTarget(target)
            },
            tableHeaderBuilder: {
                AnyView(TargetsTableHeader())
            }
        )
    }
}

// MARK: - Filter

enum TargetFilter: String, CaseIterable, Hashable, ToolchainContextFilter {
    case all = "All"
    case installed = "Installed"
    case available = "Available"
}

// MARK: - Configuration

struct TargetsListConfiguration {
    static let configuration = ToolchainContextListConfiguration<TargetFilter>(
        title: "Targets",
        icon: "target",
        emptyStateIcon: "target",
        emptyStateTitle: "No Targets",
        emptyStateDescription: "No compilation targets found for this toolchain.",
        searchPlaceholder: "Search targets (e.g., wasm32, android)...",
        loadingMessage: "Loading targets...",
        filterDisplayName: { filter in
            switch filter {
            case .all: return "All"
            case .installed: return "Installed"
            case .available: return "Available"
            }
        },
        contentDescription: { toolchain in
            let channelName = toolchain.name.components(separatedBy: "-").first ?? "stable"
            return "Manage compilation targets for the \(channelName) channel. Add standard library support for cross-compilation."
        }
    )
}

// MARK: - Table Header

struct TargetsTableHeader: View {
    var body: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // TARGET NAME column
            Text("TARGET NAME")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // STATUS column
            Text("STATUS")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(width: 150, alignment: .leading)

            // ACTION column
            Text("ACTION")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, GlassTokens.Spacing.md)
        .padding(.vertical, GlassTokens.Spacing.sm)
        .background(GlassTokens.Colors.cardBackground.opacity(0.3))
    }
}

// MARK: - Target Table Row

struct TargetTableRow: View {
    let target: TargetInfo
    let onInstall: () -> Void
    let onUninstall: () -> Void

    var body: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // TARGET NAME column
            HStack(spacing: GlassTokens.Spacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            StatusSemantics.componentColor(isInstalled: target.isInstalled)
                                .opacity(0.15)
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "cpu.fill")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(StatusSemantics.componentColor(isInstalled: target.isInstalled))
                }

                // Name and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(target.triple)
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium, design: .monospaced))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    if let description = target.description {
                        Text(description)
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // STATUS column
            HStack(spacing: GlassTokens.Spacing.xs) {
                if target.isInstalled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.success)

                    Text("Installed")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.success)
                } else {
                    Text("Available")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                        .padding(.horizontal, GlassTokens.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(GlassTokens.Colors.cardBackground)
                        .cornerRadius(GlassTokens.Radius.sm)
                }
            }
            .frame(width: 150, alignment: .leading)

            // ACTION column
            HStack {
                Spacer()
                if target.isInstalled {
                    // No button for installed (could add uninstall if needed)
                    EmptyView()
                } else {
                    Button {
                        onInstall()
                    } label: {
                        HStack(spacing: GlassTokens.Spacing.xs) {
                            Image(systemName: "arrow.down.circle")
                            Text("Install")
                        }
                        .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                    }
                    .primaryGlassButtonStyle()
                    .controlSize(.small)
                }
            }
            .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, GlassTokens.Spacing.md)
        .padding(.vertical, GlassTokens.Spacing.md)
        .contentShape(Rectangle())
    }
}

// MARK: - Previews

#Preview {
    let toolchain = ToolchainInfo(
        name: "stable-aarch64-apple-darwin",
        version: "1.75.0",
        isDefault: true,
        installDate: Date(),
        host: "aarch64-apple-darwin"
    )

    return NavigationStack {
        TargetsListView(selectedToolchain: .constant(toolchain))
    }
}
