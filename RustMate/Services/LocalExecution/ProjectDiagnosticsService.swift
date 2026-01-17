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

        // Run rustup show once and cache the output for reuse
        let rustupShowOutput = try await getRustupShowOutput(projectPath: projectPath)

        // Get override version from cached rustup show output
        // Also check if override exists even if it's being overridden by toolchainFile
        let overrideVersion = getOverrideVersion(from: rustupShowOutput, projectPath: projectPath)
        let hasOverride = try await checkOverrideExists(projectPath: projectPath)

        // Get actual version from cached rustup show output
        let actualVersion = extractActualToolchainVersion(from: rustupShowOutput)

        // Detect mismatches
        let hasMismatch = detectMismatch(
            configured: configuredVersion,
            override: overrideVersion,
            actual: actualVersion
        )

        // Check MSRV
        let msrvViolation = try await checkMSRV(projectPath: projectPath, toolchainVersion: actualVersion)

        // Determine toolchain source from cached rustup show output
        let toolchainSource = determineToolchainSource(
            from: rustupShowOutput,
            projectPath: projectPath,
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
        
        // Detect override conflict: both rust-toolchain.toml and rustup override exist
        // When both exist, one will be ignored based on priority (toolchainFile > override)
        // This is a conflict because having both is redundant and confusing
        // Use hasOverride instead of overrideVersion != nil, because overrideVersion might be nil
        // if the override is being overridden by toolchainFile
        if configuredVersion != nil && hasOverride {
            let message: String
            if toolchainSource == .toolchainFile {
                message = "Both rust-toolchain.toml and rustup override exist. The toolchain file takes priority, so the override is ignored."
            } else if toolchainSource == .override {
                message = "Both rust-toolchain.toml and rustup override exist. The override takes priority, so the toolchain file is ignored."
            } else {
                message = "Both rust-toolchain.toml and rustup override exist, but neither is active (unexpected state)."
            }
            
            conflictDetails.append(ProjectDiagnostics.ConflictDetail(
                type: .overrideConflict,
                message: message,
                suggestedFix: "Remove the rustup override with 'rustup override unset' or remove rust-toolchain.toml to use the override"
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
        
        // Use ProcessRunner to execute on background thread
        let result = try await processRunner.runRustup(
            at: rustupPath,
            arguments: ["override", "unset"],
            environment: env,
            currentDirectoryURL: projectURL
        )
        
        if !result.wasSuccessful {
            throw DiagnosticsError.commandError(result.stderr)
        }
    }
    
    func getActualToolchainVersion(projectPath: String) async throws -> String? {
        // Run rustup show to get the active toolchain version
        let output = try await getRustupShowOutput(projectPath: projectPath)
        return extractActualToolchainVersion(from: output)
    }

    private func extractActualToolchainVersion(from output: String) -> String? {
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

    /// Runs rustup show once and returns the output for caching and reuse
    private func getRustupShowOutput(projectPath: String) async throws -> String {
        let projectURL = URL(fileURLWithPath: projectPath)

        // Resolve rustup path
        let rustupPath = try RustupCommandResolver.resolveRustupPath(
            settings: settings,
            authService: authService
        )

        let env = try RustupCommandResolver.buildEnvironment(
            settings: settings,
            authService: authService
        )

        // Run rustup show once
        let result = try await processRunner.runRustup(
            at: rustupPath,
            arguments: ["show"],
            environment: env,
            currentDirectoryURL: projectURL
        )

        if !result.wasSuccessful {
            return ""
        }

        return result.stdout
    }

    private func getOverrideVersion(from output: String, projectPath: String) -> String? {
        // Parse output using ShowParser
        let contextInfo = ShowParser.parse(output, projectPath: projectPath)

        // Check if there's a directory override (not toolchain file override)
        // Override means rustup override set, not rust-toolchain.toml
        guard contextInfo.reason == .override else {
            return nil
        }

        let toolchainName = contextInfo.activeToolchain

        // Extract version from toolchain name or rustc output
        // Priority:
        // 1. Try to extract version number from toolchain name (e.g., "1.75.0-aarch64-apple-darwin")
        // 2. Extract rustc version from output (for channel-based toolchains like stable/beta/nightly)

        // Pattern 1: Toolchain name starts with version number
        // Example: "1.75.0-aarch64-apple-darwin" -> "1.75.0"
        if let versionRange = toolchainName.range(of: #"^\d+\.\d+\.\d+"#, options: .regularExpression) {
            return String(toolchainName[versionRange])
        }

        // Pattern 2: Extract rustc version from output
        // This works for channel-based toolchains (stable, beta, nightly)
        // Example output: "rustc 1.75.0 (82e1608df 2023-12-21)"
        if let rustcVersionRange = output.range(of: #"rustc\s+(\d+\.\d+\.\d+)"#, options: .regularExpression) {
            let match = String(output[rustcVersionRange])
            if let versionMatch = match.range(of: #"\d+\.\d+\.\d+"#, options: .regularExpression) {
                let version = String(match[versionMatch])
                return version
            }
        }

        // Pattern 3: For nightly with date, extract the date
        // Example: "nightly-2024-01-01-aarch64-apple-darwin" -> "nightly-2024-01-01"
        if toolchainName.contains("nightly-") {
            if let nightlyRange = toolchainName.range(of: #"nightly-\d{4}-\d{2}-\d{2}"#, options: .regularExpression) {
                return String(toolchainName[nightlyRange])
            }
        }

        // If we can't extract a specific version, return nil
        // This indicates override exists but version couldn't be determined
        return nil
    }
    
    /// Check if a rustup override exists for the project directory
    /// This checks the override database directly, even if the override is being overridden by toolchainFile
    private func checkOverrideExists(projectPath: String) async throws -> Bool {
        // Validate Security-Scoped Bookmark access for rustup operations
        let resources = try authService.validateAndResolve(
            scope: .projectContext,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }
        
        let projectURL = URL(fileURLWithPath: projectPath)
        
        // Verify path is accessible
        guard FileManager.default.fileExists(atPath: projectPath) else {
            return false
        }
        
        // Resolve rustup path
        let rustupPath = try RustupCommandResolver.resolveRustupPath(
            settings: settings,
            authService: authService
        )
        
        let env = try RustupCommandResolver.buildEnvironment(
            settings: settings,
            authService: authService
        )
        
        // Run rustup override list to check if override exists for this directory
        let result = try await processRunner.runRustup(
            at: rustupPath,
            arguments: ["override", "list"],
            environment: env,
            currentDirectoryURL: nil
        )
        
        guard result.wasSuccessful else {
            return false
        }
        
        // Check if the project path appears in the override list
        // rustup override list output format:
        // /path/to/project    toolchain-name
        // Note: paths may contain spaces, so we can't simply split by whitespace
        let output = result.stdout
        let normalizedProjectPath = (projectPath as NSString).standardizingPath

        // Check if the project path (or any parent) appears in the output
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // Use regex to parse: capture path (everything before 2+ spaces/tabs) and toolchain name
            // Pattern matches: path followed by 2+ whitespace chars, then toolchain name
            // This handles paths with single spaces but separates on multiple spaces/tabs
            let pattern = #"^(.+?)\s{2,}(\S+)$"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed)),
               match.numberOfRanges >= 2 {
                // Extract the path (first capture group)
                if let pathRange = Range(match.range(at: 1), in: trimmed) {
                    let overridePath = String(trimmed[pathRange]).trimmingCharacters(in: .whitespaces)
                    let normalizedOverridePath = (overridePath as NSString).standardizingPath

                    // Check if the project path matches or is a subdirectory of the override path
                    if normalizedProjectPath == normalizedOverridePath ||
                       normalizedProjectPath.hasPrefix(normalizedOverridePath + "/") {
                        return true
                    }
                }
            }
        }

        return false
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
                        // Attempt to compare versions
                        if let comparisonResult = compareVersions(actual, msrv) {
                            // Versions are comparable (both are semver)
                            if comparisonResult < 0 {
                                return ProjectDiagnostics.MSRVViolation(
                                    requiredVersion: versionString,
                                    configuredVersion: actual,
                                    isViolation: true
                                )
                            }
                            // No violation - toolchain meets or exceeds MSRV
                            // Return nil to indicate MSRV is satisfied
                        } else {
                            // Versions cannot be compared (e.g., nightly/beta/stable)
                            return ProjectDiagnostics.MSRVViolation(
                                requiredVersion: versionString,
                                configuredVersion: actual,
                                isViolation: false,
                                cannotDetermine: true
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
    
    private func determineToolchainSource(
        from output: String,
        projectPath: String,
        hasOverride: Bool,
        hasConfigFile: Bool
    ) -> ProjectDiagnostics.ToolchainSource {
        // Priority: env → toolchainFile → override → default
        // Parse output using ShowParser
        let contextInfo = ShowParser.parse(output, projectPath: projectPath)

        // Map ShowParser's ToolchainReason to ProjectDiagnostics.ToolchainSource
        switch contextInfo.reason {
        case .environment:
            return .environment
        case .toolchainFile:
            return .toolchainFile
        case .override:
            return .override
        case .default:
            return .default
        case .unknown:
            // Fallback logic based on what we know
            if hasConfigFile {
                return .toolchainFile
            }
            if hasOverride {
                return .override
            }
            return .default
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseVersion(_ version: String) -> [Int]? {
        let components = version.split(separator: ".").compactMap { Int($0) }
        return components.count >= 2 ? components : nil
    }
    
    private func compareVersions(_ v1: String, _ v2: [Int]) -> Int? {
        guard let v1Components = parseVersion(v1) else { return nil }
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
