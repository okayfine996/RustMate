//
//  ToolchainViewModel.swift
//  RustMate
//
//  ViewModel for toolchain management
//

import Foundation
import Combine
import AppKit

@MainActor
class ToolchainViewModel: ObservableObject {
    @Published var toolchains: [ToolchainInfo] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedToolchain: ToolchainInfo?
    @Published var runningTasks: [UUID: TaskRecord] = [:]

    private let service: RustToolchainServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Structured Error Surface (T039)

    /// Error category for UI routing
    var errorCategory: ErrorPresentation.ErrorCategory? {
        guard let error = error else { return nil }
        return ErrorPresentation.category(for: error)
    }

    /// User-facing error presentation
    var errorPresentation: (title: String, message: String, suggestedFix: String?)? {
        guard let error = error else { return nil }
        return ErrorPresentation.present(error: error)
    }

    /// Whether the error requires authorization
    var requiresAuthorization: Bool {
        errorCategory == .requiresAuthorization
    }

    /// Whether the error is an authorization problem (stale/denied)
    var hasAuthorizationProblem: Bool {
        errorCategory == .authorizationProblem
    }

    init(service: RustToolchainServiceProtocol = LocalRustupToolchainService()) {
        self.service = service
        setupAppLifecycleObservers()
    }

    // MARK: - Lifecycle & Refresh Logic

