//
//  ProjectContextView.swift
//  RustMate
//
//  Detailed view showing project toolchain context and override management
//  Feature: 004-glass-ui-refresh - Priority-based configuration layout
//  Refactored: Extracted components for better organization
//

import SwiftUI

struct ProjectContextView: View {
    let context: ProjectContextInfo
    let availableToolchains: [ToolchainInfo]
    let onSetOverride: (ToolchainInfo) -> Void
    let onClearOverride: () -> Void

    @State private var selectedTab: ProjectTab = .toolchain
    @StateObject private var diagnosticsViewModel = ProjectDiagnosticsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Project header
            ProjectHeader(
                projectPath: context.projectPath,
                title: headerTitle,
                description: headerDescription
            )
            .padding(GlassTokens.Spacing.xl)

            Divider()

            // Tab selector
            ProjectTabSelector(
                selectedTab: $selectedTab,
                issueCount: diagnosticsViewModel.issueCount
            )

            Divider()

            // Tab content
            tabContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            await diagnosticsViewModel.loadDiagnostics(projectPath: context.projectPath)
        }
        .onChange(of: context.projectPath) { _, newPath in
            Task {
                await diagnosticsViewModel.loadDiagnostics(projectPath: newPath)
            }
        }
        .onChange(of: selectedTab) { _, _ in
            if selectedTab == .info {
                Task {
                    await diagnosticsViewModel.loadDiagnostics(projectPath: context.projectPath)
                }
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .toolchain:
                ProjectToolchainSettingsView(projectPath: context.projectPath)
            case .cargo:
                ProjectCargoSettingsView(projectPath: context.projectPath)
            case .info:
                ProjectDiagnosticsView(projectPath: context.projectPath)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header Text

    private var headerTitle: String {
        switch selectedTab {
        case .toolchain: return "Toolchain Settings"
        case .cargo: return "Cargo & Build Settings"
        case .info: return "Project Diagnostics"
        }
    }

    private var headerDescription: String {
        switch selectedTab {
        case .toolchain: return "Configure the Rust environment for `rust-toolchain.toml`"
        case .cargo: return "Configure build settings for `.cargo/config.toml`"
        case .info: return "View detailed information about your project's toolchain configuration"
        }
    }
}

// MARK: - Previews

#Preview("Default Toolchain") {
    let context = ProjectContextInfo(
        projectPath: "/Users/user/projects/my-rust-app",
        activeToolchain: "stable-aarch64-apple-darwin",
        reason: .default,
        sourcePath: nil
    )

    let toolchains = [
        ToolchainInfo(
            name: "stable-aarch64-apple-darwin",
            version: "1.75.0",
            isDefault: true,
            installDate: Date(),
            host: "aarch64-apple-darwin"
        ),
        ToolchainInfo(
            name: "nightly-aarch64-apple-darwin",
            version: "1.77.0-nightly",
            isDefault: false,
            installDate: Date(),
            host: "aarch64-apple-darwin"
        )
    ]

    return ProjectContextView(
        context: context,
        availableToolchains: toolchains,
        onSetOverride: { _ in },
        onClearOverride: { }
    )
    .frame(width: 600, height: 600)
}

#Preview("Toolchain File Override") {
    let context = ProjectContextInfo(
        projectPath: "/Users/user/projects/my-rust-app",
        activeToolchain: "nightly-aarch64-apple-darwin",
        reason: .toolchainFile,
        sourcePath: "/Users/user/projects/my-rust-app/rust-toolchain.toml"
    )

    let toolchains = [
        ToolchainInfo(
            name: "stable-aarch64-apple-darwin",
            version: "1.75.0",
            isDefault: true,
            installDate: Date(),
            host: "aarch64-apple-darwin"
        ),
        ToolchainInfo(
            name: "nightly-aarch64-apple-darwin",
            version: "1.77.0-nightly",
            isDefault: false,
            installDate: Date(),
            host: "aarch64-apple-darwin"
        )
    ]

    return ProjectContextView(
        context: context,
        availableToolchains: toolchains,
        onSetOverride: { _ in },
        onClearOverride: { }
    )
    .frame(width: 600, height: 600)
}
