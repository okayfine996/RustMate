//
//  ProjectCargoSettingsView.swift
//  RustMate
//
//  View for configuring Cargo build settings (.cargo/config.toml)
//  Refactored: Extracted sections into separate components
//

import SwiftUI

struct ProjectCargoSettingsView: View {
    @StateObject private var viewModel: ProjectCargoViewModel
    let projectPath: String

    @State private var originalConfig: ProjectCargoConfig?
    @State private var showingAddAlias = false
    @State private var newAliasName = ""
    @State private var newAliasCommand = ""

    init(projectPath: String) {
        self.projectPath = projectPath
        _viewModel = StateObject(wrappedValue: ProjectCargoViewModel())
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

                    // Registry Mirror Section
                    RegistryMirrorSection(viewModel: viewModel)

                    // Cargo Aliases Section
                    CargoAliasesSection(
                        viewModel: viewModel,
                        onAddAlias: {
                            showingAddAlias = true
                        }
                    )

                    // Rustflags Section
                    RustflagsSection(viewModel: viewModel)
                }
                .padding(GlassTokens.Spacing.xxl)
            }

            // Fixed status bar at bottom
            Divider()
            statusBar
                .background(GlassTokens.Colors.backgroundPrimary)
        }
        .task {
            await viewModel.loadConfig(projectPath: projectPath)
            originalConfig = viewModel.config
        }
        .onChange(of: viewModel.config) { _, newConfig in
            if originalConfig == nil && newConfig != nil {
                originalConfig = newConfig
            }
        }
        .sheet(isPresented: $showingAddAlias) {
            AddAliasSheet(
                viewModel: viewModel,
                isPresented: $showingAddAlias,
                aliasName: $newAliasName,
                aliasCommand: $newAliasCommand
            )
        }
    }

    // MARK: - Status Bar

    @ViewBuilder
    private var statusBar: some View {
        SettingsStatusBar(
            hasChanges: hasUnsavedChanges(),
            changeCount: countChanges(),
            statusMessage: hasUnsavedChanges() ? nil : "All systems operational!",
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

        if current.registryMirror != original.registryMirror { count += 1 }
        if current.aliases != original.aliases { count += 1 }
        if current.linker != original.linker { count += 1 }
        if current.stripSymbols != original.stripSymbols { count += 1 }
        if current.rustflags != original.rustflags { count += 1 }

        return count
    }

    private func discardChanges() {
        viewModel.config = originalConfig
    }
}

// MARK: - Preview

#Preview {
    ProjectCargoSettingsView(projectPath: "/Users/example/project")
        .frame(width: 800, height: 1000)
}
