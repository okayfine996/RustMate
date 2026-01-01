//
//  ToolchainListView.swift
//  RustMate
//
//  Main toolchain management view
//

import SwiftUI

struct ToolchainListView: View {
    @ObservedObject var viewModel: ToolchainViewModel
    @State private var showInstallSheet = false
    @State private var showDeleteConfirmation = false
    @State private var toolchainToDelete: ToolchainInfo?

    init(viewModel: ToolchainViewModel) {
        self.viewModel = viewModel
    }

    // Convenience init for previews
    init(service: RustToolchainServiceProtocol = LocalRustupToolchainService()) {
        self.viewModel = ToolchainViewModel(service: service)
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.toolchains.isEmpty {
                LoadingView(message: "Loading toolchains...")
            } else if let error = viewModel.error, viewModel.toolchains.isEmpty {
                // T044: Show authorization-specific UI when needed
                if viewModel.requiresAuthorization {
                    authorizationRequiredView
                } else {
                    standardErrorView(error)
                }
            } else if viewModel.toolchains.isEmpty {
                emptyState
            } else {
                toolchainList
            }
        }
        .navigationTitle("Toolchains")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    Task {
                        await viewModel.updateAllToolchains()
                    }
                } label: {
                    Label("Update All", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(viewModel.isLoading || viewModel.toolchains.isEmpty)

                Button {
                    showInstallSheet = true
                } label: {
                    Label("Install", systemImage: "plus")
                }
            }
        }
        .task {
            await viewModel.loadToolchains()
        }
        .sheet(isPresented: $showInstallSheet) {
            InstallToolchainSheet(viewModel: viewModel)
        }
        .confirmationDialog(
            "Uninstall \(toolchainToDelete?.name ?? "")?",
            isPresented: $showDeleteConfirmation,
            presenting: toolchainToDelete
        ) { toolchain in
            Button("Uninstall", role: .destructive) {
                Task {
                    await viewModel.uninstallToolchain(toolchain)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { toolchain in
            Text("This will remove the \(toolchain.name) toolchain from your system.")
        }
    }

    // MARK: - Toolchain List

    @ViewBuilder
    private var toolchainList: some View {
        List(selection: $viewModel.selectedToolchain) {
            ForEach(viewModel.toolchains) { toolchain in
                ToolchainRowView(
                    toolchain: toolchain,
                    onSetDefault: {
                        Task {
                            await viewModel.setDefaultToolchain(toolchain)
                        }
                    },
                    onUpdate: {
                        Task {
                            await viewModel.updateToolchain(toolchain)
                        }
                    },
                    onDelete: {
                        toolchainToDelete = toolchain
                        showDeleteConfirmation = true
                    }
                )
                .tag(toolchain)
            }
        }
        .listStyle(.inset)
        .refreshable {
            await viewModel.loadToolchains()
        }
    }

    // MARK: - Authorization Required View (T044)

    @ViewBuilder
    private var authorizationRequiredView: some View {
        if let presentation = viewModel.errorPresentation {
            AuthorizationRequiredView(
                title: presentation.title,
                message: presentation.message,
                missingPurposes: extractMissingPurposes(from: viewModel.error),
                onAuthorize: {
                    // Post authorization request notification
                    let purposes = extractMissingPurposes(from: viewModel.error)
                    AuthorizationCoordinator.requestAuthorization(for: purposes)
                },
                onOpenSettings: {
                    // Open Settings window
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenSettings"),
                        object: nil
                    )
                }
            )
        }
    }

    @ViewBuilder
    private func standardErrorView(_ error: Error) -> some View {
        if let presentation = viewModel.errorPresentation {
            ErrorView(
                title: presentation.title,
                message: presentation.message,
                hints: presentation.suggestedFix.map { [$0] } ?? [
                    "Ensure all required directories are authorized in Settings",
                    "Verify rustup is installed and accessible",
                    "Check that ~/.cargo/bin, ~/.cargo, and ~/.rustup are authorized"
                ],
                actionTitle: "Retry",
                action: {
                    Task {
                        await viewModel.loadToolchains()
                    }
                }
            )
        } else {
            ErrorView(
                message: error.localizedDescription,
                hints: [
                    "Ensure all required directories are authorized in Settings",
                    "Verify rustup is installed and accessible"
                ],
                actionTitle: "Retry",
                action: {
                    Task {
                        await viewModel.loadToolchains()
                    }
                }
            )
        }
    }

    private func extractMissingPurposes(from error: Error?) -> [AuthorizedDirectory.DirectoryPurpose] {
        guard let error = error else { return [] }

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

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Toolchains")
                .font(.title.bold())

            Text("Install your first Rust toolchain to get started")
                .font(.body)
                .foregroundStyle(.secondary)

            Button {
                showInstallSheet = true
            } label: {
                Label("Install Toolchain", systemImage: "plus")
                    .font(.body.bold())
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Install Sheet

struct InstallToolchainSheet: View {
    @ObservedObject var viewModel: ToolchainViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var toolchainName = ""
    @State private var selectedSuggestion: String?
    @State private var isInstalling = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Install Toolchain")
                    .font(.title.bold())

                Text("Choose a toolchain to install")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Suggestions
                    if !viewModel.suggestedToolchains.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Common Toolchains")
                                .font(.headline)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                                ForEach(viewModel.suggestedToolchains, id: \.self) { suggestion in
                                    Button {
                                        selectedSuggestion = suggestion
                                        toolchainName = suggestion
                                    } label: {
                                        HStack {
                                            Text(suggestion)
                                                .font(.subheadline)
                                            Spacer()
                                            if selectedSuggestion == suggestion {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.blue)
                                            }
                                        }
                                        .padding(10)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedSuggestion == suggestion ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.1))
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Custom name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Toolchain Name")
                            .font(.headline)

                        TextField("e.g., stable, nightly, 1.75.0", text: $toolchainName)
                            .textFieldStyle(.roundedBorder)

                        Text("Examples: stable, beta, nightly, 1.75.0, nightly-2024-01-01")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Info
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("This will download and install the specified toolchain using rustup.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(24)
            }

            Divider()

            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Install") {
                    Task {
                        isInstalling = true
                        await viewModel.installToolchain(name: toolchainName)
                        isInstalling = false
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(toolchainName.isEmpty || isInstalling)
            }
            .padding(16)
        }
        .frame(width: 500, height: 450)
    }
}

// MARK: - Previews

#Preview("With Toolchains") {
    NavigationStack {
        ToolchainListView(service: MockToolchainService())
    }
}

#Preview("Empty State") {
    let service = MockToolchainService()
    // Mock empty response
    return NavigationStack {
        ToolchainListView(service: service)
    }
}

#Preview("Install Sheet") {
    InstallToolchainSheet(viewModel: ToolchainViewModel(service: MockToolchainService()))
}
