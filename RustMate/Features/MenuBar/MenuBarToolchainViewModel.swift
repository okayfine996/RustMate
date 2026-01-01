//
//  MenuBarToolchainViewModel.swift
//  RustMate
//
//  ViewModel for menu bar toolchain management
//

import Foundation
import Combine
import AppKit

@MainActor
class MenuBarToolchainViewModel: ObservableObject {
    @Published var toolchains: [ToolchainInfo] = []
    @Published var currentDefaultToolchainId: String?
    @Published var status: MenuBarState = .idle
    @Published var lastUpdatedAt: Date?
    @Published var lastError: Error?

    private let service: RustToolchainServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // Concurrency control for switching operations
    private var isSwitching = false

    init(service: RustToolchainServiceProtocol) {
        self.service = service
    }

    convenience init() {
        self.init(service: LocalRustupToolchainService())
    }

    // MARK: - State Aggregation (T003)

    /// Load menu bar state from service
    /// - Parameter force: Force refresh even if currently loading or switching
    func loadState(force: Bool = false) async {
        guard force || (status != .loading && status != .switching) else {
            print("⏭️ MenuBarViewModel: Skip load, already loading or switching")
            return
        }

        status = .loading
        lastError = nil

        do {
            let updatedToolchains = try await service.listToolchains()
            self.toolchains = updatedToolchains

            // Find current default toolchain
            if let defaultToolchain = updatedToolchains.first(where: { $0.isDefault }) {
                self.currentDefaultToolchainId = defaultToolchain.name
            } else {
                self.currentDefaultToolchainId = nil
            }

            self.lastUpdatedAt = Date()
            self.status = .idle

            print("✅ MenuBarViewModel: Loaded \(updatedToolchains.count) toolchains, default: \(currentDefaultToolchainId ?? "none")")
        } catch {
            self.lastError = error
            self.status = .error
            print("❌ MenuBarViewModel: Failed to load state: \(error)")
        }
    }

    // MARK: - Toolchain Switching (T005, T013, T015, T016, T017)

    /// Switch global default toolchain
    /// - Parameter toolchainId: Target toolchain identifier (must be from trusted list)
    func switchDefaultToolchain(to toolchainId: String) async {
        // Concurrency control: reject if already switching
        guard !isSwitching else {
            print("⚠️ MenuBarViewModel: Switch already in progress, ignoring new request")
            return
        }

        // Validate that toolchainId is in the current list
        guard toolchains.contains(where: { $0.name == toolchainId }) else {
            print("⚠️ MenuBarViewModel: Invalid toolchain ID: \(toolchainId)")
            return
        }

        print("🔄 MenuBarViewModel: Starting switch to \(toolchainId)")
        isSwitching = true
        status = .switching
        lastError = nil

        // Ensure isSwitching is always reset
        defer {
            isSwitching = false
            print("🏁 MenuBarViewModel: Switch operation completed, isSwitching reset")
        }

        let previousDefaultId = currentDefaultToolchainId

        do {
            print("📞 MenuBarViewModel: Calling service.setDefaultToolchain(\(toolchainId))")
            let result = try await service.setDefaultToolchain(name: toolchainId)
            print("📥 MenuBarViewModel: Received result, status: \(result.status)")

            if result.status == .success {
                // Success: force refresh to update display
                print("🔄 MenuBarViewModel: Success, refreshing state...")
                await loadState(force: true)
                print("✅ MenuBarViewModel: Switched default toolchain to \(toolchainId)")
            } else {
                // Task completed but not successful
                print("⚠️ MenuBarViewModel: Task completed but not successful: \(result.errorMessage ?? "unknown")")
                throw NSError(
                    domain: "MenuBarToolchainViewModel",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: result.errorMessage ?? "Failed to switch toolchain",
                        "stderrSnippet": result.stderrSnippet ?? ""
                    ]
                )
            }
        } catch {
            // Failure: keep previous default display and show error
            self.lastError = error
            self.status = .error
            self.currentDefaultToolchainId = previousDefaultId
            print("❌ MenuBarViewModel: Failed to switch toolchain: \(error)")
        }
    }

    // MARK: - Error Presentation (T004)

    /// Error category for UI routing
    var errorCategory: ErrorPresentation.ErrorCategory? {
        guard let error = lastError else { return nil }
        return ErrorPresentation.category(for: error)
    }

    /// User-facing error presentation
    var errorPresentation: (title: String, message: String, suggestedFix: String?)? {
        guard let error = lastError else { return nil }
        return ErrorPresentation.present(error: error)
    }

    /// Whether the error requires authorization
    var requiresAuthorization: Bool {
        errorCategory == .requiresAuthorization
    }

    // MARK: - Toolchain Options for Menu

    /// Get toolchain options suitable for menu display
    func toolchainOptions() -> [ToolchainOption] {
        // Remove duplicates by using a Set on toolchain names
        var seen = Set<String>()
        let uniqueToolchains = toolchains.filter { toolchain in
            if seen.contains(toolchain.name) {
                return false
            }
            seen.insert(toolchain.name)
            return true
        }

        print("🔍 MenuBarViewModel: toolchainOptions() - total: \(toolchains.count), unique: \(uniqueToolchains.count)")

        return uniqueToolchains.map { toolchain in
            ToolchainOption(
                id: toolchain.name,
                displayName: toolchain.name,
                isDefault: toolchain.isDefault,
                isSelectable: status != .switching
            )
        }
    }
}

// MARK: - Menu Bar State

enum MenuBarState {
    case idle
    case loading
    case switching
    case error

    var isWorking: Bool {
        self == .loading || self == .switching
    }
}
