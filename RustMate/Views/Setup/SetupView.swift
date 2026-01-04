//
//  SetupView.swift
//  RustMate
//
//  Initial setup and rustup validation
//

import SwiftUI

struct SetupView: View {
    @StateObject private var viewModel: SetupViewModel
    @EnvironmentObject var appState: AppState

    init(validator: EnvironmentValidator = EnvironmentValidator()) {
        _viewModel = StateObject(wrappedValue: SetupViewModel(validator: validator))
    }

    // Sync viewModel settings to appState whenever they change
    private func syncSettings() {
        appState.settings = viewModel.settings
        print("🔄 SetupView: Synced settings to AppState, authorized directories count: \(appState.settings.authorizedDirectories.count)")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                Text("Welcome to RustMate")
                    .font(.largeTitle.bold())

                Text("Let's set up your Rust development environment")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isValidating {
                        LoadingView(message: "Validating environment...")
                            .frame(height: 200)
                    } else if let result = viewModel.validationResult {
                        if result.hasRustup {
                            successContent(result: result)
                        } else {
                            errorContent(result: result)
                        }
                    }

                    // Bookmark authorization section
                    bookmarkSection
                }
                .padding(24)
            }

            Divider()

            // Footer
            HStack {
                Spacer()

                if let result = viewModel.validationResult, result.hasRustup {
                    Button("Continue") {
                        // Sync settings before completing setup
                        syncSettings()
                        viewModel.completeSetup()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.hasRequiredBookmarks)
                } else {
                    Button("Retry Validation") {
                        print("🔘 SetupView: Retry Validation button clicked")
                        Task {
                            print("🔘 SetupView: Starting validation task")
                            await viewModel.validateEnvironment()
                            print("🔘 SetupView: Validation task completed")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(16)
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            // Setup callback to sync settings when authorization completes
            viewModel.onSettingsChanged = syncSettings
        }
        .task {
            await viewModel.validateEnvironment()
        }
    }

    // MARK: - Success Content

    @ViewBuilder
    private func successContent(result: ValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Rustup Found")
                        .font(.headline)

                    if let version = result.version {
                        Text("Version: \(version)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Executable detected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let path = result.rustupPath {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Text(path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Error Content

    @ViewBuilder
    private func errorContent(result: ValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                Text("Rustup Not Found")
                    .font(.headline)
            }

            Text("RustMate requires rustup to manage Rust toolchains. Please install rustup to continue.")
                .font(.body)
                .foregroundStyle(.secondary)

            if !result.hints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Installation Instructions:")
                        .font(.subheadline.bold())

                    ForEach(result.hints, id: \.self) { hint in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(hint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }

            // Custom path input
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Rustup Path:")
                    .font(.subheadline.bold())

                HStack {
                    TextField("Path to rustup executable", text: $viewModel.customRustupPath)
                        .textFieldStyle(.roundedBorder)

                    Button("Browse...") {
                        viewModel.browseForRustup()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Bookmark Section

    @ViewBuilder
    private var bookmarkSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("File Access Permissions")
                .font(.title3.bold())

            Text("RustMate needs access to the following directories to run rustup in sandbox mode:")
                .font(.body)
                .foregroundStyle(.secondary)

            // Rustup executable directory
            bookmarkRow(
                title: "Rustup Executable Directory",
                description: "Directory containing rustup command (usually ~/.cargo/bin)",
                isAuthorized: viewModel.hasRustupExecutableDir,
                action: {
                    viewModel.authorizeRustupExecutableDir()
                }
            )

            // Cargo home
            bookmarkRow(
                title: "Cargo Home",
                description: "Cargo data directory (usually ~/.cargo)",
                isAuthorized: viewModel.hasCargoHome,
                action: {
                    viewModel.authorizeCargoHome()
                }
            )

            // Rustup home
            bookmarkRow(
                title: "Rustup Home",
                description: "Rustup toolchain directory (usually ~/.rustup)",
                isAuthorized: viewModel.hasRustupHome,
                action: {
                    viewModel.authorizeRustupHome()
                }
            )

            Text("You can authorize project directories later in Settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func bookmarkRow(
        title: String,
        description: String,
        isAuthorized: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isAuthorized ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isAuthorized ? .green : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !isAuthorized {
                Button("Authorize...") {
                    action()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Previews

#Preview("Validating") {
    SetupView()
}

#Preview("Success - No Bookmarks") {
    SetupView()
}

#Preview("Rustup Not Found") {
    SetupView()
}
