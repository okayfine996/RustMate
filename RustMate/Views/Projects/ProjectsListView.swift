//
//  ProjectsListView.swift
//  RustMate
//
//  View for managing project toolchain context and overrides
//

import SwiftUI
import UniformTypeIdentifiers

struct ProjectsListView: View {
    @StateObject private var viewModel = ProjectsViewModel()
    @State private var availableToolchains: [ToolchainInfo] = []
    @State private var isLoadingToolchains = false
    @State private var showingFilePicker = false
    @State private var showingOverridePicker = false
    @State private var showingAuthorizationAlert = false
    @State private var showingErrorAlert = false
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.projects.isEmpty {
                emptyState
            } else {
                HSplitView {
                    // Left: Project list
                    projectsList
                        .frame(minWidth: 180, idealWidth: 200, maxWidth: 300)

                    // Right: Project context view
                    if viewModel.selectedProject == nil {
                        selectProjectPrompt
                    } else if viewModel.isLoading {
                        loadingView
                    } else if let context = viewModel.projectContext {
                        ProjectContextView(
                            context: context,
                            availableToolchains: availableToolchains,
                            onSetOverride: { toolchain in
                                Task {
                                    await viewModel.setOverride(toolchainName: toolchain.name)
                                }
                            },
                            onClearOverride: {
                                Task {
                                    await viewModel.clearOverride()
                                }
                            }
                        )
                    } else {
                        noContextView
                    }
                }
            }
        }
        .navigationTitle("Projects")
        .onAppEvent(.allAuthorizationsCompleted) {
            // When all authorizations complete, refresh settings and retry loading project
            print("📢 ProjectsListView: Received AllAuthorizationsCompleted, refreshing settings and retrying")
            viewModel.refreshSettings()
            Task {
                await viewModel.loadProjectContext()
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.addBookmark(url: url)
                }
            case .failure(let error):
                viewModel.error = error
            }
        }
        .task {
            // Load available toolchains for override picker
            await loadAvailableToolchains()

            // Auto-select first project after view is ready
            viewModel.autoSelectFirstIfNeeded()
        }
        .onChange(of: viewModel.selectedProject) { _, _ in
            Task {
                await viewModel.loadProjectContext()
            }
        }
        .onChange(of: viewModel.error?.localizedDescription) { _, _ in
            // When error changes, determine which alert to show
            if let error = viewModel.error {
                if isAuthorizationError(error) {
                    showingAuthorizationAlert = true
                    showingErrorAlert = false
                } else {
                    showingErrorAlert = true
                    showingAuthorizationAlert = false
                }
            } else {
                showingAuthorizationAlert = false
                showingErrorAlert = false
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .alert("Authorization Required", isPresented: $showingAuthorizationAlert) {
            Button("Authorize") {
                handleAuthorizationError()
            }
            Button("Open Settings") {
                EventBus.shared.publishWithLegacy(.openSettings, notification: Constants.Notifications.openSettings)
                viewModel.error = nil
            }
            Button("Cancel", role: .cancel) {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error, let authError = error as? AuthorizationError {
                Text(authError.userFacingMessage)
            }
        }
    }

    // MARK: - Projects List

    @ViewBuilder
    private var projectsList: some View {
        VStack(spacing: 0) {    
            // Header
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text("Projects")
                    .font(.system(size: GlassTokens.Typography.titleSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text("Select a project to configure")
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            .padding(.horizontal, GlassTokens.Spacing.lg)
            .padding(.top, GlassTokens.Spacing.xl)
            .padding(.bottom, GlassTokens.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Project list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filteredProjects) { project in
                        ProjectTableRow(
                            project: project,
                            isSelected: viewModel.selectedProject?.id == project.id,
                            shortenedPath: shortenPath(project.path),
                            onSelect: {
                                viewModel.selectedProject = project
                            },
                            onRemove: {
                                viewModel.removeBookmark(project)
                            }
                        )
                        Divider()
                    }
                }
            }
            
            // Bottom add button
            VStack(spacing: 0) {
                Divider()

                Button {
                    showingFilePicker = true
                } label: {
                    HStack(spacing: GlassTokens.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: GlassTokens.Typography.bodySize))
                        Text("Add Project")
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    }
                    .foregroundColor(GlassTokens.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, GlassTokens.Spacing.md)
            }
        }
        .background(GlassTokens.Colors.backgroundSecondary)
    }

    private var filteredProjects: [ProjectBookmark] {
        let filtered: [ProjectBookmark]
        if searchText.isEmpty {
            filtered = viewModel.projects
        } else {
            filtered = viewModel.projects.filter { project in
                project.displayName.localizedCaseInsensitiveContains(searchText) ||
                project.path.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort: favorites first, then by name
        return filtered.sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite {
                return lhs.isFavorite
            }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    private func projectIcon(for project: ProjectBookmark) -> String {
        return "cube"
    }

    private func shortenPath(_ path: String) -> String {
        // Convert /Users/fineke/dev/rust/project to ~/dev/rust/project
        if let homeDir = FileManager.default.homeDirectoryForCurrentUser.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
           let homeDirDecoded = homeDir.removingPercentEncoding,
           path.hasPrefix(homeDirDecoded) {
            return path.replacingOccurrences(of: homeDirDecoded, with: "~")
        }
        return path
    }

    // MARK: - Empty & Loading States

    @ViewBuilder
    private var emptyState: some View {
        EmptyStateView(
            icon: "folder.badge.plus",
            title: "No Projects",
            description: "Add a project directory to view its toolchain context.",
            actionTitle: "Add Project",
            action: { showingFilePicker = true }
        )
    }

    @ViewBuilder
    private var selectProjectPrompt: some View {
        EmptyStateView(
            icon: "arrow.left",
            title: "Select a Project",
            description: "Choose a project from the list to view its toolchain context."
        )
    }

    @ViewBuilder
    private var loadingView: some View {
        LoadingView(message: "Loading project context...")
    }

    @ViewBuilder
    private var noContextView: some View {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "Unable to Load Context",
            description: "Failed to retrieve toolchain information for this project.",
            actionTitle: "Retry",
            action: {
                Task {
                    await viewModel.refreshProjectContext()
                }
            }
        )
    }

    // MARK: - Helper Methods

    private func loadAvailableToolchains() async {
        isLoadingToolchains = true
        do {
            let service = LocalRustupToolchainService()
            availableToolchains = try await service.listToolchains()
        } catch {
            print("Failed to load toolchains: \(error)")
            availableToolchains = []
        }
        isLoadingToolchains = false
    }

    // MARK: - Authorization Error Handling

    private func isAuthorizationError(_ error: Error?) -> Bool {
        AuthorizationHelpers.isAuthorizationError(error)
    }

    private func handleAuthorizationError() {
        guard let error = viewModel.error else { return }
        AuthorizationHelpers.handleAuthorizationError(error)
        viewModel.error = nil
    }

    private func extractMissingPurposes(from error: Error) -> [AuthorizedDirectory.DirectoryPurpose] {
        AuthorizationHelpers.extractMissingPurposes(from: error)
    }
}

// MARK: - Project Table Row

struct ProjectTableRow: View {
    let project: ProjectBookmark
    let isSelected: Bool
    let shortenedPath: String
    let onSelect: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // Project name and path
            VStack(alignment: .leading, spacing: 2) {
                Text(project.displayName)
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text(shortenedPath)
                    .font(.system(size: GlassTokens.Typography.captionSize, design: .monospaced))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Right arrow icon
            Image(systemName: "chevron.right")
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textSecondary.opacity(0.5))
        }
        .padding(.horizontal, GlassTokens.Spacing.md)
        .frame(height: 44)
        .background(isSelected ? GlassTokens.Colors.accentSubtle.opacity(0.3) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            Button("Remove") {
                onRemove()
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ProjectsListView()
    }
}
