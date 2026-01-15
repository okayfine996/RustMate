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
    private let taskCoordinator = TaskCoordinator()
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
            // Try to find matching toolchain by ID first, then by name
            // If not found, keep the current selection to avoid clearing the UI
            if let selected = selectedToolchain {
                // First try to match by ID
                if let matched = updatedToolchains.first(where: { $0.id == selected.id }) {
                    selectedToolchain = matched
                } else if let matched = updatedToolchains.first(where: { $0.name == selected.name }) {
                    // Fallback to name matching
                    selectedToolchain = matched
                } else {
                    // Keep the existing selection if no match found
                    // This prevents UI content from disappearing during refresh
                    print("⚠️ ToolchainViewModel: Could not find matching toolchain in refresh, keeping current selection")
                }
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
                EventBus.shared.publishWithLegacy(.authorizationRequired(purposes: []), notification: Constants.Notifications.authorizationRequired)
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

        let result = await taskCoordinator.execute(
            operation: "install",
            target: name
        ) {
            try await service.installToolchain(name: name)
        }

        // Handle result
        if result.status != .success {
            error = NSError(domain: "ToolchainViewModel", code: 1, userInfo: [
                NSLocalizedDescriptionKey: result.errorMessage ?? "Installation failed"
            ])
        } else {
            await loadToolchains()
        }
    }

    func uninstallToolchain(_ toolchain: ToolchainInfo) async {
        let result = await taskCoordinator.execute(
            operation: "uninstall",
            target: toolchain.name
        ) {
            try await service.uninstallToolchain(name: toolchain.name)
        }

        // Handle result
        if result.status != .success {
            error = NSError(domain: "ToolchainViewModel", code: 1, userInfo: [
                NSLocalizedDescriptionKey: result.errorMessage ?? "Uninstallation failed"
            ])
        } else {
            await loadToolchains()
        }
    }

    func setDefaultToolchain(_ toolchain: ToolchainInfo) async {
        let result = await taskCoordinator.execute(
            operation: "setDefault",
            target: toolchain.name
        ) {
            try await service.setDefaultToolchain(name: toolchain.name)
        }

        // Handle result
        if result.status != .success {
            error = NSError(domain: "ToolchainViewModel", code: 1, userInfo: [
                NSLocalizedDescriptionKey: result.errorMessage ?? "Setting default failed"
            ])
        } else {
            await loadToolchains()
        }
    }

    func updateToolchain(_ toolchain: ToolchainInfo) async {
        let result = await taskCoordinator.execute(
            operation: "update",
            target: toolchain.name
        ) {
            try await service.updateToolchain(name: toolchain.name)
        }

        // Handle result
        if result.status != .success {
            error = NSError(domain: "ToolchainViewModel", code: 1, userInfo: [
                NSLocalizedDescriptionKey: result.errorMessage ?? "Update failed"
            ])
        } else {
            await loadToolchains()
        }
    }

    func updateAllToolchains() async {
        let result = await taskCoordinator.execute(
            operation: "updateAll",
            target: nil
        ) {
            try await service.updateAllToolchains()
        }

        // Handle result
        if result.status != .success {
            error = NSError(domain: "ToolchainViewModel", code: 1, userInfo: [
                NSLocalizedDescriptionKey: result.errorMessage ?? "Update all failed"
            ])
        } else {
            await loadToolchains()
        }
    }

    // MARK: - Task Management

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
