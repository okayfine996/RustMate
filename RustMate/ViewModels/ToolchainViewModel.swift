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

        do {
            let result = try await service.installToolchain(name: name)
            trackTask(result)

            // Refresh list after completion
            if result.status == .success {
                await loadToolchains()
            }
        } catch {
            self.error = error
            print("Failed to install toolchain: \(error)")
        }
    }

    func uninstallToolchain(_ toolchain: ToolchainInfo) async {
        do {
            let result = try await service.uninstallToolchain(name: toolchain.name)
            trackTask(result)

            // Refresh list after completion
            if result.status == .success {
                await loadToolchains()
            }
        } catch {
            self.error = error
            print("Failed to uninstall toolchain: \(error)")
        }
    }

    func setDefaultToolchain(_ toolchain: ToolchainInfo) async {
        do {
            let result = try await service.setDefaultToolchain(name: toolchain.name)
            trackTask(result)

            // Refresh list after completion
            if result.status == .success {
                await loadToolchains()
            }
        } catch {
            self.error = error
            print("Failed to set default toolchain: \(error)")
        }
    }

    func updateToolchain(_ toolchain: ToolchainInfo) async {
        do {
            let result = try await service.updateToolchain(name: toolchain.name)
            trackTask(result)

            // Refresh list after completion
            if result.status == .success {
                await loadToolchains()
            }
        } catch {
            self.error = error
            print("Failed to update toolchain: \(error)")
        }
    }

    func updateAllToolchains() async {
        do {
            let result = try await service.updateAllToolchains()
            trackTask(result)

            // Refresh list after completion
            if result.status == .success {
                await loadToolchains()
            }
        } catch {
            self.error = error
            print("Failed to update all toolchains: \(error)")
        }
    }

    // MARK: - Task Management

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
