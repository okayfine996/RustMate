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
    private let taskCoordinator = TaskCoordinator()
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

        let result = await taskCoordinator.execute(
            operation: "addComponent",
            target: "\(component.name) (\(toolchain.name))"
        ) {
            try await service.addComponent(
                componentName: component.name,
                toolchainName: toolchain.name
            )
        }

        // Handle result
        if result.status != .success {
            error = AppError.operationFailed(
                operation: "install component",
                message: result.errorMessage ?? "Installation failed"
            )
        } else {
            await loadComponents()
        }
    }

    func uninstallComponent(_ component: ComponentInfo) async {
        guard let toolchain = selectedToolchain else { return }

        let result = await taskCoordinator.execute(
            operation: "removeComponent",
            target: "\(component.name) (\(toolchain.name))"
        ) {
            try await service.removeComponent(
                componentName: component.name,
                toolchainName: toolchain.name
            )
        }

        // Handle result
        if result.status != .success {
            error = AppError.operationFailed(
                operation: "uninstall component",
                message: result.errorMessage ?? "Uninstallation failed"
            )
        } else {
            await loadComponents()
        }
    }

    // MARK: - Task Management
    // (Task tracking now handled by TaskCoordinator)

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

// MARK: - ToolchainContextViewModel Conformance

extension ComponentsViewModel: ToolchainContextViewModel {
    typealias Item = ComponentInfo

    var items: [ComponentInfo] {
        components
    }

    func loadItems() async {
        await loadComponents()
    }
}
