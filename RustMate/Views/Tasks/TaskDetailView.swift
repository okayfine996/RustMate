//
//  TaskDetailView.swift
//  RustMate
//
//  Detailed view for individual task with error information and suggested fixes
//

import SwiftUI

struct TaskDetailView: View {
    let task: TaskRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
                // Header
                taskHeader

                // Metadata
                taskMetadata

                if task.status == .failed {
                    // Error information
                    errorSection
                }

                if task.stdoutSnippet != nil || task.stderrSnippet != nil {
                    // Output
                    outputSection
                }

                Spacer()
            }
            .padding(GlassTokens.Spacing.xl)
        }
        .navigationTitle(task.operation)
        .navigationSubtitle(task.target ?? "")
        .toolbar {
            ToolbarItemGroup {
                if task.errorMessage != nil || task.stderrSnippet != nil {
                    Button {
                        copyError()
                    } label: {
                        Label("Copy Error", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var taskHeader: some View {
        GlassCard {
            HStack(spacing: GlassTokens.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(
                            StatusSemantics.taskColor(status: task.status)
                                .opacity(0.15)
                        )
                        .frame(width: 60, height: 60)

                    if task.status == .running {
                        ProgressView()
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: StatusSemantics.taskIcon(status: task.status))
                            .font(.system(size: 32))
                            .foregroundColor(StatusSemantics.taskColor(status: task.status))
                    }
                }

                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    HStack(spacing: GlassTokens.Spacing.sm) {
                        Text(task.operation)
                            .font(.system(size: GlassTokens.Typography.titleSize, weight: GlassTokens.Typography.titleWeight))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        let badge = StatusSemantics.taskBadge(status: task.status)
                        StatusBadgeView(status: badge.status, text: badge.text)
                    }

                    if let target = task.target {
                        Text(target)
                            .font(.system(size: GlassTokens.Typography.calloutSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Metadata

    @ViewBuilder
    private var taskMetadata: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                Text("Task Information")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                metadataRow(label: "Started", value: formatDateTime(task.startTime), icon: "clock")

                if let endTime = task.endTime {
                    metadataRow(label: "Completed", value: formatDateTime(endTime), icon: "clock.fill")
                }

                if let duration = task.duration {
                    metadataRow(label: "Duration", value: formatDuration(duration), icon: "timer")
                }

                if let exitCode = task.exitCode {
                    metadataRow(
                        label: "Exit Code",
                        value: "\(exitCode)",
                        icon: "number.circle",
                        valueColor: exitCode == 0 ? GlassTokens.Colors.success : GlassTokens.Colors.error
                    )
                }
            }
        }
    }

    // MARK: - Error Section

    @ViewBuilder
    private var errorSection: some View {
        if task.stderrSnippet != nil {
            ErrorCalloutView(
                title: "Task Failed",
                message: task.errorMessage ?? "The operation failed with an unknown error.",
                suggestion: task.suggestedFix,
                secondaryActionTitle: "Copy Error",
                secondaryAction: copyError,
                errorDetails: task.stderrSnippet
            )
        } else {
            ErrorCalloutView(
                title: "Task Failed",
                message: task.errorMessage ?? "The operation failed with an unknown error.",
                suggestion: task.suggestedFix,
                errorDetails: nil
            )
        }
    }

    // MARK: - Output Section

    @ViewBuilder
    private var outputSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                Text("Command Output")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: GlassTokens.Typography.headlineWeight))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                if let stdout = task.stdoutSnippet {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                        Text("Standard Output:")
                            .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                            .foregroundColor(GlassTokens.Colors.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(stdout)
                                .font(.system(size: GlassTokens.Typography.captionSize, design: .monospaced))
                                .padding(GlassTokens.Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(GlassTokens.Colors.cardBackground)
                                .cornerRadius(GlassTokens.Radius.sm)
                        }
                    }
                }

                if let stderr = task.stderrSnippet {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                        Text("Standard Error:")
                            .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                            .foregroundColor(GlassTokens.Colors.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(stderr)
                                .font(.system(size: GlassTokens.Typography.captionSize, design: .monospaced))
                                .foregroundColor(GlassTokens.Colors.error)
                                .padding(GlassTokens.Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(GlassTokens.Colors.errorSubtle)
                                .cornerRadius(GlassTokens.Radius.sm)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func metadataRow(label: String, value: String, icon: String, valueColor: Color? = nil) -> some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: GlassTokens.Typography.headlineSize))
                .foregroundColor(GlassTokens.Colors.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text(label)
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)

                Text(value)
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(valueColor ?? GlassTokens.Colors.textPrimary)
            }

            Spacer()
        }
        .padding(GlassTokens.Spacing.md)
        .background(GlassTokens.Colors.cardBackground.opacity(0.5))
        .cornerRadius(GlassTokens.Radius.sm)
    }

    // MARK: - Actions

    private func copyError() {
        let errorText = """
        Operation: \(task.operation)
        Target: \(task.target ?? "N/A")
        Status: \(task.status.rawValue)
        Exit Code: \(task.exitCode ?? -1)

        Error Message:
        \(task.errorMessage ?? "Unknown error")

        Stderr:
        \(task.stderrSnippet ?? "No error output")

        Suggested Fix:
        \(task.suggestedFix ?? "No suggestions available")
        """

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(errorText, forType: .string)
    }

    // MARK: - Formatting

    private func formatDateTime(_ date: Date) -> String {
        DateFormatters.formatFullDateTime(date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        DateFormatters.formatDuration(duration, style: .verbose)
    }
}

// MARK: - Previews

#Preview("Failed Task") {
    NavigationStack {
        TaskDetailView(task: TaskRecord(
            id: UUID(),
            operation: "Install Toolchain",
            target: "nightly",
            status: .failed,
            startTime: Date().addingTimeInterval(-120),
            endTime: Date(),
            exitCode: 1,
            stdoutSnippet: "info: downloading component 'rust-std'",
            stderrSnippet: "error: could not download file from 'https://static.rust-lang.org/...'\nerror: network unreachable",
            errorMessage: "Failed to install toolchain: network error",
            suggestedFix: "Check your internet connection or try again later"
        ))
    }
}

#Preview("Success Task") {
    NavigationStack {
        TaskDetailView(task: TaskRecord(
            id: UUID(),
            operation: "Update Toolchain",
            target: "stable",
            status: .success,
            startTime: Date().addingTimeInterval(-60),
            endTime: Date(),
            exitCode: 0,
            stdoutSnippet: "info: updating existing installation for 'stable'\ninfo: checking for self-updates\nstable updated successfully",
            stderrSnippet: nil,
            errorMessage: nil,
            suggestedFix: nil
        ))
    }
}
