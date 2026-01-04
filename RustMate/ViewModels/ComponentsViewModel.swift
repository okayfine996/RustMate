//
//  ComponentsViewModel.swift
//  RustMate
//
//  ViewModel for component management
//

import Foundation
import Combine

@MainActor
class ComponentsViewModel: ObservableObject {
    @Published var components: [ComponentInfo] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedComponent: ComponentInfo?
    @Published var selectedToolchain: ToolchainInfo?
    @Published var runningTasks: [UUID: TaskRecord] = [:]

    private let service: RustToolchainServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Structured Error Surface (T041)

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
    }

    // MARK: - Data Loading

    /// Load components for the selected toolchain
    func loadComponents() async {
        guard let toolchain = selectedToolchain else {
            components = []
            return
        }

        isLoading = true
        error = nil

        do {
            let loadedComponents = try await service.listComponents(toolchainName: toolchain.name)

            // Update with toolchain name
            components = loadedComponents.map { component in
                ComponentInfo(
                    id: component.id,
                    name: component.name,
                    displayName: component.displayName,
                    toolchainName: toolchain.name,
                    isInstalled: component.isInstalled,
                    componentType: component.componentType,
                    description: component.description
                )
            }
        } catch {
            self.error = error
            print("Failed to load components: \(error)")
        }

        isLoading = false
    }

    /// Refresh components list for current toolchain
    func refreshComponents() async {
        await loadComponents()
    }

    // MARK: - Component Operations

    func installComponent(_ component: ComponentInfo) async {
        guard let toolchain = selectedToolchain else { return }

        // Create initial running task record
        let taskId = UUID()
        let runningTask = TaskRecord(
            id: taskId,
            operation: "addComponent",
            target: "\(component.name) (\(toolchain.name))",
            status: .running,
            startTime: Date()
        )

        // Track and notify task started
        await trackTaskStarted(runningTask)

        do {
            let result = try await service.addComponent(
                componentName: component.name,
                toolchainName: toolchain.name
            )

            // Create updated task with the same taskId
            let completedTask = TaskRecord(
                id: taskId,
                operation: "addComponent",
                target: "\(component.name) (\(toolchain.name))",
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
                await loadComponents()
            }
        } catch {
            self.error = error
            print("Failed to install component: \(error)")

            // Track failure with the same taskId
            let failedTask = TaskRecord(
                id: taskId,
                operation: "addComponent",
                target: "\(component.name) (\(toolchain.name))",
                status: .failed,
                startTime: runningTask.startTime,
                endTime: Date(),
                exitCode: -1,
                errorMessage: error.localizedDescription
            )
            await trackTaskCompleted(failedTask)
        }
    }

    func uninstallComponent(_ component: ComponentInfo) async {
        guard let toolchain = selectedToolchain else { return }

        // Create initial running task record
        let taskId = UUID()
        let runningTask = TaskRecord(
            id: taskId,
            operation: "removeComponent",
            target: "\(component.name) (\(toolchain.name))",
            status: .running,
            startTime: Date()
        )

        // Track and notify task started
        await trackTaskStarted(runningTask)

        do {
            let result = try await service.removeComponent(
                componentName: component.name,
                toolchainName: toolchain.name
            )

            // Create updated task with the same taskId
            let completedTask = TaskRecord(
                id: taskId,
                operation: "removeComponent",
                target: "\(component.name) (\(toolchain.name))",
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
                await loadComponents()
            }
        } catch {
            self.error = error
            print("Failed to uninstall component: \(error)")

            // Track failure with the same taskId
            let failedTask = TaskRecord(
                id: taskId,
                operation: "removeComponent",
                target: "\(component.name) (\(toolchain.name))",
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

    // MARK: - Suggestions

    /// Get suggested components that are not yet installed
    var suggestedComponents: [ComponentInfo] {
        let installedNames = Set(components.filter { $0.isInstalled }.map { $0.displayName })
        let allSuggestions = ComponentInfo.commonComponents

        return components.filter { component in
            allSuggestions.contains(component.displayName) && !installedNames.contains(component.displayName)
        }
    }

    /// Check if there are any common components not installed
    var hasSuggestions: Bool {
        !suggestedComponents.isEmpty
    }

    // MARK: - Computed Properties

    var installedCount: Int {
        components.filter { $0.isInstalled }.count
    }

    var availableCount: Int {
        components.filter { !$0.isInstalled }.count
    }
}
