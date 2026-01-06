//
//  SettingsView.swift
//  RustMate
//
//  Application settings and configuration
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var updateService: AppUpdateService  // T012: Access update service
    @Environment(\.dismiss) private var dismiss

    // T004: Accept Binding<AppSettings> for single source of truth
    init(settingsBinding: Binding<AppSettings>) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(settingsBinding: settingsBinding))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xxl) {
                // General Section
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                    sectionHeader(title: "General")

                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        rustupConfigurationSection
                        projectOverrideSection
                        uiPreferencesSection
                    }
                }

                Divider()
                    .padding(.vertical, GlassTokens.Spacing.sm)

                // T012: Updates Section
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                    sectionHeader(title: "Updates")
                    updatesSection
                }

                Divider()
                    .padding(.vertical, GlassTokens.Spacing.sm)

                // Permissions Section
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                    sectionHeader(title: "Permissions")
                    permissionsSection
                }

                Divider()
                    .padding(.vertical, GlassTokens.Spacing.sm)

                // Advanced Section
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                    sectionHeader(title: "Advanced")
                    dangerZoneSection
                }
            }
            .padding(GlassTokens.Spacing.xxl)
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: GlassTokens.Typography.titleSize, weight: GlassTokens.Typography.titleWeight))
            .foregroundColor(GlassTokens.Colors.textPrimary)
    }

    // MARK: - Section Views

    @ViewBuilder
    private var rustupConfigurationSection: some View {
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
    }

    @ViewBuilder
    private var projectOverrideSection: some View {
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
    }

    @ViewBuilder
    private var uiPreferencesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                // UI Preferences subsection
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                    Text("UI Preferences")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    Toggle("Auto-refresh on app activation", isOn: $viewModel.autoRefresh)
                        .toggleStyle(.switch)
                }

                Divider()

                // Notifications subsection
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                    Text("Notifications")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    Toggle("Enable task notifications", isOn: $viewModel.enableTaskNotifications)
                        .toggleStyle(.switch)

                    Text("Show system notifications when tasks start and complete")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Permissions Section

    @ViewBuilder
    private var permissionsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                    Text("File Access Permissions")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    Text("RustMate uses Security-Scoped Bookmarks to access files within the macOS App Sandbox.")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }

                VStack(spacing: GlassTokens.Spacing.md) {
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
            }
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

    // MARK: - Updates Section (T012, T014)

    @ViewBuilder
    private var updatesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                    Text("Application Updates")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                    
                    Text("Automatically check for and download updates")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
                
                // T015/T018: Beta channel toggle with current channel display
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                    Toggle("Receive Beta Updates", isOn: Binding(
                        get: { viewModel.settings.updateChannel == .beta },
                        set: { isBeta in
                            // T016: Update channel preference
                            viewModel.settings.updateChannel = isBeta ? .beta : .stable
                            // T017: Switch update service to new channel
                            updateService.switchChannel(to: viewModel.settings.updateChannel)
                        }
                    ))
                    .toggleStyle(.switch)
                    
                    // T018: Display current channel
                    HStack(spacing: GlassTokens.Spacing.xs) {
                        Text("Current channel:")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                        
                        Text(updateService.currentChannel.displayText)
                            .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                            .foregroundColor(updateService.currentChannel == .beta ? GlassTokens.Colors.warning : GlassTokens.Colors.success)
                    }
                    
                    Text(viewModel.settings.updateChannel == .beta 
                        ? "You'll receive early access to new features and improvements"
                        : "You'll receive stable, tested releases")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
                
                Divider()
                
                // T014: Display update state
                HStack(spacing: GlassTokens.Spacing.md) {
                    updateStateIndicator
                    
                    Spacer()
                    
                    // T012: Check for Updates button
                    Button("Check for Updates") {
                        updateService.checkForUpdates()
                    }
                    .primaryGlassButtonStyle()
                    .disabled(updateService.isUpdating)
                }
                
                // T014: Show detailed state information
                if case .updateAvailable(let info) = updateService.updateState {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                        Text("Version \(info.version) is available")
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                            .foregroundColor(GlassTokens.Colors.textPrimary)
                        
                        if let size = info.formattedSize {
                            Text("Download size: \(size)")
                                .font(.system(size: GlassTokens.Typography.captionSize))
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                        }
                        
                        if let notesURL = info.releaseNotesURL {
                            Link("View Release Notes", destination: notesURL)
                                .font(.system(size: GlassTokens.Typography.captionSize))
                        }
                    }
                    .padding(.top, GlassTokens.Spacing.sm)
                }
                
                // T014/T020: Show error details with retry option
                if case .failed(let error) = updateService.updateState {
                    ErrorCalloutView(
                        title: error.userMessage,
                        message: error.recoverySuggestion,
                        retryAction: {
                            updateService.checkForUpdates()
                        },
                        errorDetails: error.debugContext?.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
                    )
                    .padding(.top, GlassTokens.Spacing.sm)
                }
            }
        }
    }
    
    @ViewBuilder
    private var updateStateIndicator: some View {
        HStack(spacing: GlassTokens.Spacing.sm) {
            // State icon
            Group {
                switch updateService.updateState {
                case .idle, .noUpdate:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(GlassTokens.Colors.success)
                case .checking:
                    ProgressView()
                        .scaleEffect(0.8)
                case .updateAvailable:
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(GlassTokens.Colors.warning)
                case .downloading:
                    ProgressView()
                        .scaleEffect(0.8)
                case .readyToInstall:
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(GlassTokens.Colors.success)
                case .failed:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(GlassTokens.Colors.error)
                }
            }
            .font(.system(size: GlassTokens.Typography.titleSize))
            
            // State text
            Text(updateService.stateDisplayText)
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textPrimary)
        }
    }

    // MARK: - Danger Zone Section

    @ViewBuilder
    private var dangerZoneSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    Text("Danger Zone")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    Text("Caution: This action cannot be undone")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.error)
                }

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
}

// MARK: - Previews

#Preview("General Tab") {
    @State var settings = AppSettings()
    return SettingsView(settingsBinding: $settings)
}

#Preview("With Authorized Access") {
    @State var settings = AppSettings()
    return SettingsView(settingsBinding: $settings)
}
