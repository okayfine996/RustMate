//
//  ProjectToolchainSettingsView.swift
//  RustMate
//
//  View for configuring project toolchain settings (rust-toolchain.toml)
//  Refactored: Extracted sections into separate components
//

import SwiftUI

struct ProjectToolchainSettingsView: View {
    @StateObject private var viewModel: ProjectToolchainViewModel
    @StateObject private var diagnosticsViewModel = ProjectDiagnosticsViewModel()

    let projectPath: String

    @State private var showingAddTarget = false
    @State private var selectedTargets: Set<String> = []
    @State private var showingAddComponent = false
    @State private var selectedComponents: Set<String> = []
    @State private var originalConfig: ProjectToolchainConfig?

    init(projectPath: String) {
        self.projectPath = projectPath
        _viewModel = StateObject(wrappedValue: ProjectToolchainViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
                    // Error display
                    if let error = viewModel.error {
                        ProjectErrorBanner(error: error, onDismiss: {
                            viewModel.error = nil
                        })
                    }

                    // Version mismatch warning banner
                    if let diagnostics = diagnosticsViewModel.diagnostics, diagnostics.hasMismatch {
                        VersionMismatchBanner(
                            diagnostics: diagnostics,
                            projectPath: projectPath,
                            onFix: {
                                try? await diagnosticsViewModel.fixMismatch()
                                await diagnosticsViewModel.loadDiagnostics(projectPath: projectPath)
                            }
                        )
                    }

                    // Channel Selection
                    ChannelSelectionSection(viewModel: viewModel)

                    // Version Input
                    VersionInputSection(viewModel: viewModel)

                    // Components and Targets (side by side)
                    HStack(alignment: .top, spacing: GlassTokens.Spacing.xl) {
                        componentsSection
                            .frame(maxWidth: .infinity)

                        targetsSection
                            .frame(maxWidth: .infinity)
                    }

                    // Profile
                    ProfileSelectionSection(viewModel: viewModel)
                }
                .padding(GlassTokens.Spacing.xxl)
            }

            // Fixed status bar at bottom
            Divider()
            saveButton
                .background(GlassTokens.Colors.backgroundSecondary)
        }
        .background(GlassTokens.Colors.backgroundSecondary)
        .task {
            await viewModel.loadConfig(projectPath: projectPath)
            originalConfig = viewModel.config
            await diagnosticsViewModel.loadDiagnostics(projectPath: projectPath)
            await viewModel.loadAvailableTargets()
        }
        .onChange(of: viewModel.config) { _, newConfig in
            if originalConfig == nil && newConfig != nil {
                originalConfig = newConfig
            }
        }
        .onChange(of: viewModel.config?.channel) { _, _ in
            Task {
                await viewModel.loadAvailableTargets()
            }
        }
        .sheet(isPresented: $showingAddTarget) {
            AddTargetView(
                selectedTargets: $selectedTargets,
                currentToolchain: viewModel.config?.channel?.rawValue ?? "stable",
                existingTargets: Set(viewModel.config?.targets ?? []),
                onAdd: { newTargets in
                    for target in newTargets {
                        viewModel.addTarget(target)
                    }
                }
            )
        }
        .sheet(isPresented: $showingAddComponent) {
            AddComponentView(
                selectedComponents: $selectedComponents,
                currentToolchain: viewModel.config?.channel?.rawValue ?? "stable",
                existingComponents: Set(viewModel.config?.components ?? []),
                onAdd: { newComponents in
                    for component in newComponents {
                        viewModel.toggleComponent(component)
                    }
                }
            )
        }
    }

    // MARK: - Components Section

    @ViewBuilder
    private var componentsSection: some View {
        let configuredComponents = viewModel.config?.components ?? []
        let componentItems = configuredComponents.sorted().map { component in
            SelectionItem(
                id: component,
                name: component,
                description: RustComponentDescriptions.description(for: component),
                isSelected: viewModel.config?.components.contains(component) ?? false,
                onToggle: { viewModel.toggleComponent(component) }
            )
        }

        SelectionCardView(
            title: "Components",
            actionButtonTitle: "ADD COMPONENT",
            showOnColumn: true,
            emptyMessage: "No components configured. Click \"ADD COMPONENT\" to add components.",
            items: componentItems,
            onAction: {
                selectedComponents = Set(viewModel.config?.components ?? [])
                showingAddComponent = true
            }
        )
    }

    // MARK: - Targets Section

    @ViewBuilder
    private var targetsSection: some View {
        let configuredTargets = viewModel.config?.targets ?? []
        let targetItems = configuredTargets.sorted().map { target in
            SelectionItem(
                id: target,
                name: target,
                description: RustTargetDescriptions.description(for: target),
                isSelected: viewModel.config?.targets.contains(target) ?? false,
                onToggle: { viewModel.toggleTarget(target) }
            )
        }

        SelectionCardView(
            title: "Targets",
            actionButtonTitle: "ADD TARGET",
            showOnColumn: true,
            emptyMessage: "No targets configured. Click \"ADD TARGET\" to add compilation targets.",
            items: targetItems,
            onAction: {
                selectedTargets = Set(viewModel.config?.targets ?? [])
                showingAddTarget = true
            }
        )
    }

    // MARK: - Save Button / Status Bar

    @ViewBuilder
    private var saveButton: some View {
        SettingsStatusBar(
            hasChanges: hasUnsavedChanges(),
            changeCount: countChanges(),
            statusMessage: hasUnsavedChanges() ? nil : "Configuration saved",
            isLoading: viewModel.isLoading,
            onDiscard: {
                discardChanges()
            },
            onSave: {
                Task {
                    do {
                        try await viewModel.saveConfig()
                        originalConfig = viewModel.config
                    } catch {
                        // Error is handled by viewModel.error
                    }
                }
            }
        )
    }

    // MARK: - Change Tracking

    private func hasUnsavedChanges() -> Bool {
        guard let current = viewModel.config, let original = originalConfig else {
            return false
        }
        return current != original
    }

    private func countChanges() -> Int {
        guard let current = viewModel.config, let original = originalConfig else {
            return 0
        }

        var count = 0

        if current.channel != original.channel { count += 1 }
        if current.version != original.version { count += 1 }
        if current.components != original.components { count += 1 }
        if current.targets != original.targets { count += 1 }
        if current.profile != original.profile { count += 1 }

        return count
    }

    private func discardChanges() {
        viewModel.config = originalConfig
    }
}

