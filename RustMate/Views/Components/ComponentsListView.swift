//
//  ComponentsListView.swift
//  RustMate
//
//  View for displaying and managing components for a toolchain
//  Feature: 004-glass-ui-refresh - Table layout redesign
//  Refactored to use ToolchainContextListView
//

import SwiftUI

struct ComponentsListView: View {
    @StateObject private var viewModel = ComponentsViewModel()
    @Binding var selectedToolchain: ToolchainInfo?

    var body: some View {
        ToolchainContextListView(
            viewModel: viewModel,
            selectedToolchain: $selectedToolchain,
            configuration: ComponentsListConfiguration.configuration,
            rowBuilder: { component, onInstall, onUninstall in
                ComponentTableRow(
                    component: component,
                    onInstall: onInstall,
                    onUninstall: onUninstall
                )
            },
            searchFilter: { component, searchText in
                component.displayName.localizedCaseInsensitiveContains(searchText) ||
                component.name.localizedCaseInsensitiveContains(searchText)
            },
            onInstall: { component in
                await viewModel.installComponent(component)
            },
            onUninstall: { component in
                await viewModel.uninstallComponent(component)
            },
            tableHeaderBuilder: {
                AnyView(ComponentsTableHeader())
            }
        )
    }
}

// MARK: - Filter

enum ComponentFilter: String, CaseIterable, Hashable, ToolchainContextFilter {
    case all = "All"
    case installed = "Installed"
    case available = "Available"
}

// MARK: - Configuration

struct ComponentsListConfiguration {
    static let configuration = ToolchainContextListConfiguration<ComponentFilter>(
        title: "Components",
        icon: "puzzlepiece.extension",
        emptyStateIcon: "puzzlepiece.extension",
        emptyStateTitle: "No Components",
        emptyStateDescription: "No components found for this toolchain.",
        searchPlaceholder: "Search components...",
        loadingMessage: "Loading components...",
        filterDisplayName: { filter in
            switch filter {
            case .all: return "All"
            case .installed: return "Installed"
            case .available: return "Available"
            }
        },
        contentDescription: { toolchain in
            let channelName = toolchain.name.components(separatedBy: "-").first ?? "stable"
            return "Manage components for the \(channelName) channel. Add tools like rustfmt, clippy, and rust-src."
        }
    )
}

// MARK: - Table Header

struct ComponentsTableHeader: View {
    var body: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // NAME column (flexible width)
            Text("NAME")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // TYPE column (fixed width)
            Text("TYPE")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(width: 120, alignment: .leading)

            // STATUS column (fixed width)
            Text("STATUS")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(width: 120, alignment: .leading)

            // ACTION column (fixed width)
            Text("ACTION")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, GlassTokens.Spacing.md)
        .padding(.vertical, GlassTokens.Spacing.sm)
        .background(GlassTokens.Colors.cardBackground.opacity(0.3))
    }
}

// MARK: - Component Table Row

struct ComponentTableRow: View {
    let component: ComponentInfo
    let onInstall: () -> Void
    let onUninstall: () -> Void

    var body: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // NAME column (flexible width)
            HStack(spacing: GlassTokens.Spacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            StatusSemantics.componentColor(isInstalled: component.isInstalled)
                                .opacity(0.15)
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "puzzlepiece.extension.fill")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(StatusSemantics.componentColor(isInstalled: component.isInstalled))
                }

                // Name and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(component.displayName)
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    if let description = component.description {
                        Text(description)
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // TYPE column (fixed width)
            Text("Component")
                .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(width: 120, alignment: .leading)

            // STATUS column (fixed width)
            HStack(spacing: GlassTokens.Spacing.xs) {
                let badge = StatusSemantics.componentBadge(isInstalled: component.isInstalled)
                StatusBadgeView(status: badge.status, text: badge.text)
            }
            .frame(width: 120, alignment: .leading)

            // ACTION column (fixed width)
            HStack {
                Spacer()
                if component.isInstalled {
                    Button {
                        onUninstall()
                    } label: {
                        Text("Uninstall")
                            .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                    }
                    .secondaryGlassButtonStyle()
                    .controlSize(.small)
                } else {
                    Button {
                        onInstall()
                    } label: {
                        Text("Install")
                            .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                    }
                    .primaryGlassButtonStyle()
                    .controlSize(.small)
                }
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, GlassTokens.Spacing.lg)
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
        ComponentsListView(selectedToolchain: .constant(toolchain))
    }
}