    /// Set up observers for app lifecycle events (FR-208, FR-209)
    private func setupAppLifecycleObservers() {
        // Refresh on app becoming active (returning from background)
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.refreshToolchains()
                }
            }
            .store(in: &cancellables)

        // Refresh after system wakes from sleep
        NotificationCenter.default.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.refreshToolchains()
                }
            }
            .store(in: &cancellables)
    }

    /// Refresh toolchains list (lightweight, no loading indicator for background refresh)
    func refreshToolchains() async {
        do {
            let updatedToolchains = try await service.listToolchains()
            self.toolchains = updatedToolchains

            // Update selected toolchain if it changed
            if let selected = selectedToolchain {
                selectedToolchain = updatedToolchains.first { $0.id == selected.id }
            }
        } catch {
            // Silent failure for background refresh - don't disrupt user
            print("Background refresh failed: \(error)")
        }
    }

    // MARK: - Data Loading

    func loadToolchains() async {
        isLoading = true
        error = nil

        do {
            toolchains = try await service.listToolchains()

            // Auto-select default toolchain if none selected
            if selectedToolchain == nil {
                selectedToolchain = toolchains.first { $0.isDefault }
            }
        } catch {
            self.error = error
            print("Failed to load toolchains: \(error)")

            // If this is an authorization error, trigger setup flow
            let category = ErrorPresentation.category(for: error)
            if category == .requiresAuthorization || category == .authorizationProblem {
                print("🔐 ToolchainViewModel: Authorization error detected, triggering setup flow")
                NotificationCenter.default.post(name: NSNotification.Name("AuthorizationRequired"), object: nil)
            }
        }

        isLoading = false
    }

    // MARK: - Toolchain Operations

    func installToolchain(name: String) async {
        guard ToolchainInfo.validateName(name) else {
            error = NSError(domain: "ToolchainViewModel", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid toolchain name"
            ])
            return
        }

        // Create initial running task record
        let taskId = UUID()
        let runningTask = TaskRecord(
            id: taskId,
            operation: "install",
            target: name,
            status: .running,
            startTime: Date()
        )

        // Track and notify task started
        await trackTaskStarted(runningTask)

        do {
            let result = try await service.installToolchain(name: name)

            // Create updated task with the same taskId
            let completedTask = TaskRecord(
                id: taskId, // Use the same taskId we created earlier
                operation: "install",
                target: name,
                status: result.status,
                startTime: runningTask.startTime,
                endTime: result.endTime ?? Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdoutSnippet,
                stderrSnippet: result.stderrSnippet,
                errorMessage: result.errorMessage,
                suggestedFix: TaskResult.suggestFix(for: result.stderrSnippet ?? "")
            )

            await trackTaskCompleted(completedTask)

            // Refresh list after completion
            if result.status == .success {
                await loadToolchains()
            }
        } catch {
            self.error = error
            print("Failed to install toolchain: \(error)")

            // Track failure with the same taskId
            let failedTask = TaskRecord(
                id: taskId,
                operation: "install",
                target: name,
                status: .failed,
                startTime: runningTask.startTime,
                endTime: Date(),
                exitCode: -1,
                errorMessage: error.localizedDescription
            )
            await trackTaskCompleted(failedTask)
        }
    }

    func uninstallToolchain(_ toolchain: ToolchainInfo) async {
        // Create initial running task record
        let taskId = UUID()
        let runningTask = TaskRecord(
            id: taskId,
            operation: "uninstall",
            target: toolchain.name,
            status: .running,
            startTime: Date()
        )

        // Track and notify task started
        await trackTaskStarted(runningTask)

        do {
            let result = try await service.uninstallToolchain(name: toolchain.name)

            // Create updated task with the same taskId
            let completedTask = TaskRecord(
                id: taskId,
                operation: "uninstall",
                target: toolchain.name,
                status: result.status,
                startTime: runningTask.startTime,
                endTime: result.endTime ?? Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdoutSnippet,
                stderrSnippet: result.stderrSnippet,
                errorMessage: result.errorMessage,
                suggestedFix: TaskResult.suggestFix(for: result.stderrSnippet ?? "")
            )

            await trackTaskCompleted(completedTask)

            // Refresh list after completion
            if result.status == .success {
                await loadToolchains()
            }
        } catch {
            self.error = error
            print("Failed to uninstall toolchain: \(error)")

            // Track failure with the same taskId
            let failedTask = TaskRecord(
                id: taskId,
                operation: "uninstall",
                target: toolchain.name,
                status: .failed,
                startTime: runningTask.startTime,
                endTime: Date(),
                exitCode: -1,
                errorMessage: error.localizedDescription
            )
            await trackTaskCompleted(failedTask)
        }
    }

    func setDefaultToolchain(_ toolchain: ToolchainInfo) async {
        // Create initial running task record
        let taskId = UUID()
        let runningTask = TaskRecord(
            id: taskId,
            operation: "setDefault",
            target: toolchain.name,
            status: .running,
            startTime: Date()
        )

        // Track and notify task started
        await trackTaskStarted(runningTask)

        do {
            let result = try await service.setDefaultToolchain(name: toolchain.name)

            // Create updated task with the same taskId
            let completedTask = TaskRecord(
                id: taskId,
                operation: "setDefault",
                target: toolchain.name,
                status: result.status,
                startTime: runningTask.startTime,
                endTime: result.endTime ?? Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdoutSnippet,
                stderrSnippet: result.stderrSnippet,
                errorMessage: result.errorMessage,
                suggestedFix: TaskResult.suggestFix(for: result.stderrSnippet ?? "")
            )

            await trackTaskCompleted(completedTask)

            // Refresh list after completion
            if result.status == .success {
                await loadToolchains()
            }
        } catch {
            self.error = error
            print("Failed to set default toolchain: \(error)")

            // Track failure with the same taskId
            let failedTask = TaskRecord(
                id: taskId,
                operation: "setDefault",
                target: toolchain.name,
                status: .failed,
                startTime: runningTask.startTime,
                endTime: Date(),
                exitCode: -1,
                errorMessage: error.localizedDescription
            )
            await trackTaskCompleted(failedTask)
        }
    }

    func updateToolchain(_ toolchain: ToolchainInfo) async {
        // Create initial running task record
        let taskId = UUID()
        let runningTask = TaskRecord(
            id: taskId,
            operation: "update",
            target: toolchain.name,
            status: .running,
            startTime: Date()
        )

        // Track and notify task started
        await trackTaskStarted(runningTask)

        do {
            let result = try await service.updateToolchain(name: toolchain.name)

            // Create updated task with the same taskId
            let completedTask = TaskRecord(
                id: taskId,
                operation: "update",
                target: toolchain.name,
                status: result.status,
                startTime: runningTask.startTime,
                endTime: result.endTime ?? Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdoutSnippet,
                stderrSnippet: result.stderrSnippet,
                errorMessage: result.errorMessage,
                suggestedFix: TaskResult.suggestFix(for: result.stderrSnippet ?? "")
            )

            await trackTaskCompleted(completedTask)

            // Refresh list after completion
            if result.status == .success {
                await loadToolchains()
            }
        } catch {
            self.error = error
            print("Failed to update toolchain: \(error)")

            // Track failure with the same taskId
            let failedTask = TaskRecord(
                id: taskId,
                operation: "update",
                target: toolchain.name,
                status: .failed,
                startTime: runningTask.startTime,
                endTime: Date(),
                exitCode: -1,
                errorMessage: error.localizedDescription
            )
            await trackTaskCompleted(failedTask)
        }
    }

    func updateAllToolchains() async {
        // Create initial running task record
        let taskId = UUID()
        let runningTask = TaskRecord(
            id: taskId,
            operation: "updateAll",
            target: nil,
            status: .running,
            startTime: Date()
        )

        // Track and notify task started
        await trackTaskStarted(runningTask)

        do {
            let result = try await service.updateAllToolchains()

            // Create updated task with the same taskId
            let completedTask = TaskRecord(
                id: taskId,
                operation: "updateAll",
                target: nil,
                status: result.status,
                startTime: runningTask.startTime,
                endTime: result.endTime ?? Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdoutSnippet,
                stderrSnippet: result.stderrSnippet,
                errorMessage: result.errorMessage,
                suggestedFix: TaskResult.suggestFix(for: result.stderrSnippet ?? "")
            )

            await trackTaskCompleted(completedTask)

            // Refresh list after completion
            if result.status == .success {
                await loadToolchains()
            }
        } catch {
            self.error = error
            print("Failed to update all toolchains: \(error)")

            // Track failure with the same taskId
            let failedTask = TaskRecord(
                id: taskId,
                operation: "updateAll",
                target: nil,
                status: .failed,
                startTime: runningTask.startTime,
                endTime: Date(),
                exitCode: -1,
                errorMessage: error.localizedDescription
            )
            await trackTaskCompleted(failedTask)
        }
    }

    // MARK: - Task Management

    private func trackTaskStarted(_ task: TaskRecord) async {
        // Track locally for UI badges
        runningTasks[task.id] = task

        // Broadcast to TaskManager for global task list
        TaskManager.shared.addTask(task)

        // Send notification
        await TaskNotificationManager.shared.notifyTaskStarted(task)
    }

    private func trackTaskCompleted(_ record: TaskRecord) async {
        // Update local tracking
        runningTasks[record.id] = record

        // Broadcast to TaskManager
        TaskManager.shared.addTask(record)

        // Send completion notification
        await TaskNotificationManager.shared.notifyTaskCompleted(record)

        // Remove completed tasks after a delay
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            runningTasks.removeValue(forKey: record.id)
        }
    }

    private func trackTask(_ result: TaskResult) {
        if let record = result.taskRecord {
            // Track locally for UI badges
            runningTasks[record.id] = record

            // Broadcast to TaskManager for global task list
            TaskManager.shared.addTask(record)

            // Remove completed tasks after a delay
            if record.status != .running {
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                    runningTasks.removeValue(forKey: record.id)
                }
            }
        }
    }

    func clearTask(_ taskId: UUID) {
        runningTasks.removeValue(forKey: taskId)
    }

    // MARK: - Common Toolchain Suggestions

    var suggestedToolchains: [String] {
        let installed = Set(toolchains.map { $0.name })
        let suggestions = [
            "stable",
            "beta",
            "nightly",
            "stable-aarch64-apple-darwin",
            "stable-x86_64-apple-darwin"
        ]
        return suggestions.filter { !installed.contains($0) }
    }
}
