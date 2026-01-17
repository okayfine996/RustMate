//
//  ProjectHealthService.swift
//  RustMate
//
//  Service for computing and managing project health status
//  Extracted from ProjectsViewModel for single responsibility
//

import Foundation

/// Service for managing project health status computation
/// Handles diagnostics and health status calculation for projects
@MainActor
class ProjectHealthService {

    private let diagnosticsService: ProjectDiagnosticsService

    init(diagnosticsService: ProjectDiagnosticsService = ProjectDiagnosticsService()) {
        self.diagnosticsService = diagnosticsService
    }

    // MARK: - Health Status Computation

    /// Compute the health status for a project
    /// - Parameter projectPath: The path to the project directory
    /// - Returns: The computed health status
    /// - Throws: If unable to compute diagnostics
    func computeHealthStatus(for projectPath: String) async throws -> ProjectHealthStatus {
        // Compute diagnostics
        let diagnostics = try await diagnosticsService.computeDiagnostics(projectPath: projectPath)

        // Check if toolchain is installed
        // Logic: A toolchain is considered "installed" if diagnostics computation succeeded.
        // The only case where toolchain is NOT installed is if diagnostics computation itself failed,
        // which would throw an error before reaching this point.
        //
        // Note: actualToolchainVersion being nil does NOT mean toolchain is not installed.
        // It may be nil for valid reasons (e.g., using default toolchain, version parsing failed).
        // The ProjectHealthStatus.calculate method has detailed logic to handle this correctly.
        let toolchainInstalled = true

        // Check if components are available
        // Note: Simplified implementation - assumes components are available if toolchain is installed
        // Future enhancement could query actual component availability via rustup component list
        let componentsAvailable = toolchainInstalled

        // Calculate health status
        return ProjectHealthStatus.calculate(
            from: diagnostics,
            toolchainInstalled: toolchainInstalled,
            componentsAvailable: componentsAvailable
        )
    }

    /// Compute health status with error fallback
    /// - Parameter projectPath: The path to the project directory
    /// - Returns: The computed health status, or an unknown status on error
    func computeHealthStatusSafely(for projectPath: String) async -> ProjectHealthStatus {
        do {
            return try await computeHealthStatus(for: projectPath)
        } catch {
            return ProjectHealthStatus(
                status: .unknown,
                indicatorColor: .yellow,
                details: "Failed to compute health status: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Batch Operations

    /// Refresh health statuses for multiple projects in parallel
    /// - Parameter projects: The projects to refresh
    /// - Returns: Dictionary mapping project IDs to their health statuses
    nonisolated func refreshHealthStatuses(for projects: [ProjectBookmark]) async -> [UUID: ProjectHealthStatus] {
        // Use TaskGroup for concurrent processing with controlled concurrency
        // Limit concurrent tasks to avoid overloading the system
        let maxConcurrentTasks = min(projects.count, 4)

        return await withTaskGroup(of: (UUID, ProjectHealthStatus).self) { group in
            var results: [UUID: ProjectHealthStatus] = [:]
            var pendingProjects = projects
            var activeTasks = 0

            // Process projects with controlled concurrency
            while !pendingProjects.isEmpty || activeTasks > 0 {
                // Add tasks up to the concurrency limit
                while activeTasks < maxConcurrentTasks && !pendingProjects.isEmpty {
                    let project = pendingProjects.removeFirst()
                    activeTasks += 1

                    // Capture diagnosticsService for use in detached task
                    let diagnosticsService = self.diagnosticsService

                    group.addTask {
                        let status: ProjectHealthStatus
                        do {
                            let healthStatus = try await ScopedResource.withBookmark(project.bookmarkData) { url in
                                // Run diagnostics (not on main actor)
                                let diagnostics = try await diagnosticsService.computeDiagnostics(projectPath: url.path)
                                let toolchainInstalled = diagnostics.actualToolchainVersion != nil
                                let componentsAvailable = toolchainInstalled
                                return ProjectHealthStatus.calculate(
                                    from: diagnostics,
                                    toolchainInstalled: toolchainInstalled,
                                    componentsAvailable: componentsAvailable
                                )
                            }
                            status = healthStatus.result
                        } catch {
                            // Skip projects that can't be accessed
                            status = ProjectHealthStatus(
                                status: .unknown,
                                indicatorColor: .yellow,
                                details: "Failed to access project: \(error.localizedDescription)"
                            )
                        }
                        return (project.id, status)
                    }
                }

                // Wait for one task to complete
                if let (projectId, status) = await group.next() {
                    results[projectId] = status
                    activeTasks -= 1
                }
            }

            return results
        }
    }
}
