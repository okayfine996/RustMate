//
//  TasksListView.swift
//  RustMate
//
//  View for displaying task status and history
//

import SwiftUI

struct TasksListView: View {
    @EnvironmentObject var viewModel: TasksViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding(.horizontal)
                .padding(.vertical,GlassTokens.Spacing.xxl)

            Divider()

            // Filter bar
            filterBar
                .padding(GlassTokens.Spacing.lg)

            Divider()

            // Content
            if viewModel.filteredTasks.isEmpty {
                emptyState
            } else {
                tasksList
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
            Text("Tasks")
                .font(.system(size: GlassTokens.Typography.displaySize, weight: .bold))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            Text("View and manage background operations. Track the status of toolchain installations, updates, and other operations.")
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .lineLimit(2)
//                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Filter Bar

    @ViewBuilder
    private var filterBar: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            SegmentedChipsView(
                options: TasksViewModel.TaskFilter.allCases,
                displayName: { filter in
                    var name = filter.rawValue
                    if filter == .running && viewModel.runningCount > 0 {
                        name += " (\(viewModel.runningCount))"
                    } else if filter == .failed && viewModel.failedCount > 0 {
                        name += " (\(viewModel.failedCount))"
                    }
                    return name
                },
                selection: $viewModel.filter
            )

            Spacer()
        }
    }

    // MARK: - Tasks List

    @ViewBuilder
    private var tasksList: some View {
        List(viewModel.filteredTasks, selection: $viewModel.selectedTask) { task in
            TaskRowView(task: task)
                .tag(task)
                .contextMenu {
                    if task.errorMessage != nil {
                        Button {
                            copyError(task)
                        } label: {
                            Label("Copy Error", systemImage: "doc.on.doc")
                        }
                    }

                    Button {
                        viewModel.removeTask(task.id)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
        }
        .listStyle(.inset)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        EmptyStateView(
            icon: emptyStateIcon,
            title: "No Tasks",
            description: emptyStateMessage
        )
    }

    private var emptyStateIcon: String {
        switch viewModel.filter {
        case .all:
            return "tray"
        case .running:
            return "arrow.triangle.2.circlepath"
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .cancelled:
            return "slash.circle"
        }
    }

    private var emptyStateMessage: String {
        switch viewModel.filter {
        case .all:
            return "No tasks have been run yet. Perform operations to see them here."
        case .running:
            return "No tasks are currently running."
        case .success:
            return "No successful tasks to display."
        case .failed:
            return "No failed tasks to display."
        case .cancelled:
            return "No cancelled tasks to display."
        }
    }

    // MARK: - Actions

    private func copyError(_ task: TaskRecord) {
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
}

// MARK: - Task Row

struct TaskRowView: View {
    let task: TaskRecord

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: GlassTokens.Spacing.md) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(
                            StatusSemantics.taskColor(status: task.status)
                                .opacity(0.15)
                        )
                        .frame(width: 40, height: 40)

                    if task.status == .running {
                        ProgressView()
                            .scaleEffect(0.8)
                            .controlSize(.small)
                    } else {
                        Image(systemName: StatusSemantics.taskIcon(status: task.status))
                            .font(.system(size: GlassTokens.Typography.headlineSize))
                            .foregroundColor(StatusSemantics.taskColor(status: task.status))
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    HStack(spacing: GlassTokens.Spacing.sm) {
                        Text(task.operation)
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        if let target = task.target {
                            Text("·")
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                            Text(target)
                                .font(.system(size: GlassTokens.Typography.bodySize))
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                        }

                        let badge = StatusSemantics.taskBadge(status: task.status)
                        StatusBadgeView(status: badge.status, text: badge.text)
                    }

                    HStack(spacing: GlassTokens.Spacing.md) {
                        Label(formatTime(task.startTime), systemImage: "clock")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)

                        if let duration = task.duration {
                            Label(formatDuration(duration), systemImage: "timer")
                                .font(.system(size: GlassTokens.Typography.captionSize))
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                        } else if task.status == .running {
                            // Show elapsed time for running tasks
                            Label(formatElapsed(from: task.startTime), systemImage: "timer")
                                .font(.system(size: GlassTokens.Typography.captionSize))
                                .foregroundColor(StatusSemantics.taskColor(status: .running))
                        }

                        if task.status == .failed, task.suggestedFix != nil {
                            Label("Has Fix", systemImage: "lightbulb")
                                .font(.system(size: GlassTokens.Typography.captionSize))
                                .foregroundColor(GlassTokens.Colors.warning)
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical, GlassTokens.Spacing.xs)

            // Progress bar for running tasks
            if task.status == .running {
                ProgressView()
                    .progressViewStyle(.linear)
                    .padding(.top, GlassTokens.Spacing.xs)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        DateFormatters.formatTime(date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        DateFormatters.formatDuration(duration)
    }

    private func formatElapsed(from startTime: Date) -> String {
        DateFormatters.formatElapsed(from: startTime)
    }
}

// MARK: - Previews

#Preview {
    let viewModel = TasksViewModel()

    // Add sample tasks
    viewModel.addTask(TaskRecord(
        id: UUID(),
        operation: "Install Toolchain",
        target: "stable",
        status: .success,
        startTime: Date().addingTimeInterval(-120),
        endTime: Date(),
        exitCode: 0,
        stdoutSnippet: "info: syncing channel updates for 'stable'",
        stderrSnippet: nil,
        errorMessage: nil,
        suggestedFix: nil
    ))

    viewModel.addTask(TaskRecord(
        id: UUID(),
        operation: "Update Toolchain",
        target: "nightly",
        status: .running,
        startTime: Date().addingTimeInterval(-30),
        endTime: nil,
        exitCode: nil,
        stdoutSnippet: nil,
        stderrSnippet: nil,
        errorMessage: nil,
        suggestedFix: nil
    ))

    return NavigationStack {
        TasksListView()
            .environmentObject(viewModel)
    }
}
