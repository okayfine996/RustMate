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
            // Filter bar
            filterBar

            Divider()

            if viewModel.filteredTasks.isEmpty {
                emptyState
            } else {
                tasksList
            }
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    viewModel.clearCompleted()
                } label: {
                    Label("Clear Completed", systemImage: "trash")
                }
                .disabled(viewModel.filteredTasks.filter { $0.status != .running }.isEmpty)
            }
        }
    }

    // MARK: - Filter Bar

    @ViewBuilder
    private var filterBar: some View {
        HStack(spacing: 12) {
            ForEach(TasksViewModel.TaskFilter.allCases, id: \.self) { filter in
                Button {
                    viewModel.filter = filter
                } label: {
                    HStack(spacing: 4) {
                        Text(filter.rawValue)
                            .font(.subheadline)

                        if filter == .running && viewModel.runningCount > 0 {
                            Text("\(viewModel.runningCount)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }

                        if filter == .failed && viewModel.failedCount > 0 {
                            Text("\(viewModel.failedCount)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(viewModel.filter == filter ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
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
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("No Tasks")
                .font(.title.bold())

            Text(emptyStateMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateMessage: String {
        switch viewModel.filter {
        case .all:
            return "No tasks have been run yet.\nPerform operations to see them here."
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
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(task.status.color.opacity(0.2))
                    .frame(width: 40, height: 40)

                if task.status == .running {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: task.status.icon)
                        .font(.title3)
                        .foregroundStyle(task.status.color)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.operation)
                        .font(.body.bold())

                    if let target = task.target {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(target)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Label(formatTime(task.startTime), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let duration = task.duration {
                        Label(formatDuration(duration), systemImage: "timer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if task.status == .failed, task.suggestedFix != nil {
                        Label("Has Fix", systemImage: "lightbulb")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Status badge
            Text(task.status.rawValue.capitalized)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(task.status.color)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(seconds)s"
        }
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
