//
//  ProjectDiagnosticsView.swift
//  RustMate
//
//  View for displaying project diagnostics and health status
//  Refactored: Extracted cards and sections into separate components
//

import SwiftUI

struct ProjectDiagnosticsView: View {
    @StateObject private var viewModel: ProjectDiagnosticsViewModel
    let projectPath: String

    @State private var showingConflictAlert = true

    init(projectPath: String) {
        self.projectPath = projectPath
        _viewModel = StateObject(wrappedValue: ProjectDiagnosticsViewModel())
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

                    // Loading indicator
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    } else if let diagnostics = viewModel.diagnostics {
                        // Top Alert Banner (if there's a conflict)
                        if diagnostics.hasMismatch && showingConflictAlert {
                            DiagnosticsConflictBanner(isVisible: $showingConflictAlert)
                        }

                        // Information Cards
                        HStack(alignment: .top, spacing: GlassTokens.Spacing.lg) {
                            ProjectConfigCard(diagnostics: diagnostics)
                            ActiveEnvironmentCard(diagnostics: diagnostics)
                        }

                        // Directory Override Alert (if override is active)
                        if diagnostics.toolchainSource == .override {
                            OverrideAlertBanner(
                                diagnostics: diagnostics,
                                isLoading: viewModel.isLoading,
                                onFix: {
                                    try? await viewModel.fixMismatch()
                                }
                            )
                        }

                        // Resolution Path Section
                        ResolutionPathSection(diagnostics: diagnostics)
                    }
                }
                .padding(GlassTokens.Spacing.xxl)
            }

            // Fixed status bar at bottom
            Divider()
            SettingsStatusBar(
                hasChanges: false,
                statusMessage: "Diagnostics updated just now",
                isLoading: viewModel.isLoading,
                discardButtonTitle: "Rescan",
                saveButtonTitle: "Apply Fixes",
                saveButtonIcon: "wrench.and.screwdriver",
                isSaveDisabled: viewModel.diagnostics?.hasMismatch != true,
                onDiscard: {
                    Task {
                        await viewModel.loadDiagnostics(projectPath: projectPath)
                    }
                },
                onSave: {
                    if let diagnostics = viewModel.diagnostics, diagnostics.hasMismatch {
                        Task {
                            try? await viewModel.fixMismatch()
                        }
                    }
                }
            )
        }
        .task {
            await viewModel.loadDiagnostics(projectPath: projectPath)
        }
    }
}
