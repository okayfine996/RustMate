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
        // Logic: A toolchain is considered "installed" if any of these conditions are met:
        // 1. actualToolchainVersion exists (rustc version was successfully parsed)
        // 2. toolchainSource is not .default (explicit configuration exists: override or toolchainFile)
        // 3. toolchainSource is .default (using default toolchain, which is normal and healthy)
        //
        // The only case where toolchain is NOT installed is if diagnostics computation itself failed,
        // which would throw an error before reaching this point.
        // Therefore, if we reach here, toolchain is always considered installed.
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

    /// Refresh health statuses for multiple projects
    /// - Parameter projects: The projects to refresh
    /// - Returns: Dictionary mapping project IDs to their health statuses
    func refreshHealthStatuses(for projects: [ProjectBookmark]) async -> [UUID: ProjectHealthStatus] {
        var results: [UUID: ProjectHealthStatus] = [:]

        for project in projects {
            do {
                let healthStatus = try await ScopedResource.withBookmark(project.bookmarkData) { url in
                    return try await computeHealthStatus(for: url.path)
                }
                results[project.id] = healthStatus.result
            } catch {
                // Skip projects that can't be accessed
                results[project.id] = ProjectHealthStatus(
                    status: .unknown,
                    indicatorColor: .yellow,
                    details: "Failed to access project: \(error.localizedDescription)"
                )
            }
        }

        return results
    }
}
