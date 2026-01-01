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
                        .frame(minWidth: 200, idealWidth: 250)

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
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
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
            let service = XPCToolchainService()
            availableToolchains = try await service.listToolchains()
        } catch {
            print("Failed to load toolchains: \(error)")
            availableToolchains = []
        }
        isLoadingToolchains = false
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ProjectsListView()
    }
}
