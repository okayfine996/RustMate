//
//  SettingsView.swift
//  RustMate
//
//  Application settings and configuration
//  Refactored: Extracted sections into separate components
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var updateService: AppUpdateService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSection: SettingsSection = .general

    // T004: Accept Binding<AppSettings> for single source of truth
    init(settingsBinding: Binding<AppSettings>) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(settingsBinding: settingsBinding))
    }

    var body: some View {
        HSplitView {
            // Left sidebar navigation
            SettingsSidebar(selectedSection: $selectedSection)
                .frame(minWidth: 220, idealWidth: 250, maxWidth: 280)

            // Right content area
            contentArea
        }
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

    // MARK: - Breadcrumbs and Header

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

    // MARK: - Content Views

    @ViewBuilder
    private var generalContentView: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
            // Rustup Configuration
            RustupConfigurationSection(viewModel: viewModel)

            // UI Preferences (including notifications)
            UIPreferencesSection(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var permissionsContentView: some View {
        PermissionsSection(viewModel: viewModel)
    }

    @ViewBuilder
    private var advancedContentView: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
            // Application Updates
            UpdatesSection(viewModel: viewModel, updateService: updateService)

            // Danger Zone
            DangerZoneSection(viewModel: viewModel)
        }
    }
}

// MARK: - Settings Section Enum

enum SettingsSection: String, CaseIterable {
    case general = "General"
    case permissions = "Permissions"
    case advanced = "Advanced"

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .permissions: return "lock.shield"
        case .advanced: return "slider.horizontal.3"
        }
    }
}

// MARK: - Previews

#Preview("General Tab") {
    @State var settings = AppSettings()
    return SettingsView(settingsBinding: $settings)
        .environmentObject(AppUpdateService())
        .frame(width: 1000, height: 700)
}

#Preview("Permissions Tab") {
    @State var settings = AppSettings()
    return SettingsView(settingsBinding: $settings)
        .environmentObject(AppUpdateService())
        .frame(width: 1000, height: 700)
}

#Preview("Advanced Tab") {
    @State var settings = AppSettings()
    return SettingsView(settingsBinding: $settings)
        .environmentObject(AppUpdateService())
        .frame(width: 1000, height: 700)
}
