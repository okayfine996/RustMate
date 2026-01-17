//
//  ProjectHeader.swift
//  RustMate
//
//  Project header with breadcrumbs, title, and action buttons
//

import SwiftUI

struct ProjectHeader: View {
    let projectPath: String
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Breadcrumb
            breadcrumb

            // Title and description with action buttons
            HStack(alignment: .top, spacing: GlassTokens.Spacing.lg) {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    Text(title)
                        .font(.system(size: GlassTokens.Typography.displaySize, weight: .bold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    Text(description)
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }

                Spacer()

                // Header action icons
                actionButtons
            }
        }
    }

    // MARK: - Breadcrumb

    @ViewBuilder
    private var breadcrumb: some View {
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
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
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

    // MARK: - Helpers

    private var projectName: String {
        URL(fileURLWithPath: projectPath).lastPathComponent
    }

    private func openInFolder() {
        let url = URL(fileURLWithPath: projectPath)
        NSWorkspace.shared.open(url)
    }

    private func openInTerminal() {
        let script = """
        #!/bin/bash
        cd "\(projectPath)"
        exec $SHELL
        """

        let tempDir = FileManager.default.temporaryDirectory
        let commandFile = tempDir.appendingPathComponent("open-project-\(UUID().uuidString).command")

        do {
            try script.write(to: commandFile, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: commandFile.path)

            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            task.arguments = ["-a", "Terminal.app", commandFile.path]

            try task.run()

            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                try? FileManager.default.removeItem(at: commandFile)
            }
        } catch {
            print("Failed to open Terminal: \(error)")
        }
    }
}
