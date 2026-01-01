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

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar/status bar
            statusBar

            Divider()

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

    // MARK: - Status Bar

    @ViewBuilder
    private var statusBar: some View {
        HStack(spacing: 12) {
            Text("Project Context")
                .font(.subheadline.bold())

            Spacer()

            // Override mode setting
            Menu {
                Button {
                    viewModel.overrideMode = "toolchainFile"
                } label: {
                    HStack {
                        Text("rust-toolchain.toml")
                        if viewModel.overrideMode == "toolchainFile" {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button {
                    viewModel.overrideMode = "override"
                } label: {
                    HStack {
                        Text("rustup override")
                        if viewModel.overrideMode == "override" {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape")
                    Text(viewModel.overrideMode == "toolchainFile" ? "File" : "Override")
                        .font(.caption)
                }
            }
            .help("Override strategy")

            Button {
                Task {
                    await viewModel.refreshProjectContext()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.selectedProject == nil || viewModel.isLoading)
            .help("Refresh project context")

            Button {
                showingFilePicker = true
            } label: {
                Image(systemName: "plus")
            }
            .help("Add project")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Projects List

    @ViewBuilder
    private var projectsList: some View {
        VStack(spacing: 0) {
            List(viewModel.projects, selection: $viewModel.selectedProject) { project in
                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.displayName)
                            .font(.body.bold())

                        Text(project.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        viewModel.removeBookmark(project)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Remove project")
                }
                .padding(.vertical, 4)
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

    // MARK: - Empty & Loading States

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Projects")
                .font(.title.bold())

            Text("Add a project directory to view its toolchain context.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingFilePicker = true
            } label: {
                Label("Add Project", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var selectProjectPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Select a Project")
                .font(.title.bold())

            Text("Choose a project from the list to view its toolchain context.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading project context...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var noContextView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("Unable to Load Context")
                .font(.title.bold())

            Text("Failed to retrieve toolchain information for this project.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.refreshProjectContext()
                }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
