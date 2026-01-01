//
//  TargetsViewModel.swift
//  RustMate
//
//  ViewModel for target platform management
//

import Foundation
import Combine

@MainActor
class TargetsViewModel: ObservableObject {
    @Published var targets: [TargetInfo] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedTarget: TargetInfo?
    @Published var selectedToolchain: ToolchainInfo?
    @Published var runningTasks: [UUID: TaskRecord] = [:]

    private let service: RustToolchainServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(service: RustToolchainServiceProtocol = XPCToolchainService()) {
        self.service = service
    }

    // MARK: - Data Loading

    /// Load targets for the selected toolchain
    func loadTargets() async {
        guard let toolchain = selectedToolchain else {
            targets = []
            return
        }

        isLoading = true
        error = nil

        do {
            let loadedTargets = try await service.listTargets(toolchainName: toolchain.name)

            // Update with toolchain name
            targets = loadedTargets.map { target in
                TargetInfo(
                    id: target.id,
                    triple: target.triple,
                    arch: target.arch,
                    vendor: target.vendor,
                    os: target.os,
                    env: target.env,
                    toolchainName: toolchain.name,
                    isInstalled: target.isInstalled,
                    description: target.description
                )
            }
        } catch {
            self.error = error
            print("Failed to load targets: \(error)")
        }

        isLoading = false
    }

    /// Refresh targets list for current toolchain
    func refreshTargets() async {
        await loadTargets()
    }

    // MARK: - Target Operations

    func installTarget(_ target: TargetInfo) async {
        guard let toolchain = selectedToolchain else { return }

        do {
            let result = try await service.addTarget(
                targetTriple: target.triple,
                toolchainName: toolchain.name
            )
            trackTask(result)

            // Refresh list after completion
            if result.status == .success {
                await loadTargets()
            }
        } catch {
            self.error = error
            print("Failed to install target: \(error)")
        }
    }

    func uninstallTarget(_ target: TargetInfo) async {
        guard let toolchain = selectedToolchain else { return }

        do {
            let result = try await service.removeTarget(
                targetTriple: target.triple,
                toolchainName: toolchain.name
            )
            trackTask(result)

            // Refresh list after completion
            if result.status == .success {
                await loadTargets()
            }
        } catch {
            self.error = error
            print("Failed to uninstall target: \(error)")
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

    // MARK: - Suggestions

    /// Get suggested targets that are not yet installed
    var suggestedTargets: [TargetInfo] {
        let installedTriples = Set(targets.filter { $0.isInstalled }.map { $0.triple })
        let allSuggestions = TargetInfo.commonTargets

        return targets.filter { target in
            allSuggestions.contains(target.triple) && !installedTriples.contains(target.triple)
        }
    }

    /// Check if there are any common targets not installed
    var hasSuggestions: Bool {
        !suggestedTargets.isEmpty
    }

    // MARK: - Computed Properties

    var installedCount: Int {
        targets.filter { $0.isInstalled }.count
    }

    var availableCount: Int {
        targets.filter { !$0.isInstalled }.count
    }

    // MARK: - Filtering

    /// Group targets by architecture for better organization
    var targetsByArchitecture: [(arch: String, targets: [TargetInfo])] {
        let grouped = Dictionary(grouping: targets) { target in
            target.arch ?? "other"
        }

        return grouped.sorted { $0.key < $1.key }.map { (arch: $0.key, targets: $0.value) }
    }
}
