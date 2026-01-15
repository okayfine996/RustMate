//
//  TaskCoordinator.swift
//  RustMate
//
//  Coordinates task execution, tracking, and notifications
//  Eliminates duplicate task management code across ViewModels
//

import Foundation

/// Coordinates task execution with automatic tracking and notifications
/// This eliminates ~100+ lines of duplicate code across ViewModels
@MainActor
class TaskCoordinator {

    // MARK: - Dependencies

    private let taskManager: TaskManager
    private let notificationManager: TaskNotificationManager

    // MARK: - Initialization

    init(
        taskManager: TaskManager = .shared,
        notificationManager: TaskNotificationManager = .shared
    ) {
        self.taskManager = taskManager
        self.notificationManager = notificationManager
    }

    // MARK: - Core Execution

    /// Execute a tracked async operation
    /// - Parameters:
    ///   - operation: Operation name (e.g., "install", "uninstall")
    ///   - target: Optional target identifier (e.g., toolchain name)
    ///   - work: The async operation to execute, returns TaskResult
    /// - Returns: TaskResult with complete execution details
    func execute(
        operation: String,
        target: String?,
        work: () async throws -> TaskResult
    ) async -> TaskResult {
        let taskId = UUID()
        let startTime = Date()

        // 1. Create and track starting task
        let runningTask = TaskRecord(
            id: taskId,
            operation: operation,
            target: target,
            status: .running,
            startTime: startTime
        )
        await trackTaskStarted(runningTask)

        // 2. Execute the actual work
        let result: TaskResult
        do {
            result = try await work()
        } catch {
            // 3a. Work threw an exception - create failed task record
            let failedTask = TaskRecord(
                id: taskId,
                operation: operation,
                target: target,
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: -1,
                errorMessage: error.localizedDescription
            )
            await trackTaskCompleted(failedTask)

            return TaskResult(
                taskId: taskId,
                toolchainName: target,
                operation: operation,
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: -1,
                errorMessage: error.localizedDescription
            )
        }

        // 3b. Work completed successfully - create completed task record
        let completedTask = TaskRecord(
            id: taskId,
            operation: operation,
            target: target,
            status: result.status,
            startTime: startTime,
            endTime: result.endTime ?? Date(),
            exitCode: result.exitCode,
            stdoutSnippet: result.stdoutSnippet,
            stderrSnippet: result.stderrSnippet,
            errorMessage: result.errorMessage,
            suggestedFix: TaskResult.suggestFix(for: result.stderrSnippet ?? "")
        )
        await trackTaskCompleted(completedTask)

        return result
    }

    // MARK: - Private Helpers

    private func trackTaskStarted(_ task: TaskRecord) async {
        taskManager.addTask(task)
        await notificationManager.notifyTaskStarted(task)
    }

    private func trackTaskCompleted(_ task: TaskRecord) async {
        taskManager.addTask(task)
        await notificationManager.notifyTaskCompleted(task)
    }
}
