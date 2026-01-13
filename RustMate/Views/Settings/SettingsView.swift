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
            Text(pageTitle)
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
            return "Manage your environment configuration, UI preferences, and system notifications."
        case .permissions:
            return "Manage file access permissions for RustMate to access required directories."
        case .advanced:
            return "Manage application update channels, version control, and reset configurations."
        }
    }
    
    private var pageTitle: String {
        switch selectedSection {
        case .general:
            return "General Settings"
        case .permissions:
            return "\(selectedSection.rawValue) Settings"
        case .advanced:
            return "Advanced & Updates"
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
            
            // Danger Zone
            dangerZoneSection
        }
    }
    
    // MARK: - Section Views

    @ViewBuilder
    private var rustupConfigurationSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Header with icon (outside card)
            HStack(spacing: GlassTokens.Spacing.md) {                
                Text("Rustup Configuration")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            }
            
            GlassCard {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                    // Rustup Binary Path
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                        Text("Rustup Binary Path")
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                            .foregroundColor(GlassTokens.Colors.textPrimary)
                        
                        HStack(spacing: GlassTokens.Spacing.sm) {
                            TextField("", text: $viewModel.rustupPath)
                                .textFieldStyle(.plain)
                                .padding(GlassTokens.Spacing.sm)
                                .background(GlassTokens.Colors.backgroundSecondary)
                                .cornerRadius(GlassTokens.Radius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                                        .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
                                )
                            
                            Button {
                                viewModel.browseForRustup()
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: GlassTokens.Typography.bodySize))
                                    .foregroundColor(GlassTokens.Colors.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Rustup Version and Check for Updates button
                    HStack {
                        // Rustup Version
                        if let rustupVersion = viewModel.rustupVersion {
                            HStack(spacing: GlassTokens.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: GlassTokens.Typography.bodySize))
                                    .foregroundColor(.green)
                                
                                Text("Rustup: \(rustupVersion)")
                                    .font(.system(size: GlassTokens.Typography.bodySize))
                                    .foregroundColor(GlassTokens.Colors.textPrimary)
                            }
                        }
                        
                        Spacer()
                        
                        // Check for Updates button
                        Button {
                            viewModel.checkForRustupUpdates()
                        } label: {
                            HStack(spacing: GlassTokens.Spacing.xs) {
                                if viewModel.isCheckingUpdates {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                        .frame(width: 16, height: 16)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: GlassTokens.Typography.bodySize))
                                        .frame(width: 16, height: 16)
                                }
                                Text("Check for Updates")
                                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, GlassTokens.Spacing.lg)
                            .padding(.vertical, GlassTokens.Spacing.md)
                            .background(GlassTokens.Colors.accent)
                            .cornerRadius(GlassTokens.Radius.md)
                            .frame(minWidth: 160)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isCheckingUpdates)
                    }
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
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {

                Text("UI Preferences")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                
                GlassCard {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                        // Auto-refresh Dashboard
                        HStack {
                            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                                Text("Auto-refresh Dashboard")
                                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                                    .foregroundColor(GlassTokens.Colors.textPrimary)
                                
                                Text("Automatically reload project status periodically.")
                                    .font(.system(size: GlassTokens.Typography.captionSize))
                                    .foregroundColor(GlassTokens.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.autoRefresh)
                                .toggleStyle(.switch)
                                .onChange(of: viewModel.autoRefresh) { _ in
                                    viewModel.saveSettings()
                                }
                        }
                        
                        // Refresh Interval
                        VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                            Text("Refresh Interval (seconds)")
                                .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                                .foregroundColor(GlassTokens.Colors.textPrimary)
                            
                            HStack(spacing: GlassTokens.Spacing.sm) {
                                TextField("", value: $viewModel.refreshIntervalSeconds, format: .number)
                                    .textFieldStyle(.plain)
                                    .frame(width: 80)
                                    .padding(GlassTokens.Spacing.sm)
                                    .background(GlassTokens.Colors.backgroundSecondary)
                                    .cornerRadius(GlassTokens.Radius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                                            .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
                                    )
                                    .onChange(of: viewModel.refreshIntervalSeconds) { _ in
                                        viewModel.saveSettings()
                                    }
                                
                                Text("sec")
                                    .font(.system(size: GlassTokens.Typography.bodySize))
                                    .foregroundColor(GlassTokens.Colors.textSecondary)
                            }
                        }
                    }
                }
            }
            
            // Notifications
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                Text("Notifications")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                
                GlassCard {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                        // Build Failure
                        HStack {
                            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                                Text("Build Failure")
                                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                                    .foregroundColor(GlassTokens.Colors.textPrimary)
                                
                                Text("Get notified immediately when a compilation fails.")
                                    .font(.system(size: GlassTokens.Typography.captionSize))
                                    .foregroundColor(GlassTokens.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.enableTaskNotifications)
                                .toggleStyle(.switch)
                                .onChange(of: viewModel.enableTaskNotifications) { _ in
                                    viewModel.saveSettings()
                                }
                        }
                        
                        // Toolchain Updates
                        HStack {
                            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                                Text("Toolchain Updates")
                                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                                    .foregroundColor(GlassTokens.Colors.textPrimary)
                                
                                Text("Receive alerts when new stable Rust versions are released.")
                                    .font(.system(size: GlassTokens.Typography.captionSize))
                                    .foregroundColor(GlassTokens.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.enableToolchainUpdateNotifications)
                                .toggleStyle(.switch)
                                .onChange(of: viewModel.enableToolchainUpdateNotifications) { _ in
                                    viewModel.saveSettings()
                                }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Permissions Section

    @ViewBuilder
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
            // Information Box
            HStack(alignment: .top, spacing: GlassTokens.Spacing.md) {
                // Info Icon
                ZStack {
                    Circle()
                        .fill(GlassTokens.Colors.accent)
                        .frame(width: 32, height: 32)
                    
                    Text("i")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Info Content
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    Text("Why are these permissions required?")
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                    
                    Text("This application needs read/write access to your local Rust toolchain directories for toolchain configuration and management. These permissions are required for the GUI to execute rustup commands safely on your behalf.")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
            }
            .padding(GlassTokens.Spacing.lg)
            .background(GlassTokens.Colors.backgroundSecondary)
            .cornerRadius(GlassTokens.Radius.lg)
            
            // Section Header
            Text("CRITICAL DIRECTORIES")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .tracking(0.5)
                .padding(.top, GlassTokens.Spacing.md)

            VStack(spacing: GlassTokens.Spacing.md) {
                    // Rustup Executable Directory
                    permissionRow(
                        title: "Rustup Bin Directory",
                        description: "Required to run rustup and cargo executables",
                        path: viewModel.settings.authorizedDirectory(for: .rustupExecutableDir)?.path ?? "~/.cargo/bin",
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
                        title: "Cargo Home",
                        description: "Required for Cargo configuration and cache",
                        path: viewModel.settings.authorizedDirectory(for: .cargoHome)?.path ?? "~/.cargo",
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
                        title: "Rustup Home",
                        description: "Required to access installed toolchains",
                        path: viewModel.settings.authorizedDirectory(for: .rustupHome)?.path ?? "~/.rustup",
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
        GlassCard {
            HStack(spacing: GlassTokens.Spacing.md) {
                // Icon
                Image(systemName: "folder.fill.badge.gearshape")
                    .font(.system(size: 20))
                    .foregroundColor(GlassTokens.Colors.accent)
                
                // Title, Status, and Path
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                    // Title and Status Badge
                    HStack(spacing: GlassTokens.Spacing.sm) {
                        Text(title)
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                            .foregroundColor(GlassTokens.Colors.textPrimary)
                        
                        if isAuthorized && state == .authorized {
                            HStack(spacing: GlassTokens.Spacing.xs) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.green)
                                Text("Authorized")
                                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, GlassTokens.Spacing.sm)
                            .padding(.vertical, GlassTokens.Spacing.xs)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(GlassTokens.Radius.pill)
                        }
                    }
                    
                    // Path in gray rounded rectangle
                    Text(path)
                        .font(.system(size: GlassTokens.Typography.captionSize, design: .monospaced))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                        .padding(GlassTokens.Spacing.sm)
                        .background(GlassTokens.Colors.backgroundSecondary)
                        .cornerRadius(GlassTokens.Radius.md)
                }
                
                Spacer()
                
                // Change Path button
                Button("Change Path...") {
                    authorizeAction()
                }
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.accent)
                .buttonStyle(.plain)
            }
            .padding(GlassTokens.Spacing.md)
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

    // MARK: - Updates Section

    @ViewBuilder
    private var updatesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                // Header with status badge
                HStack {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                        Text("Application Updates")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                            .foregroundColor(GlassTokens.Colors.textPrimary)
                        
                        Text("Configure how and when the app updates.")
                            .font(.system(size: GlassTokens.Typography.bodySize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Status badge
                    if updateService.updateState == .idle || updateService.updateState == .noUpdate {
                        HStack(spacing: GlassTokens.Spacing.xs) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Up to date")
                                .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                                .foregroundColor(GlassTokens.Colors.textPrimary)
                        }
                        .padding(.horizontal, GlassTokens.Spacing.sm)
                        .padding(.vertical, GlassTokens.Spacing.xs)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(GlassTokens.Radius.pill)
                    }
                }
                
                // Current Version and Check for Updates
                HStack(spacing: GlassTokens.Spacing.lg) {
                    // Current Version box
                    HStack(spacing: GlassTokens.Spacing.sm) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(GlassTokens.Colors.accent)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Version")
                                .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                                .foregroundColor(GlassTokens.Colors.textPrimary)
                            
                            Text("v\(currentAppVersion) (\(updateService.currentChannel.displayText))")
                                .font(.system(size: GlassTokens.Typography.captionSize))
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                        }
                    }
                    .padding(GlassTokens.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GlassTokens.Colors.backgroundSecondary)
                    .cornerRadius(GlassTokens.Radius.md)
                    
                    // Check for Updates button
                    Button {
                        updateService.checkForUpdates()
                    } label: {
                        HStack(spacing: GlassTokens.Spacing.xs) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: GlassTokens.Typography.bodySize))
                            Text("Check for Updates")
                                .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, GlassTokens.Spacing.lg)
                        .padding(.vertical, GlassTokens.Spacing.md)
                        .background(GlassTokens.Colors.accent)
                        .cornerRadius(GlassTokens.Radius.md)
                    }
                    .buttonStyle(.plain)
                    .disabled(updateService.isUpdating)
                }
                
                // Update Channel and Auto-download
                HStack(alignment: .top, spacing: GlassTokens.Spacing.lg) {
                    // Update Channel
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                        Text("Update Channel")
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                            .foregroundColor(GlassTokens.Colors.textPrimary)
                        
                        Picker("", selection: Binding(
                            get: { updateService.currentChannel },
                            set: { newChannel in
                                viewModel.settings.updateChannel = newChannel
                                updateService.switchChannel(to: newChannel)
                            }
                        )) {
                            Text("Stable (Recommended)").tag(AppSettings.UpdateChannel.stable)
                            Text("Beta").tag(AppSettings.UpdateChannel.beta)
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .labelsHidden()
                        
                        Text("Beta builds may be unstable but offer the latest Rust tooling features.")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Auto-download
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                        Text("Auto-download")
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                            .foregroundColor(GlassTokens.Colors.textPrimary)
                        
                        Toggle("", isOn: Binding(
                            get: { updateService.automaticallyDownloadsUpdates },
                            set: { updateService.automaticallyDownloadsUpdates = $0 }
                        ))
                        .toggleStyle(.switch)
                        
                        Text("Automatically download updates")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var currentAppVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }

    // MARK: - Danger Zone Section

    @ViewBuilder
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Header
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: GlassTokens.Typography.headlineSize))
                    .foregroundColor(.red)
                
                Text("Danger Zone")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            }
            
            // Reset Application subsection
            HStack(alignment: .top, spacing: GlassTokens.Spacing.lg) {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                    Text("Reset Application")
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                    
                    Text("This will delete all local configuration files and reset project defaults to their original state.")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                    
                    Text("This action is irreversible.")
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button("Reset All Settings") {
                    viewModel.showResetConfirmation = true
                }
                .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, GlassTokens.Spacing.lg)
                .padding(.vertical, GlassTokens.Spacing.md)
                .background(Color.red)
                .cornerRadius(GlassTokens.Radius.md)
                .buttonStyle(.plain)
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
        .padding(GlassTokens.Spacing.lg)
        .background(Color.red.opacity(0.05))
        .cornerRadius(GlassTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.lg)
                .stroke(Color.red.opacity(0.2), lineWidth: GlassTokens.Stroke.thin)
        )
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
