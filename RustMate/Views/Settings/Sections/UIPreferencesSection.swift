//
//  UIPreferencesSection.swift
//  RustMate
//
//  UI preferences and notifications section for Settings
//

import SwiftUI

struct UIPreferencesSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
            // UI Preferences
            uiPreferencesCard

            // Notifications
            notificationsCard
        }
    }

    // MARK: - UI Preferences Card

    @ViewBuilder
    private var uiPreferencesCard: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            Text("UI Preferences")
                .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            GlassCard {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                    // Appearance Mode
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                        Text("Appearance")
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        HStack(spacing: GlassTokens.Spacing.sm) {
                            ForEach([AppSettings.AppearanceMode.light, .dark, .auto], id: \.self) { mode in
                                Button {
                                    viewModel.appearanceMode = mode
                                    viewModel.saveSettings()
                                } label: {
                                    HStack(spacing: GlassTokens.Spacing.xs) {
                                        Image(systemName: mode.icon)
                                            .font(.system(size: GlassTokens.Typography.bodySize))
                                        Text(mode.displayText)
                                            .font(.system(size: GlassTokens.Typography.bodySize))
                                    }
                                    .foregroundColor(viewModel.appearanceMode == mode ? .white : GlassTokens.Colors.textPrimary)
                                    .padding(.horizontal, GlassTokens.Spacing.md)
                                    .padding(.vertical, GlassTokens.Spacing.sm)
                                    .background(viewModel.appearanceMode == mode ? GlassTokens.Colors.accent : GlassTokens.Colors.backgroundSecondary)
                                    .cornerRadius(GlassTokens.Radius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                                            .stroke(viewModel.appearanceMode == mode ? GlassTokens.Colors.accent : GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

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
    }

    // MARK: - Notifications Card

    @ViewBuilder
    private var notificationsCard: some View {
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
