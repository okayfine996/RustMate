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

    // MARK: - Permissions Tab

    @ViewBuilder
    private var permissionsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("File Access Permissions")
                .font(.title2.bold())
                .padding(.bottom, 8)

            Text("RustMate uses Security-Scoped Bookmarks to access files within the macOS App Sandbox.")
                .font(.body)
                .foregroundStyle(.secondary)

            // Cargo bin directory
            permissionRow(
                title: "Cargo Bin Directory",
                description: "Required to run rustup and cargo commands",
                path: "~/.cargo/bin",
                isAuthorized: viewModel.hasCargoBookmark,
                purpose: .rustupAccess,
                authorizeAction: {
                    viewModel.authorizeDirectory(purpose: .rustupAccess)
                },
                removeAction: {
                    viewModel.removeBookmark(purpose: .rustupAccess)
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
        purpose: AuthorizedDirectory.DirectoryPurpose,
        authorizeAction: @escaping () -> Void,
        removeAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isAuthorized ? .green : .red)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isAuthorized {
                    Button("Remove") {
                        removeAction()
                    }
                    .buttonStyle(.bordered)
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

    // MARK: - Advanced Tab

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

            Section("XPC Service") {
                LabeledContent("Service Name:") {
                    Text("com.finefine.RustMate.XPC")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Button("Test Connection") {
                    Task {
                        await viewModel.testXPCConnection()
                    }
                }
                .buttonStyle(.bordered)

                if let xpcStatus = viewModel.xpcConnectionStatus {
                    HStack {
                        Image(systemName: xpcStatus ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(xpcStatus ? .green : .red)

                        Text(xpcStatus ? "Connected" : "Connection Failed")
                            .font(.caption)
                    }
                }
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
