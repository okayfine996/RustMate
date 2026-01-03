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
    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case permissions = "Permissions"
        case advanced = "Advanced"
    }

    init(settings: AppSettings = AppSettings()) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(settings: settings))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with title and tabs
            headerSection
                .padding(GlassTokens.Spacing.xxl)

            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case .general:
                    generalTab
                case .permissions:
                    permissionsTab
                case .advanced:
                    advancedTab
                }
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
            Text("Settings")
                .font(.system(size: GlassTokens.Typography.displaySize, weight: .bold))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            // Tab navigation
            HStack(spacing: GlassTokens.Spacing.xs) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? GlassTokens.Colors.accent : GlassTokens.Colors.textSecondary)
                            .padding(.horizontal, GlassTokens.Spacing.md)
                            .padding(.vertical, GlassTokens.Spacing.sm)
                            .background(
                                selectedTab == tab ?
                                    GlassTokens.Colors.accentSubtle.opacity(0.3) :
                                    Color.clear
                            )
                            .cornerRadius(GlassTokens.Radius.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - General Tab

    @ViewBuilder
    private var generalTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
                // Rustup Configuration
                GlassCard {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        Text("Rustup Configuration")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                            Text("Rustup Path:")
                                .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                                .foregroundColor(GlassTokens.Colors.textPrimary)

                            HStack(spacing: GlassTokens.Spacing.sm) {
                                TextField("Auto-detect", text: $viewModel.rustupPath)
                                    .textFieldStyle(.roundedBorder)
                                    .disabled(true)

                                Button("Browse...") {
                                    viewModel.browseForRustup()
                                }
                                .secondaryGlassButtonStyle()
                            }
                        }

                        VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                            Text("Version:")
                                .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                                .foregroundColor(GlassTokens.Colors.textPrimary)

                            if let version = viewModel.rustupVersion {
                                Text(version)
                                    .font(.system(size: GlassTokens.Typography.bodySize))
                                    .foregroundColor(GlassTokens.Colors.textSecondary)
                            } else {
                                Text("Not detected")
                                    .font(.system(size: GlassTokens.Typography.bodySize))
                                    .foregroundColor(GlassTokens.Colors.error)
                            }
                        }

                        Button("Validate Environment") {
                            Task {
                                await viewModel.validateEnvironment()
                            }
                        }
                        .primaryGlassButtonStyle()
                    }
                }

                // Project Override Strategy
                GlassCard {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        Text("Project Override Strategy")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        Picker("Method:", selection: $viewModel.overrideStrategy) {
                            Text("rust-toolchain.toml file").tag(AppSettings.OverrideStrategy.toolchainFile)
                            Text("rustup override command").tag(AppSettings.OverrideStrategy.rustupOverride)
                        }
                        .pickerStyle(.radioGroup)

                        Text(viewModel.overrideStrategy == .toolchainFile
                            ? "Creates rust-toolchain.toml in project directory (can be committed to repo)"
                            : "Uses rustup override set/unset (doesn't modify project files)")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                }

                // UI Preferences
                GlassCard {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        Text("UI Preferences")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        Toggle("Show detailed task output", isOn: $viewModel.showDetailedOutput)
                        Toggle("Auto-refresh on app activation", isOn: $viewModel.autoRefresh)
                    }
                }
            }
            .padding(GlassTokens.Spacing.xl)
        }
    }

    // MARK: - Permissions Tab (T049)

    @ViewBuilder
    private var permissionsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                    Text("File Access Permissions")
                        .font(.system(size: GlassTokens.Typography.titleSize, weight: GlassTokens.Typography.titleWeight))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    Text("RustMate uses Security-Scoped Bookmarks to access files within the macOS App Sandbox.")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }

                // Required Authorizations Section
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                    Text("Required Authorizations")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

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

                }

                // Project Directories Section
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                    HStack {
                        Text("Project Directories")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        Spacer()

                        Button("Add Project...") {
                            viewModel.authorizeDirectory(purpose: .projectAccess)
                        }
                        .secondaryGlassButtonStyle()
                    }

                    if viewModel.authorizedProjects.isEmpty {
                        EmptyStateView(
                            icon: "folder",
                            title: "No Projects",
                            description: "No project directories authorized yet."
                        )
                        .frame(height: 200)
                    } else {
                        VStack(spacing: GlassTokens.Spacing.sm) {
                            ForEach(viewModel.authorizedProjects) { project in
                                GlassCard(elevation: 2) {
                                    HStack(spacing: GlassTokens.Spacing.md) {
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: GlassTokens.Typography.headlineSize))
                                            .foregroundColor(GlassTokens.Colors.accent)

                                        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                                            Text(project.displayName)
                                                .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                                                .foregroundColor(GlassTokens.Colors.textPrimary)

                                            Text(project.path)
                                                .font(.system(size: GlassTokens.Typography.captionSize))
                                                .foregroundColor(GlassTokens.Colors.textSecondary)
                                        }

                                        Spacer()

                                        Button {
                                            viewModel.removeProjectBookmark(path: project.path)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(GlassTokens.Colors.error)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(GlassTokens.Spacing.xl)
        }
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
        GlassCard(elevation: 2) {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                HStack(spacing: GlassTokens.Spacing.md) {
                    Image(systemName: state.iconName)
                        .font(.system(size: GlassTokens.Typography.titleSize))
                        .foregroundColor(colorForState(state))

                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                        HStack(spacing: GlassTokens.Spacing.sm) {
                            Text(title)
                                .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                                .foregroundColor(GlassTokens.Colors.textPrimary)

                            // Status badge
                            StatusBadgeView(status: badgeStatusForState(state), text: state.displayText)
                        }

                        Text(description)
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }

                    Spacer()

                    if isAuthorized {
                        if state == .stale || state == .invalid {
                            Button("Re-authorize...") {
                                authorizeAction()
                            }
                            .primaryGlassButtonStyle()
                        } else {
                            Button("Remove") {
                                removeAction()
                            }
                            .secondaryGlassButtonStyle()
                        }
                    } else {
                        Button("Authorize...") {
                            authorizeAction()
                        }
                        .primaryGlassButtonStyle()
                    }
                }

                Text("Path: \(path)")
                    .font(.system(size: GlassTokens.Typography.captionSize, design: .monospaced))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .padding(.leading, GlassTokens.Spacing.xxxl)
            }
        }
    }

    private func colorForState(_ state: SettingsViewModel.AuthorizationState) -> Color {
        switch state {
        case .authorized: return GlassTokens.Colors.success
        case .missing: return GlassTokens.Colors.textSecondary
        case .stale: return GlassTokens.Colors.warning
        case .invalid: return GlassTokens.Colors.error
        }
    }

    private func badgeStatusForState(_ state: SettingsViewModel.AuthorizationState) -> StatusBadgeView.BadgeStatus {
        switch state {
        case .authorized: return .success
        case .missing: return .info
        case .stale: return .update
        case .invalid: return .failed
        }
    }

    // MARK: - Advanced Tab (T050 - XPC section removed)

    @ViewBuilder
    private var advancedTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
                // Environment Variables
                GlassCard {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        Text("Environment Variables")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                            Text("RUSTUP_HOME:")
                                .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                                .foregroundColor(GlassTokens.Colors.textPrimary)

                            TextField("Default: ~/.rustup", text: $viewModel.rustupHome)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                            Text("CARGO_HOME:")
                                .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                                .foregroundColor(GlassTokens.Colors.textPrimary)

                            TextField("Default: ~/.cargo", text: $viewModel.cargoHome)
                                .textFieldStyle(.roundedBorder)
                        }

                        Text("Leave empty to use default locations")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                }

                // Execution Mode
                GlassCard {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        Text("Execution Mode")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                            Text("Mode:")
                                .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                                .foregroundColor(GlassTokens.Colors.textPrimary)

                            Text("In-App (Sandboxed)")
                                .font(.system(size: GlassTokens.Typography.bodySize))
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                        }

                        Text("RustMate now executes rustup directly within the sandboxed app using security-scoped bookmarks. XPC service is no longer used.")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                }

                // Danger Zone
                GlassCard {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        Text("Danger Zone")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                            .foregroundColor(GlassTokens.Colors.error)

                        Button("Reset All Settings") {
                            viewModel.showResetConfirmation = true
                        }
                        .destructiveGlassButtonStyle()
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
            }
            .padding(GlassTokens.Spacing.xl)
        }
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
