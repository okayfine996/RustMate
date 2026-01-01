//
//  SettingsView.swift
//  RustMate
//
//  Application settings and configuration
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(settings: AppSettings = AppSettings()) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(settings: settings))
    }

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            permissionsTab
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }

            advancedTab
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
        }
        .frame(width: 600, height: 450)
    }

    // MARK: - General Tab

    @ViewBuilder
    private var generalTab: some View {
        Form {
            Section("Rustup Configuration") {
                LabeledContent("Rustup Path:") {
                    HStack {
                        TextField("Auto-detect", text: $viewModel.rustupPath)
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)

                        Button("Browse...") {
                            viewModel.browseForRustup()
                        }
                    }
                }

                LabeledContent("Version:") {
                    if let version = viewModel.rustupVersion {
                        Text(version)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not detected")
                            .foregroundStyle(.red)
                    }
                }

                Button("Validate Environment") {
                    Task {
                        await viewModel.validateEnvironment()
                    }
                }
                .buttonStyle(.bordered)
            }

            Section("Project Override Strategy") {
                Picker("Method:", selection: $viewModel.overrideStrategy) {
                    Text("rust-toolchain.toml file").tag(AppSettings.OverrideStrategy.toolchainFile)
                    Text("rustup override command").tag(AppSettings.OverrideStrategy.rustupOverride)
                }
                .pickerStyle(.radioGroup)

                Text(viewModel.overrideStrategy == .toolchainFile
                    ? "Creates rust-toolchain.toml in project directory (can be committed to repo)"
                    : "Uses rustup override set/unset (doesn't modify project files)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("UI Preferences") {
                Toggle("Show detailed task output", isOn: $viewModel.showDetailedOutput)
                Toggle("Auto-refresh on app activation", isOn: $viewModel.autoRefresh)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Permissions Tab (T049)

    @ViewBuilder
    private var permissionsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("File Access Permissions")
                .font(.title2.bold())
                .padding(.bottom, 8)

            Text("RustMate uses Security-Scoped Bookmarks to access files within the macOS App Sandbox.")
                .font(.body)
                .foregroundStyle(.secondary)

            Text("Required Authorizations")
                .font(.headline)
                .padding(.top, 8)

            // Rustup Executable Directory
            permissionRow(
                title: "Rustup Executable Directory",
                description: "Required to run rustup and cargo executables",
                path: "~/.cargo/bin",
                isAuthorized: viewModel.hasRustupExecutableDir,
                state: viewModel.authorizationStates[.rustupExecutableDir] ?? .missing,
                purpose: .rustupExecutableDir,
                authorizeAction: {
                    viewModel.authorizeDirectory(purpose: .rustupExecutableDir)
                },
                removeAction: {
                    viewModel.removeBookmark(purpose: .rustupExecutableDir)
                }
            )

            // Cargo Home
            permissionRow(
                title: "Cargo Home Directory",
                description: "Required for Cargo configuration and cache",
                path: "~/.cargo",
                isAuthorized: viewModel.hasCargoHome,
                state: viewModel.authorizationStates[.cargoHome] ?? .missing,
                purpose: .cargoHome,
                authorizeAction: {
                    viewModel.authorizeDirectory(purpose: .cargoHome)
                },
                removeAction: {
                    viewModel.removeBookmark(purpose: .cargoHome)
                }
            )

            // Rustup Home
            permissionRow(
                title: "Rustup Home Directory",
                description: "Required to access installed toolchains",
                path: "~/.rustup",
                isAuthorized: viewModel.hasRustupHome,
                state: viewModel.authorizationStates[.rustupHome] ?? .missing,
                purpose: .rustupHome,
                authorizeAction: {
                    viewModel.authorizeDirectory(purpose: .rustupHome)
                },
                removeAction: {
                    viewModel.removeBookmark(purpose: .rustupHome)
                }
            )

            Divider()

            // Project directories
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Project Directories")
                        .font(.headline)

                    Spacer()

                    Button("Add Project...") {
                        viewModel.authorizeDirectory(purpose: .projectAccess)
                    }
                    .buttonStyle(.bordered)
                }

                if viewModel.authorizedProjects.isEmpty {
                    Text("No project directories authorized")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.authorizedProjects) { project in
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(project.displayName)
                                    .font(.subheadline)

                                Text(project.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                viewModel.removeProjectBookmark(path: project.path)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private func permissionRow(
        title: String,
        description: String,
        path: String,
        isAuthorized: Bool,
        state: SettingsViewModel.AuthorizationState,
        purpose: AuthorizedDirectory.DirectoryPurpose,
        authorizeAction: @escaping () -> Void,
        removeAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: state.iconName)
                    .font(.title2)
                    .foregroundStyle(colorForState(state))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)

                        // Status badge
                        Text(state.displayText)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(backgroundForState(state))
                            .foregroundStyle(colorForState(state))
                            .cornerRadius(4)
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isAuthorized {
                    if state == .stale || state == .invalid {
                        // Show re-authorize button for stale/invalid states
                        Button("Re-authorize...") {
                            authorizeAction()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Remove") {
                            removeAction()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Button("Authorize...") {
                        authorizeAction()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Text("Path: \(path)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 32)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private func colorForState(_ state: SettingsViewModel.AuthorizationState) -> Color {
        switch state {
        case .authorized: return .green
        case .missing: return .gray
        case .stale: return .orange
        case .invalid: return .red
        }
    }

    private func backgroundForState(_ state: SettingsViewModel.AuthorizationState) -> Color {
        switch state {
        case .authorized: return .green.opacity(0.2)
        case .missing: return .gray.opacity(0.2)
        case .stale: return .orange.opacity(0.2)
        case .invalid: return .red.opacity(0.2)
        }
    }

    // MARK: - Advanced Tab (T050 - XPC section removed)

    @ViewBuilder
    private var advancedTab: some View {
        Form {
            Section("Environment Variables") {
                LabeledContent("RUSTUP_HOME:") {
                    TextField("Default: ~/.rustup", text: $viewModel.rustupHome)
                        .textFieldStyle(.roundedBorder)
                }

                LabeledContent("CARGO_HOME:") {
                    TextField("Default: ~/.cargo", text: $viewModel.cargoHome)
                        .textFieldStyle(.roundedBorder)
                }

                Text("Leave empty to use default locations")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Execution Mode") {
                LabeledContent("Mode:") {
                    Text("In-App (Sandboxed)")
                        .foregroundStyle(.secondary)
                }

                Text("RustMate now executes rustup directly within the sandboxed app using security-scoped bookmarks. XPC service is no longer used.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Danger Zone") {
                Button("Reset All Settings") {
                    viewModel.showResetConfirmation = true
                }
                .foregroundStyle(.red)
                .confirmationDialog(
                    "Reset all settings and permissions?",
                    isPresented: $viewModel.showResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset Everything", role: .destructive) {
                        viewModel.resetAllSettings()
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Previews

#Preview("General Tab") {
    SettingsView()
}

#Preview("With Authorized Access") {
    let settings = AppSettings()
    SettingsView(settings: settings)
}
