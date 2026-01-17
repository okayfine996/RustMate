//
//  UpdatesSection.swift
//  RustMate
//
//  Application updates section for Settings
//

import SwiftUI

struct UpdatesSection: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var updateService: AppUpdateService

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                // Header with status badge
                headerSection

                // Current Version and Check for Updates
                versionAndCheckSection

                // Update Channel and Auto-download
                channelAndAutoDownloadSection
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
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
    }

    // MARK: - Version and Check Section

    @ViewBuilder
    private var versionAndCheckSection: some View {
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
    }

    // MARK: - Channel and Auto-download Section

    @ViewBuilder
    private var channelAndAutoDownloadSection: some View {
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

    // MARK: - Helper Properties

    private var currentAppVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }
}