// MARK: - Rust Component Descriptions

enum RustComponentDescriptions {
    static func description(for component: String) -> String? {
        switch component.lowercased() {
        case "rustfmt":
            return "Automatic code formatter"
        case "clippy":
            return "Linting library to catch common mistakes"
        case "rust-src":
            return "Source code for the standard library"
        case "rust-analyzer":
            return "Language server for IDE support"
        case "llvm-tools-preview":
            return "LLVM tools for advanced debugging"
        case "rust-docs":
            return "Standard library documentation"
        default:
            return nil
        }
    }
}

// MARK: - Rust Target Descriptions

enum RustTargetDescriptions {
    static func description(for target: String) -> String? {
        let lower = target.lowercased()

        // WebAssembly
        if lower.contains("wasm32-unknown-unknown") {
            return "WebAssembly (Generic)"
        } else if lower.contains("wasm32-wasi") {
            return "WebAssembly System Interface"
        }
        // Apple platforms
        else if lower.contains("aarch64-apple-darwin") {
            return "macOS (Apple Silicon)"
        } else if lower.contains("x86_64-apple-darwin") {
            return "macOS (Intel)"
        } else if lower.contains("aarch64-apple-ios") {
            return "iOS on ARM64"
        } else if lower.contains("x86_64-apple-ios") {
            return "iOS Simulator"
        }
        // Linux
        else if lower.contains("x86_64-unknown-linux-gnu") {
            return "Linux x86_64 (GNU)"
        } else if lower.contains("aarch64-unknown-linux-gnu") {
            return "Linux ARM64 (GNU)"
        } else if lower.contains("x86_64-unknown-linux-musl") {
            return "Linux x86_64 (musl, static linking)"
        } else if lower.contains("aarch64-unknown-linux-musl") {
            return "Linux ARM64 (musl, static linking)"
        }
        // Windows
        else if lower.contains("x86_64-pc-windows-msvc") {
            return "Windows x86_64 (MSVC)"
        } else if lower.contains("x86_64-pc-windows-gnu") {
            return "Windows x86_64 (MinGW)"
        } else if lower.contains("i686-pc-windows-msvc") {
            return "Windows 32-bit (MSVC)"
        }
        // Android
        else if lower.contains("aarch64-linux-android") {
            return "Android ARM64"
        } else if lower.contains("armv7-linux-androideabi") {
            return "Android ARMv7"
        } else if lower.contains("x86_64-linux-android") {
            return "Android x86_64"
        }

        return nil
    }
}

// MARK: - Preview

#Preview {
    ProjectToolchainSettingsView(projectPath: "/Users/example/project")
        .frame(width: 900, height: 1200)
}
