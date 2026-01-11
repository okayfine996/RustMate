//
//  ProjectDiagnosticsService.swift
//  RustMate
//
//  Service for computing project toolchain configuration diagnostics
//

import Foundation

/// Service for computing diagnostic information about a project's toolchain configuration
class ProjectDiagnosticsService: DiagnosticsService {
    private let processRunner = ProcessRunner()
    private let authService: AuthorizationService
    private let toolchainConfigService: ToolchainConfigService
    private var settings: AppSettings
    
    init(
        settings: AppSettings = .default,
        authService: AuthorizationService = AuthorizationService(),
        toolchainConfigService: ToolchainConfigService = LocalToolchainConfigService()
    ) {
        self.settings = settings
        self.authService = authService
        self.toolchainConfigService = toolchainConfigService
    }
    
    // MARK: - DiagnosticsService Implementation
    
    func computeDiagnostics(projectPath: String) async throws -> ProjectDiagnostics {
        // Validate Security-Scoped Bookmark access for rustup operations
        let resources = try authService.validateAndResolve(
            scope: .projectContext,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }
        
        // Project path should be validated via ProjectBookmark in the ViewModel
        // For service layer, we assume the path is already authorized
        let projectURL = URL(fileURLWithPath: projectPath)
        
        // Verify path is accessible (basic check)
        guard FileManager.default.fileExists(atPath: projectPath) else {
            throw DiagnosticsError.permissionDenied
        }
        
        // Read configured version from rust-toolchain.toml
        let configuredVersion: String?
        do {
            let config = try await toolchainConfigService.readToolchainConfig(projectPath: projectPath)
            configuredVersion = config.version
        } catch {
            configuredVersion = nil
        }
        
        // Get override version from rustup show
        let overrideVersion = try await getOverrideVersion(projectPath: projectPath)
        
        // Get actual version that would be used
        let actualVersion = try await getActualToolchainVersion(projectPath: projectPath)
        
        // Detect mismatches
        let hasMismatch = detectMismatch(
            configured: configuredVersion,
            override: overrideVersion,
            actual: actualVersion
        )
        
        // Check MSRV
        let msrvViolation = try await checkMSRV(projectPath: projectPath, toolchainVersion: actualVersion)
        
        // Determine toolchain source priority
        let toolchainSource = determineToolchainSource(
            hasOverride: overrideVersion != nil,
            hasConfigFile: configuredVersion != nil
        )
        
        // Build conflict details
        var conflictDetails: [ProjectDiagnostics.ConflictDetail] = []
        if hasMismatch {
            conflictDetails.append(ProjectDiagnostics.ConflictDetail(
                type: .versionMismatch,
                message: "Version mismatch: configured=\(configuredVersion ?? "none"), override=\(overrideVersion ?? "none"), actual=\(actualVersion ?? "none")",
                suggestedFix: "Clear override or update configuration to match"
            ))
        }
        
        return ProjectDiagnostics(
            actualToolchainVersion: actualVersion,
            configuredVersion: configuredVersion,
            overrideVersion: overrideVersion,
            hasMismatch: hasMismatch,
            msrvViolation: msrvViolation,
            conflictDetails: conflictDetails,
            toolchainSource: toolchainSource
        )
    }
    
    func clearOverride(projectPath: String) async throws {
        // Validate Security-Scoped Bookmark access for rustup operations
        let resources = try authService.validateAndResolve(
            scope: .projectContext,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }
        
        // Project path should be validated via ProjectBookmark in the ViewModel
        // For service layer, we assume the path is already authorized
        let projectURL = URL(fileURLWithPath: projectPath)
        
        // Verify path is accessible (basic check)
        guard FileManager.default.fileExists(atPath: projectPath) else {
            throw DiagnosticsError.permissionDenied
        }
        
        // Run rustup override unset
        let rustupPath = try RustupCommandResolver.resolveRustupPath(
            settings: settings,
            authService: authService
        )
        
        let env = try RustupCommandResolver.buildEnvironment(
            settings: settings,
            authService: authService
        )
        
        // Use Process directly to set working directory
        let process = Process()
        process.executableURL = URL(fileURLWithPath: rustupPath)
        process.arguments = ["override", "unset"]
        process.currentDirectoryURL = projectURL
        
        if !env.isEmpty {
            var processEnv = ProcessInfo.processInfo.environment
            for (key, value) in env {
                processEnv[key] = value
            }
            process.environment = processEnv
        }
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        try process.run()
        process.waitUntilExit()
        
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        
        if process.terminationStatus != 0 {
            throw DiagnosticsError.commandError(stderr)
        }
    }
    
