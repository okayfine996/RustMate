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
    
    @State private var selectedSection: SettingsSection = .general

    // T004: Accept Binding<AppSettings> for single source of truth
    init(settingsBinding: Binding<AppSettings>) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(settingsBinding: settingsBinding))
    }
    
    enum SettingsSection: String, CaseIterable {
        case general = "General"
        case permissions = "Permissions"
        case advanced = "Advanced"
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .permissions: return "lock"
            case .advanced: return "gearshape.2"
            }
        }
    }

    var body: some View {
        HSplitView {
            // Left sidebar navigation
            navigationSidebar
                .frame(minWidth: 220, idealWidth: 250, maxWidth: 280)
            
            // Right content area
            contentArea
        }
    }
    
    // MARK: - Navigation Sidebar
    
    @ViewBuilder
    private var navigationSidebar: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text("Settings")
                    .font(.system(size: GlassTokens.Typography.titleSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                Text("Manage preferences")
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            .padding(.horizontal, GlassTokens.Spacing.lg)
            .padding(.top, GlassTokens.Spacing.xl)
            .padding(.bottom, GlassTokens.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(GlassTokens.Colors.divider)
            
            // Navigation items
            ScrollView {
                VStack(spacing: GlassTokens.Spacing.xs) {
                    ForEach(SettingsSection.allCases, id: \.self) { section in
                        navigationItem(section: section)
                    }
                }
                .padding(.vertical, GlassTokens.Spacing.md)
            }
            
            Spacer()
            
            // Links section
            Divider()
                .background(GlassTokens.Colors.divider)
            
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text("LINKS")
                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .tracking(0.5)
                    .padding(.horizontal, GlassTokens.Spacing.lg)
                    .padding(.top, GlassTokens.Spacing.lg)
                    .padding(.bottom, GlassTokens.Spacing.xs)
                
                VStack(spacing: GlassTokens.Spacing.xs) {
                    linkItem(title: "Documentation", icon: "questionmark.circle", action: {
                        if let url = URL(string: "https://github.com/okayfine996/RustMate") {
                            NSWorkspace.shared.open(url)
                        }
                    })
                    
                    linkItem(title: "Report Issue", icon: "exclamationmark.circle", action: {
                        if let url = URL(string: "https://github.com/okayfine996/RustMate/issues") {
                            NSWorkspace.shared.open(url)
                        }
                    })
                }
            }
            .padding(.bottom, GlassTokens.Spacing.lg)
        }
        .background(GlassTokens.Colors.cardBackground.opacity(0.5))
    }
    
    @ViewBuilder
    private func navigationItem(section: SettingsSection) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = section
            }
        } label: {
            HStack(spacing: GlassTokens.Spacing.md) {
                Image(systemName: section.icon)
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(selectedSection == section ? GlassTokens.Colors.accent : GlassTokens.Colors.textSecondary)
                    .frame(width: 20)
                
                Text(section.rawValue)
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: selectedSection == section ? .semibold : .regular))
                    .foregroundColor(selectedSection == section ? GlassTokens.Colors.textPrimary : GlassTokens.Colors.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, GlassTokens.Spacing.lg)
            .padding(.vertical, GlassTokens.Spacing.sm)
            .background(selectedSection == section ? GlassTokens.Colors.accentSubtle.opacity(0.3) : Color.clear)
            .cornerRadius(GlassTokens.Radius.md)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func linkItem(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: GlassTokens.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, GlassTokens.Spacing.lg)
            .padding(.vertical, GlassTokens.Spacing.sm)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Content Area
    
    @ViewBuilder
    private var contentArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xxl) {
                // Breadcrumbs
                breadcrumbsView
                
                // Page title and description
                pageHeaderView
                
                // Content based on selected section
                Group {
                    switch selectedSection {
                    case .general:
                        generalContentView
                    case .permissions:
                        permissionsContentView
                    case .advanced:
                        advancedContentView
                    }
                }
            }
            .padding(GlassTokens.Spacing.xxl)
        }
        .background(GlassTokens.Colors.backgroundPrimary)
    }
    
    @ViewBuilder
    private var breadcrumbsView: some View {
        HStack(spacing: GlassTokens.Spacing.xs) {
            Text("Settings")
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
            
            Image(systemName: "chevron.right")
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
            
            Text(selectedSection.rawValue)
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textPrimary)
        }
    }
    
    @ViewBuilder
    private var pageHeaderView: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
            Text("\(selectedSection.rawValue) Settings")
                .font(.system(size: GlassTokens.Typography.titleSize, weight: .bold))
                .foregroundColor(GlassTokens.Colors.textPrimary)
            
            Text(pageDescription)
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
        }
    }
    
    private var pageDescription: String {
        switch selectedSection {
        case .general:
            return "Configure your local Rust environment, toolchains, and UI preferences."
        case .permissions:
            return "Manage file access permissions for RustMate to access required directories."
        case .advanced:
            return "Advanced settings and system configuration options."
        }
    }

    // MARK: - Content Views
    
    @ViewBuilder
    private var generalContentView: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
            // Rustup Configuration
            rustupConfigurationSection
            
            // UI Preferences (including notifications)
            uiPreferencesWithNotificationsSection
        }
    }
    
    @ViewBuilder
    private var permissionsContentView: some View {
        permissionsSection
    }
    
    @ViewBuilder
    private var advancedContentView: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
            // Application Updates
            updatesSection
            
            // Project Override Strategy
            projectOverrideSection
            
            // Danger Zone
            dangerZoneSection
        }
    }
    
    // MARK: - Section Views

    @ViewBuilder
    private var rustupConfigurationSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                // Header with icon
                HStack(spacing: GlassTokens.Spacing.md) {
                    Image(systemName: "terminal")
                        .font(.system(size: GlassTokens.Typography.titleSize))
                        .foregroundColor(GlassTokens.Colors.accent)
                    
                    Text("Rustup Configuration")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                    // Default Toolchain (simplified - using rustup path as fallback)
                    settingRow(
                        label: "Default Toolchain",
                        description: "The toolchain to use when no override is set.",
                        content: {
                            if let version = viewModel.rustupVersion {
                                Text(version)
                                    .font(.system(size: GlassTokens.Typography.bodySize))
                                    .foregroundColor(GlassTokens.Colors.textSecondary)
                            } else {
                                Text("Auto-detect")
                                    .font(.system(size: GlassTokens.Typography.bodySize))
                                    .foregroundColor(GlassTokens.Colors.textSecondary)
                            }
                        }
                    )
                    
                    // Installation Profile (placeholder for future feature)
                    settingRow(
                        label: "Installation Profile",
                        description: "Set of components installed by default.",
                        content: {
                            Text("Default (Recommended)")
                                .font(.system(size: GlassTokens.Typography.bodySize))
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                        }
                    )
                    
                    // Auto-update Toolchains
                    settingRow(
                        label: "Auto-update Toolchains",
                        description: "Automatically check for updates on startup.",
                        content: {
                            Toggle("", isOn: .constant(true))
                                .toggleStyle(.switch)
                        }
                    )
                    
                    Divider()
                        .padding(.vertical, GlassTokens.Spacing.xs)
                    
                    // Rustup Path (advanced)
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
                    
                    // Version info
                    if let version = viewModel.rustupVersion {
                        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                            Text("Version: \(version)")
                                .font(.system(size: GlassTokens.Typography.bodySize))
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                        }
                    }
                    
                    Button("Validate Environment") {
                        Task {
                            await viewModel.validateEnvironment()
                        }
                    }
                    .primaryGlassButtonStyle()
                    .padding(.top, GlassTokens.Spacing.xs)
                }
            }
        }
    }
    
    @ViewBuilder
    private func settingRow<Content: View>(
        label: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                    
                    Text(description)
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                content()
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
    private var uiPreferencesWithNotificationsSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
            // UI Preferences
            GlassCard {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                    // Header with icon
                    HStack(spacing: GlassTokens.Spacing.md) {
                        Image(systemName: "display")
                            .font(.system(size: GlassTokens.Typography.titleSize))
                            .foregroundColor(GlassTokens.Colors.accent)
                        
                        Text("UI Preferences")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                            .foregroundColor(GlassTokens.Colors.textPrimary)
                    }
                    
                    settingRow(
                        label: "Auto-refresh Dashboard",
                        description: "Keep project lists and statuses up to date in the background.",
                        content: {
                            Toggle("", isOn: $viewModel.autoRefresh)
                                .toggleStyle(.switch)
                        }
                    )
                }
            }
            
            // Notifications
            GlassCard {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                    // Header with icon
                    HStack(spacing: GlassTokens.Spacing.md) {
                        Image(systemName: "bell")
                            .font(.system(size: GlassTokens.Typography.titleSize))
                            .foregroundColor(GlassTokens.Colors.accent)
                        
                        Text("Notifications")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                            .foregroundColor(GlassTokens.Colors.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        // Build Failures
                        settingRow(
                            label: "Build Failures",
                            description: "Notify me when a background build fails.",
                            content: {
                                Toggle("", isOn: $viewModel.enableTaskNotifications)
                                    .toggleStyle(.switch)
                            }
                        )
                        
                        // Toolchain Updates Available
                        settingRow(
                            label: "Toolchain Updates Available",
                            description: "Notify when a new stable version is released.",
                            content: {
                                Toggle("", isOn: .constant(false))
                                    .toggleStyle(.switch)
                            }
                        )
                    }
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
                        get: { updateService.currentChannel == .beta },
                        set: { isBeta in
                            let newChannel: AppSettings.UpdateChannel = isBeta ? .beta : .stable
                            // T016: Update channel preference in settings
                            viewModel.settings.updateChannel = newChannel
                            // T017: Switch update service to new channel (this will trigger UI update via @Published)
                            updateService.switchChannel(to: newChannel)
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
                    
                    Text(updateService.currentChannel == .beta 
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
