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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AllAuthorizationsCompleted"))) { _ in
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
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenSettings"),
                    object: nil
                )
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
            // Header with search
            VStack(spacing: GlassTokens.Spacing.md) {
                HStack {
                    Text("PROJECTS")
                        .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                        .tracking(0.5)

                    Spacer()

                    Button {
                        showingFilePicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: GlassTokens.Typography.headlineSize))
                            .foregroundColor(GlassTokens.Colors.accent)
                    }
                    .buttonStyle(.plain)
                    .help("Add project")
                }

                // Search field
                HStack(spacing: GlassTokens.Spacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)

                    TextField("Search projects...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: GlassTokens.Typography.bodySize))
                }
                .padding(GlassTokens.Spacing.sm)
                .background(GlassTokens.Colors.cardBackground)
                .cornerRadius(GlassTokens.Radius.sm)
            }
            .padding(GlassTokens.Spacing.md)

            Divider()

            // Project list
            List(filteredProjects, selection: $viewModel.selectedProject) { project in
                HStack(spacing: GlassTokens.Spacing.md) {
                    // Project type icon
                    Image(systemName: projectIcon(for: project))
                        .font(.system(size: GlassTokens.Typography.titleSize))
                        .foregroundColor(GlassTokens.Colors.accent)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.displayName)
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        Text(shortenPath(project.path))
                            .font(.system(size: GlassTokens.Typography.captionSize, design: .monospaced))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Favorite star button
                    Button {
                        viewModel.toggleFavorite(project)
                    } label: {
                        Image(systemName: project.isFavorite ? "star.fill" : "star")
                            .font(.system(size: GlassTokens.Typography.bodySize))
                            .foregroundColor(project.isFavorite ? GlassTokens.Colors.warning : GlassTokens.Colors.textSecondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help(project.isFavorite ? "Remove from favorites" : "Add to favorites")
                }
                .padding(.vertical, GlassTokens.Spacing.xs)
                .tag(project)
                .contextMenu {
                    Button("Remove") {
                        viewModel.removeBookmark(project)
                    }
                }
            }
            .listStyle(.sidebar)
        }
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
        guard let error = error else { return false }

        if error is AuthorizationError {
            return true
        }

        if let execError = error as? RustupExecutionError {
            switch execError {
            case .missingAuthorization:
                return true
            default:
                return false
            }
        }

        return false
    }

    private func handleAuthorizationError() {
        guard let error = viewModel.error else { return }

        let purposes = extractMissingPurposes(from: error)
        if !purposes.isEmpty {
            // Request authorization via coordinator
            AuthorizationCoordinator.requestAuthorization(for: purposes)
        }

        // Clear error
        viewModel.error = nil
    }

    private func extractMissingPurposes(from error: Error) -> [AuthorizedDirectory.DirectoryPurpose] {
        if let authError = error as? AuthorizationError {
            switch authError {
            case .missingScope(let purpose):
                return [purpose]
            case .staleBookmark(_, let purpose), .accessDenied(_, let purpose), .invalidSelection(_, let purpose, _):
                return [purpose]
            }
        } else if let execError = error as? RustupExecutionError {
            switch execError {
            case .missingAuthorization(let purpose, _, _):
                return [purpose]
            default:
                return []
            }
        }

        return []
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ProjectsListView()
    }
}
