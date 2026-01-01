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
            VStack(alignment: .leading, spacing: 24) {
                // Header
                taskHeader

                Divider()

                // Metadata
                taskMetadata

                if task.status == .failed {
                    Divider()

                    // Error information
                    errorSection

                    if task.suggestedFix != nil {
                        Divider()

                        // Suggested fix
                        suggestedFixSection
                    }
                }

                if task.stdoutSnippet != nil || task.stderrSnippet != nil {
                    Divider()

                    // Output
                    outputSection
                }

                Spacer()
            }
            .padding(24)
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
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(task.status.color.opacity(0.2))
                    .frame(width: 60, height: 60)

                if task.status == .running {
                    ProgressView()
                        .scaleEffect(1.2)
                } else {
                    Image(systemName: task.status.icon)
                        .font(.largeTitle)
                        .foregroundStyle(task.status.color)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.operation)
                    .font(.title.bold())

                if let target = task.target {
                    Text(target)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(task.status.rawValue.capitalized)
                    .font(.subheadline.bold())
                    .foregroundStyle(task.status.color)
            }
        }
    }

    // MARK: - Metadata

    @ViewBuilder
    private var taskMetadata: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Information")
                .font(.headline)

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
                    valueColor: exitCode == 0 ? .green : .red
                )
            }
        }
    }

    // MARK: - Error Section

    @ViewBuilder
    private var errorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Error Details")
                    .font(.headline)
            }

            if let errorMessage = task.errorMessage {
                Text(errorMessage)
                    .font(.body)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Suggested Fix

    @ViewBuilder
    private var suggestedFixSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.orange)
                Text("Suggested Fix")
                    .font(.headline)
            }

            if let fix = task.suggestedFix {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                    Text(fix)
                        .font(.body)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Output Section

    @ViewBuilder
    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Command Output")
                .font(.headline)

            if let stdout = task.stdoutSnippet {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Standard Output:")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(stdout)
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }

            if let stderr = task.stderrSnippet {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Standard Error:")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(stderr)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.red)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func metadataRow(label: String, value: String, icon: String, valueColor: Color? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body)
                    .foregroundStyle(valueColor ?? .primary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(6)
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
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.1f seconds", duration)
        } else {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(minutes) minutes \(seconds) seconds"
        }
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
