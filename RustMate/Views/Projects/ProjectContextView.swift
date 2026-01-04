//
//  ProjectContextView.swift
//  RustMate
//
//  Detailed view showing project toolchain context and override management
//  Feature: 004-glass-ui-refresh - Priority-based configuration layout
//

import SwiftUI

struct ProjectContextView: View {
    let context: ProjectContextInfo
    let availableToolchains: [ToolchainInfo]
    let onSetOverride: (ToolchainInfo) -> Void
    let onClearOverride: () -> Void

    @State private var showingOverridePicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
                // Project header
                projectHeader

                // Active toolchain card
                activeToolchainCard

                // Configuration source priority
                configurationSourcePriority
            }
            .padding(GlassTokens.Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Project Header

    @ViewBuilder
    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Breadcrumb path
            HStack(spacing: GlassTokens.Spacing.xs) {
                Image(systemName: "folder.fill")
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)

                Text(context.projectPath)
                    .font(.system(size: GlassTokens.Typography.captionSize, design: .monospaced))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }

            // Project title and actions
            HStack(spacing: GlassTokens.Spacing.lg) {
                Text(projectName)
                    .font(.system(size: GlassTokens.Typography.displaySize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Spacer()

                // Action buttons
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Button {
                        // Open folder action
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: context.projectPath)
                    } label: {
                        HStack(spacing: GlassTokens.Spacing.xs) {
                            Image(systemName: "folder.fill")
                            Text("Open Folder")
                        }
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                        .padding(.horizontal, GlassTokens.Spacing.md)
                        .padding(.vertical, GlassTokens.Spacing.sm)
                    }
                    .secondaryGlassButtonStyle()

                    Button {
                        // Open terminal action
                        openInTerminal()
                    } label: {
                        HStack(spacing: GlassTokens.Spacing.xs) {
                            Image(systemName: "terminal.fill")
                            Text("Terminal")
                        }
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                        .padding(.horizontal, GlassTokens.Spacing.md)
                        .padding(.vertical, GlassTokens.Spacing.sm)
                    }
                    .secondaryGlassButtonStyle()
                }
            }
        }
    }

    private var projectName: String {
        URL(fileURLWithPath: context.projectPath).lastPathComponent
    }

    private func openInTerminal() {
        // Create a shell script that changes to the directory
        let script = """
        #!/bin/bash
        cd "\(context.projectPath)"
        exec $SHELL
        """

        // Save script to a temporary .command file
        let tempDir = FileManager.default.temporaryDirectory
        let commandFile = tempDir.appendingPathComponent("open-project-\(UUID().uuidString).command")

        do {
            // Write the script
            try script.write(to: commandFile, atomically: true, encoding: .utf8)

            // Make it executable
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: commandFile.path)

            // Open it with Terminal
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            task.arguments = ["-a", "Terminal.app", commandFile.path]

            try task.run()
            print("✅ Successfully opened Terminal")

            // Keep the file for a bit longer to ensure Terminal has time to execute it
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                try? FileManager.default.removeItem(at: commandFile)
                print("🗑️ Cleaned up temporary command file")
            }
        } catch {
            print("❌ Failed to open Terminal: \(error)")

            // Fallback: just open Terminal and copy path to clipboard
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("cd \"\(context.projectPath)\"", forType: .string)

            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            task.arguments = ["-a", "Terminal.app"]

            do {
                try task.run()
                print("✅ Opened Terminal, path copied to clipboard")
            } catch {
                print("❌ Failed to open Terminal: \(error)")
            }
        }
    }

    // MARK: - Active Toolchain Card

    @ViewBuilder
    private var activeToolchainCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
                // Header with badge
                HStack {
                    Text("ACTIVE TOOLCHAIN")
                        .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                        .tracking(0.5)

                    Spacer()

                    StatusBadgeView(status: .success, text: "Active")
                }

                // Toolchain name with icon
                HStack(spacing: GlassTokens.Spacing.md) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: GlassTokens.Typography.titleSize))
                        .foregroundColor(GlassTokens.Colors.accent)

                    Text(context.activeToolchain)
                        .font(.system(size: GlassTokens.Typography.titleSize, weight: .bold, design: .monospaced))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    Spacer()
                }

                // Action buttons
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Menu {
                        ForEach(availableToolchains) { toolchain in
                            Button {
                                onSetOverride(toolchain)
                            } label: {
                                HStack {
                                    Text(toolchain.name)
                                    if toolchain.isDefault {
                                        Text("(default)")
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if context.activeToolchain == toolchain.name {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: GlassTokens.Spacing.xs) {
                            Image(systemName: "pencil")
                            Text("Set Override")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .primaryGlassButtonStyle()
                    .disabled(availableToolchains.isEmpty)

                    if context.reason != .default {
                        Button {
                            onClearOverride()
                        } label: {
                            HStack(spacing: GlassTokens.Spacing.xs) {
                                Image(systemName: "trash")
                                Text("Clear Override")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .destructiveGlassButtonStyle()
                    }
                }
            }
        }
    }

    // MARK: - Configuration Source Priority

    @ViewBuilder
    private var configurationSourcePriority: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
            // Section header
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text("Configuration Source Priority")
                    .font(.system(size: GlassTokens.Typography.titleSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text("Rustup checks these locations in order to determine which toolchain to use.")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }

            // Priority list
            VStack(spacing: 0) {
                // 1. Environment Variable
                prioritySourceItem(
                    icon: context.reason == .environment ? "checkmark.circle.fill" : "circle",
                    iconColor: context.reason == .environment ? GlassTokens.Colors.success : GlassTokens.Colors.textSecondary.opacity(0.3),
                    title: "Environment Variable",
                    description: context.reason == .environment ? "Set via RUSTUP_TOOLCHAIN" : "Not set",
                    badge: "RUSTUP_TOOLCHAIN",
                    badgeStatus: context.reason == .environment ? .info : .default,
                    isActive: context.reason == .environment,
                    showDivider: true
                )

                // 2. Directory Toolchain File
                prioritySourceItem(
                    icon: context.reason == .toolchainFile ? "checkmark.circle.fill" : "circle",
                    iconColor: context.reason == .toolchainFile ? GlassTokens.Colors.success : GlassTokens.Colors.textSecondary.opacity(0.3),
                    title: "Directory Toolchain File",
                    description: context.reason == .toolchainFile ? "Found in \(context.sourcePath?.components(separatedBy: "/").last ?? "rust-toolchain.toml")" : "No rust-toolchain.toml found",
                    badge: context.reason == .toolchainFile ? (context.sourcePath?.contains("channel") == true ? "channel = \"\(context.activeToolchain)\"" : context.activeToolchain) : nil,
                    badgeStatus: .info,
                    isActive: context.reason == .toolchainFile,
                    showDivider: true
                )

                // 3. Directory Override
                prioritySourceItem(
                    icon: context.reason == .override ? "checkmark.circle.fill" : "circle",
                    iconColor: context.reason == .override ? GlassTokens.Colors.success : GlassTokens.Colors.textSecondary.opacity(0.3),
                    title: "Directory Override",
                    description: context.reason == .override ? "Manual override set for this path" : "No manual override set for this path",
                    badge: "rustup override",
                    badgeStatus: context.reason == .override ? .info : .default,
                    isActive: context.reason == .override,
                    showDivider: true
                )

                // 4. System Default
                prioritySourceItem(
                    icon: context.reason == .default ? "checkmark.circle.fill" : "slash.circle",
                    iconColor: context.reason == .default ? GlassTokens.Colors.success : GlassTokens.Colors.textSecondary.opacity(0.3),
                    title: "System Default",
                    description: context.reason == .default ? "Using system default toolchain" : "Ignored due to higher priority source",
                    badge: "stable",
                    badgeStatus: context.reason == .default ? .info : .default,
                    isActive: context.reason == .default,
                    showDivider: false
                )
            }
        }
    }

    @ViewBuilder
    private func prioritySourceItem(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        badge: String?,
        badgeStatus: StatusBadgeView.BadgeStatus,
        isActive: Bool,
        showDivider: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: GlassTokens.Spacing.lg) {
                // Icon - larger circle
                ZStack {
                    Circle()
                        .fill(isActive ? iconColor.opacity(0.15) : Color.clear)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                .frame(width: 48)

                // Content
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                    HStack(spacing: GlassTokens.Spacing.sm) {
                        Text(title)
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        if isActive {
                            Text("ACTIVE SOURCE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(GlassTokens.Colors.accent)
                                .padding(.horizontal, GlassTokens.Spacing.sm)
                                .padding(.vertical, 3)
                                .background(GlassTokens.Colors.accentSubtle)
                                .cornerRadius(GlassTokens.Radius.sm)
                        }

                        Spacer()

                        if let badge = badge, !isActive || !badge.contains("=") {
                            Text(badge)
                                .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium, design: .monospaced))
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                                .padding(.horizontal, GlassTokens.Spacing.sm)
                                .padding(.vertical, 3)
                                .background(GlassTokens.Colors.cardBackground.opacity(0.5))
                                .cornerRadius(GlassTokens.Radius.sm)
                        }
                    }

                    Text(description)
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)

                    // Show code snippet for toolchain file if active
                    if isActive, let badge = badge, badge.contains("=") {
                        HStack(spacing: GlassTokens.Spacing.xs) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: GlassTokens.Typography.captionSize))
                                .foregroundColor(GlassTokens.Colors.textSecondary)

                            Text(badge)
                                .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                                .foregroundColor(GlassTokens.Colors.textPrimary)
                        }
                        .padding(GlassTokens.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(GlassTokens.Colors.cardBackground.opacity(0.3))
                        .cornerRadius(GlassTokens.Radius.sm)
                    }
                }
            }
            .padding(GlassTokens.Spacing.lg)
            .background(isActive ? GlassTokens.Colors.accentSubtle.opacity(0.1) : Color.clear)
            .cornerRadius(GlassTokens.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                    .stroke(isActive ? GlassTokens.Colors.accent : Color.clear, lineWidth: 2)
            )

            if showDivider && !isActive {
                Divider()
                    .padding(.leading, 64)
                    .padding(.top, GlassTokens.Spacing.sm)
            }
        }
        .padding(.bottom, showDivider ? GlassTokens.Spacing.sm : 0)
    }

}