    func getActualToolchainVersion(projectPath: String) async throws -> String? {
        // Validate Security-Scoped Bookmark access for rustup operations
        let resources = try authService.validateAndResolve(
            scope: .projectContext,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }
        
        // Project path should be validated via ProjectBookmark in the ViewModel
        // For service layer, we assume the path is already authorized
        let projectURL = URL(fileURLWithPath: projectPath)
        
        // Verify path is accessible (basic check)
        guard FileManager.default.fileExists(atPath: projectPath) else {
            throw DiagnosticsError.permissionDenied
        }
        
        // Resolve rustc path (typically via rustup)
        let rustupPath = try RustupCommandResolver.resolveRustupPath(
            settings: settings,
            authService: authService
        )
        
        let env = try RustupCommandResolver.buildEnvironment(
            settings: settings,
            authService: authService
        )
        
        // Run rustup show to get active toolchain, then extract version
        // Use Process directly to set working directory
        let process = Process()
        process.executableURL = URL(fileURLWithPath: rustupPath)
        process.arguments = ["show"]
        process.currentDirectoryURL = projectURL
        
        if !env.isEmpty {
            var processEnv = ProcessInfo.processInfo.environment
            for (key, value) in env {
                processEnv[key] = value
            }
            process.environment = processEnv
        }
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            return nil
        }
        
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: stdoutData, encoding: .utf8) ?? ""
        
        // Parse version from rustup show output
        // Look for "rustc 1.75.0" pattern in the output
        if let versionRange = output.range(of: #"rustc\s+(\d+\.\d+\.\d+)"#, options: .regularExpression) {
            let match = String(output[versionRange])
            // Extract version number
            if let versionMatch = match.range(of: #"\d+\.\d+\.\d+"#, options: .regularExpression) {
                return String(match[versionMatch])
            }
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func getOverrideVersion(projectPath: String) async throws -> String? {
        // Run rustup show to get override information
        // This is a simplified implementation - full implementation would parse rustup show output
        // For now, return nil (no override detected)
        return nil
    }
    
    private func detectMismatch(configured: String?, override: String?, actual: String?) -> Bool {
        // Check if versions don't match
        if let configured = configured, let actual = actual, configured != actual {
            return true
        }
        if let override = override, let actual = actual, override != actual {
            return true
        }
        return false
    }
    
    private func checkMSRV(projectPath: String, toolchainVersion: String?) async throws -> ProjectDiagnostics.MSRVViolation? {
        // Read Cargo.toml and extract rust-version field
        let projectURL = URL(fileURLWithPath: projectPath)
        let cargoTomlURL = projectURL.appendingPathComponent("Cargo.toml")
        
        guard FileManager.default.fileExists(atPath: cargoTomlURL.path) else {
            // Cargo.toml not found - this is not an error, just means no MSRV check
            return nil
        }
        
        // Try to read rust-version from Cargo.toml
        // This is a simplified implementation - full TOML parsing would be better
        do {
            let cargoContent = try String(contentsOf: cargoTomlURL, encoding: .utf8)
            // Simple regex to find rust-version = "1.75.0"
            if let range = cargoContent.range(of: #"rust-version\s*=\s*"([^"]+)""#, options: .regularExpression) {
                let versionMatch = String(cargoContent[range])
                if let versionRange = versionMatch.range(of: #""([^"]+)""#, options: .regularExpression) {
                    let versionString = String(versionMatch[versionRange])
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    
                    // Compare with actual toolchain version
                    if let actual = toolchainVersion, let msrv = parseVersion(versionString) {
                        if compareVersions(actual, msrv) < 0 {
                            return ProjectDiagnostics.MSRVViolation(
                                requiredVersion: versionString,
                                configuredVersion: actual,
                                isViolation: true
                            )
                        }
                    }
                }
            }
        } catch {
            // If we can't read Cargo.toml, don't fail - just skip MSRV check
            return nil
        }
        
        return nil
    }
    
    private func determineToolchainSource(hasOverride: Bool, hasConfigFile: Bool) -> ProjectDiagnostics.ToolchainSource {
        // Priority: env → toolchainFile → override → default
        // For now, simplified logic
        if hasConfigFile {
            return .toolchainFile
        }
        if hasOverride {
            return .override
        }
        return .default
    }
    
    // MARK: - Helper Methods
    
    private func parseVersion(_ version: String) -> [Int]? {
        let components = version.split(separator: ".").compactMap { Int($0) }
        return components.count >= 2 ? components : nil
    }
    
    private func compareVersions(_ v1: String, _ v2: [Int]) -> Int {
        guard let v1Components = parseVersion(v1) else { return 0 }
        for (i, component) in v1Components.enumerated() {
            if i >= v2.count { return 1 }
            if component < v2[i] { return -1 }
            if component > v2[i] { return 1 }
        }
        return v1Components.count < v2.count ? -1 : 0
    }
}

// MARK: - Error Types

enum DiagnosticsError: Error, LocalizedError {
    case permissionDenied
    case commandError(String)
    case parseError(String)
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission denied: Please re-authorize project directory access"
        case .commandError(let msg):
            return "Command failed: \(msg)"
        case .parseError(let msg):
            return "Failed to parse output: \(msg)"
        case .fileNotFound:
            return "Cargo.toml not found"
        }
    }
}
