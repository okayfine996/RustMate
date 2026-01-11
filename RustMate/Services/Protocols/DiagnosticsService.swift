//
//  DiagnosticsService.swift
//  RustMate
//
//  Protocol for project diagnostics service
//

import Foundation

/// Service protocol for computing diagnostic information about a project's toolchain configuration
protocol DiagnosticsService {
    /// Compute diagnostics for a project
    func computeDiagnostics(projectPath: String) async throws -> ProjectDiagnostics
    
    /// Clear rustup override for a project
    func clearOverride(projectPath: String) async throws
    
    /// Get actual Rust version that would be used in shell
    func getActualToolchainVersion(projectPath: String) async throws -> String?
}