// MARK: - Previews

#Preview("Default Toolchain") {
    let context = ProjectContextInfo(
        projectPath: "/Users/user/projects/my-rust-app",
        activeToolchain: "stable-aarch64-apple-darwin",
        reason: .default,
        sourcePath: nil
    )

    let toolchains = [
        ToolchainInfo(
            name: "stable-aarch64-apple-darwin",
            version: "1.75.0",
            isDefault: true,
            installDate: Date(),
            host: "aarch64-apple-darwin"
        ),
        ToolchainInfo(
            name: "nightly-aarch64-apple-darwin",
            version: "1.77.0-nightly",
            isDefault: false,
            installDate: Date(),
            host: "aarch64-apple-darwin"
        )
    ]

    return ProjectContextView(
        context: context,
        availableToolchains: toolchains,
        onSetOverride: { _ in },
        onClearOverride: { }
    )
    .frame(width: 600, height: 600)
}

#Preview("Toolchain File Override") {
    let context = ProjectContextInfo(
        projectPath: "/Users/user/projects/my-rust-app",
        activeToolchain: "nightly-aarch64-apple-darwin",
        reason: .toolchainFile,
        sourcePath: "/Users/user/projects/my-rust-app/rust-toolchain.toml"
    )

    let toolchains = [
        ToolchainInfo(
            name: "stable-aarch64-apple-darwin",
            version: "1.75.0",
            isDefault: true,
            installDate: Date(),
            host: "aarch64-apple-darwin"
        ),
        ToolchainInfo(
            name: "nightly-aarch64-apple-darwin",
            version: "1.77.0-nightly",
            isDefault: false,
            installDate: Date(),
            host: "aarch64-apple-darwin"
        )
    ]

    return ProjectContextView(
        context: context,
        availableToolchains: toolchains,
        onSetOverride: { _ in },
        onClearOverride: { }
    )
    .frame(width: 600, height: 600)
}
