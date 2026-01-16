//
//  TasksViewModel.swift
//  RustMate
//
//  ViewModel for task monitoring and management
//

import Foundation
import Combine

@MainActor
class TasksViewModel: ObservableObject {
    @Published var tasks: [TaskRecord] = []
    @Published var selectedTask: TaskRecord?
    @Published var filter: TaskFilter = .all

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to task updates from TaskManager
        TaskManager.shared.taskPublisher
            .sink { [weak self] task in
                guard let self = self else { return }
                self.addTask(task)
            }
            .store(in: &cancellables)
    }

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case running = "Running"
        case success = "Successful"
        case failed = "Failed"
        case cancelled = "Cancelled"

        func matches(_ task: TaskRecord) -> Bool {
            switch self {
            case .all: return true
            case .running: return task.status == .running
            case .success: return task.status == .success
            case .failed: return task.status == .failed
            case .cancelled: return task.status == .cancelled
            }
        }
    }

    // MARK: - Computed Properties

    var filteredTasks: [TaskRecord] {
        tasks.filter { filter.matches($0) }
            .sorted { $0.startTime > $1.startTime }
    }

    var runningCount: Int {
        tasks.filter { $0.status == .running }.count
    }

    var failedCount: Int {
        tasks.filter { $0.status == .failed }.count
    }

    // MARK: - Task Management

    /// Add or update a task
    func addTask(_ task: TaskRecord) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.insert(task, at: 0)
        }

        // Auto-select newly added tasks
        if selectedTask == nil || selectedTask?.id == task.id {
            selectedTask = task
        }

        // Clean up old completed tasks (keep last 50)
        cleanupOldTasks()
    }

    /// Update task status
    func updateTask(_ taskId: UUID, status: TaskRecord.TaskStatus, endTime: Date? = nil, exitCode: Int? = nil, errorMessage: String? = nil) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }

        var task = tasks[index]
        tasks[index] = TaskRecord(
            id: task.id,
            operation: task.operation,
            target: task.target,
            status: status,
            startTime: task.startTime,
            endTime: endTime ?? task.endTime,
            exitCode: exitCode ?? task.exitCode,
            stdoutSnippet: task.stdoutSnippet,
            stderrSnippet: task.stderrSnippet,
            errorMessage: errorMessage ?? task.errorMessage,
            suggestedFix: task.suggestedFix
        )

        // Update selected task if it's the one being updated
        if selectedTask?.id == taskId {
            selectedTask = tasks[index]
        }
    }

    /// Remove a task from the list
    func removeTask(_ taskId: UUID) {
        tasks.removeAll { $0.id == taskId }

        if selectedTask?.id == taskId {
            selectedTask = filteredTasks.first
        }
    }

    /// Clear all completed tasks
    func clearCompleted() {
        tasks.removeAll { $0.status != .running }
        if let selected = selectedTask, selected.status != .running {
            selectedTask = filteredTasks.first
        }
    }

    /// Clear all tasks
    func clearAll() {
        tasks.removeAll()
        selectedTask = nil
    }

    // MARK: - Private Helpers

    private func cleanupOldTasks() {
        let maxTasks = 50
        guard tasks.count > maxTasks else { return }

        // Keep running tasks and the most recent completed tasks
        let runningTasks = tasks.filter { $0.status == .running }
        let completedTasks = tasks.filter { $0.status != .running }
            .sorted { $0.startTime > $1.startTime }
            .prefix(maxTasks - runningTasks.count)

        tasks = (runningTasks + completedTasks).sorted { $0.startTime > $1.startTime }
    }
}
