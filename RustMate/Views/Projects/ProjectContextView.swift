//
//  ProjectContextView.swift
//  RustMate
//
//  Detailed view showing project toolchain context and override management
//  Feature: 004-glass-ui-refresh - Priority-based configuration layout
//

import SwiftUI
import AppKit

struct ProjectContextView: View {
    let context: ProjectContextInfo
    let availableToolchains: [ToolchainInfo]
    let onSetOverride: (ToolchainInfo) -> Void
    let onClearOverride: () -> Void

    @State private var showingOverridePicker = false
    @State private var selectedTab: ProjectTab = .toolchain
    @StateObject private var diagnosticsViewModel = ProjectDiagnosticsViewModel()

    enum ProjectTab: String, CaseIterable {
        case toolchain = "Toolchain Version"
        case cargo = "Cargo & Build"
        case info = "Diagnostics"
        
        var icon: String {
            switch self {
            case .toolchain: return "wrench.and.screwdriver"
            case .cargo: return "doc.text"
            case .info: return "exclamationmark.triangle"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Project header
            projectHeader
                .padding(GlassTokens.Spacing.xl)
            
            Divider()
            
            // Tab selector
            tabSelector
            
            Divider()
            
            // Tab content
            tabContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            // Load diagnostics when view appears for badge count
            await diagnosticsViewModel.loadDiagnostics(projectPath: context.projectPath)
        }
        .onChange(of: context.projectPath) { _, newPath in
            // Reload diagnostics when project changes
            Task {
                await diagnosticsViewModel.loadDiagnostics(projectPath: newPath)
            }
        }
        .onChange(of: selectedTab) { _, _ in
            // Reload diagnostics when switching to diagnostics tab
            if selectedTab == .info {
                Task {
                    await diagnosticsViewModel.loadDiagnostics(projectPath: context.projectPath)
                }
            }
        }
    }
    
    // MARK: - Tab Selector
    
    @ViewBuilder
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ProjectTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(GlassTokens.Animation.fast) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: GlassTokens.Spacing.xs) {
                        Image(systemName: tab.icon)
                            .font(.system(size: GlassTokens.Typography.bodySize))
                            .foregroundColor(selectedTab == tab ? GlassTokens.Colors.accent : GlassTokens.Colors.textSecondary)
                        
                        Text(tab.rawValue)
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                            .foregroundColor(selectedTab == tab ? GlassTokens.Colors.accent : GlassTokens.Colors.textPrimary)
                        
                        // Badge for Diagnostics tab
                        if tab == .info {
                            let issueCount = diagnosticsViewModel.issueCount
                            if issueCount > 0 {
                                Text("\(issueCount)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.brown.opacity(0.8))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, GlassTokens.Spacing.lg)
                    .padding(.vertical, GlassTokens.Spacing.md)
                    .overlay(
                        Rectangle()
                            .frame(height: selectedTab == tab ? 2 : 0)
                            .foregroundColor(GlassTokens.Colors.accent),
                        alignment: .bottom
                    )
                }
                .buttonStyle(.plain)
            }
//            .background(GlassTokens.Colors.backgroundSecondary)
            
            Spacer()
        }
        
//        .background(GlassTokens.Colors.backgroundSecondary)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(GlassTokens.Colors.divider),
            alignment: .bottom
        )
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .toolchain:
                ProjectToolchainSettingsView(projectPath: context.projectPath)
            case .cargo:
                ProjectCargoSettingsView(projectPath: context.projectPath)
            case .info:
                ProjectDiagnosticsView(projectPath: context.projectPath)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Project Header

    @ViewBuilder
    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Breadcrumb
            HStack(spacing: GlassTokens.Spacing.xs) {
                Text("Projects")
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                Text(projectName)
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }

            // Title and description
            HStack(alignment: .top, spacing: GlassTokens.Spacing.lg) {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    Text(headerTitle)
                        .font(.system(size: GlassTokens.Typography.displaySize, weight: .bold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                    
                    Text(headerDescription)
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                // Header action icons
                HStack(spacing: GlassTokens.Spacing.md) {
                    Button {
                        openInFolder()
                    } label: {
                        Image(systemName: "folder")
                            .font(.system(size: GlassTokens.Typography.bodySize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Open in Finder")
                    
                    Button {
                        openInTerminal()
                    } label: {
                        Image(systemName: "terminal")
                            .font(.system(size: GlassTokens.Typography.bodySize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Open in Terminal")
                }
            }
        }
    }
    
    private var headerTitle: String {
        switch selectedTab {
        case .toolchain: return "Toolchain Settings"
        case .cargo: return "Cargo & Build Settings"
        case .info: return "Project Diagnostics"
        }
    }
    
    private var headerDescription: String {
        switch selectedTab {
        case .toolchain: return "Configure the Rust environment for `rust-toolchain.toml`"
        case .cargo: return "Configure build settings for `.cargo/config.toml`"
        case .info: return "View detailed information about your project's toolchain configuration"
        }
    }
    
    private func refreshProject() async {
        // Refresh project context
        // This would need to be passed from parent or accessed via environment
    }

    private var projectName: String {
        URL(fileURLWithPath: context.projectPath).lastPathComponent
    }
    
    private func openInFolder() {
        let url = URL(fileURLWithPath: context.projectPath)
        NSWorkspace.shared.open(url)
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
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                try? FileManager.default.removeItem(at: commandFile)
            }
        } catch {
            print("❌ Failed to open Terminal: \(error)")
        }
    }
    
    private func openInVSCode() {
        // Try to open the project in VS Code using the 'code' command
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["code", context.projectPath]
        
        do {
            try task.run()
            print("✅ Successfully opened VS Code")
        } catch {
            // If 'code' command is not available, try opening with the app bundle
            let vsCodeURL = URL(fileURLWithPath: "/Applications/Visual Studio Code.app")
            if FileManager.default.fileExists(atPath: vsCodeURL.path) {
                let openTask = Process()
                openTask.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                openTask.arguments = ["-a", vsCodeURL.path, context.projectPath]
                try? openTask.run()
            } else {
                print("❌ VS Code not found. Please install VS Code or add 'code' to your PATH.")
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
