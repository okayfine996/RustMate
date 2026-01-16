//
//  LocalToolchainConfigService.swift
//  RustMate
//
//  Local implementation of ToolchainConfigService
//  Handles reading and writing rust-toolchain.toml files
//

import Foundation

/// Local implementation of ToolchainConfigService
class LocalToolchainConfigService: ToolchainConfigService {
    private let authService: AuthorizationService
    private var settings: AppSettings
    
    init(settings: AppSettings = .default, authService: AuthorizationService = AuthorizationService()) {
        self.settings = settings
        self.authService = authService
    }
    
    // MARK: - ToolchainConfigService Implementation
    
    func readToolchainConfig(projectPath: String) async throws -> ProjectToolchainConfig {
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
            throw ConfigError.permissionDenied
        }
        
        // Try rust-toolchain.toml first (preferred)
        let tomlURL = projectURL.appendingPathComponent("rust-toolchain.toml")
        if TOMLFileManager.fileExists(at: tomlURL) {
            do {
                let content = try TOMLFileManager.read(from: tomlURL)
                return try ToolchainConfigParser.parse(content)
            } catch {
                // Handle malformed TOML files
                throw ConfigError.parseError("Failed to parse rust-toolchain.toml: \(error.localizedDescription). Please check the file format.")
            }
        }
        
        // Fallback to legacy rust-toolchain file
        let legacyURL = projectURL.appendingPathComponent("rust-toolchain")
        if TOMLFileManager.fileExists(at: legacyURL) {
            let content = try TOMLFileManager.read(from: legacyURL)
            // Legacy format is just a version string, parse accordingly
            let version = content.trimmingCharacters(in: .whitespacesAndNewlines)
            return ProjectToolchainConfig(version: version)
        }
        
        // Return default config if neither file exists
        return ProjectToolchainConfig()
    }
    
    func writeToolchainConfig(projectPath: String, config: ProjectToolchainConfig) async throws {
        // Validate configuration
        let validationErrors = config.validate()
        if !validationErrors.isEmpty {
            throw ConfigError.validationError(validationErrors.joined(separator: "; "))
        }
        
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
            throw ConfigError.permissionDenied
        }
        
        // Serialize to TOML
        let tomlContent = try ToolchainConfigParser.serialize(config)
        
        // Write atomically
        let tomlURL = projectURL.appendingPathComponent("rust-toolchain.toml")
        try TOMLFileManager.writeAtomically(content: tomlContent, to: tomlURL, validate: true)
    }
    
    func validateVersion(_ version: String) -> Bool {
        return ProjectToolchainConfig.validateVersion(version)
    }
    
    func isToolchainInstalled(_ version: String) async throws -> Bool {
        let toolchainService = LocalRustupToolchainService()
        let toolchains = try await toolchainService.listToolchains()
        return toolchains.contains(where: { $0.name == version })
    }
}

// MARK: - Error Types

enum ConfigError: Error, LocalizedError {
    case fileNotFound
    case parseError(String)
    case validationError(String)
    case writeError(String)
    case permissionDenied
    case commandError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Configuration file not found"
        case .parseError(let msg):
            return "Failed to parse TOML: \(msg)"
        case .validationError(let msg):
            return "Validation failed: \(msg)"
        case .writeError(let msg):
            return "Failed to write file: \(msg)"
        case .permissionDenied:
            return "Permission denied: Please re-authorize project directory access"
        case .commandError(let msg):
            return "Command failed: \(msg)"
        }
    }
}
