//
//  LocalCargoConfigService.swift
//  RustMate
//
//  Local implementation of CargoConfigService
//  Handles reading and writing .cargo/config.toml files
//

import Foundation

/// Local implementation of CargoConfigService
class LocalCargoConfigService: CargoConfigService {
    private let authService: AuthorizationService
    private var settings: AppSettings
    
    init(settings: AppSettings = .default, authService: AuthorizationService = AuthorizationService()) {
        self.settings = settings
        self.authService = authService
    }
    
    // MARK: - CargoConfigService Implementation
    
    func readCargoConfig(projectPath: String) async throws -> ProjectCargoConfig {
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
        
        let configURL = projectURL.appendingPathComponent(".cargo").appendingPathComponent("config.toml")
        
        if TOMLFileManager.fileExists(at: configURL) {
            do {
                let content = try TOMLFileManager.read(from: configURL)
                return try CargoConfigParser.parse(content)
            } catch {
                // Handle malformed TOML files
                throw ConfigError.parseError("Failed to parse .cargo/config.toml: \(error.localizedDescription). Please check the file format.")
            }
        }
        
        // Return default config if file doesn't exist
        return ProjectCargoConfig()
    }
    
    func writeCargoConfig(projectPath: String, config: ProjectCargoConfig) async throws {
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
        
        // Create .cargo directory if it doesn't exist
        let cargoDirURL = projectURL.appendingPathComponent(".cargo")
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: cargoDirURL.path) {
            try fileManager.createDirectory(
                at: cargoDirURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // Serialize to TOML
        let tomlContent = try CargoConfigParser.serialize(config)
        
        // Write atomically
        let configURL = cargoDirURL.appendingPathComponent("config.toml")
        try TOMLFileManager.writeAtomically(content: tomlContent, to: configURL, validate: true)
    }
    
    func validateMirrorURL(_ url: String) -> Bool {
        // Check if URL is in whitelist
        let whitelist = [
            "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git",
            "https://mirrors.ustc.edu.cn/crates.io-index.git",
            "https://rsproxy.cn/crates.io-index"
        ]
        return whitelist.contains(url)
    }
    
    func validateAlias(_ alias: String) -> Bool {
        return ProjectCargoConfig.validateAlias(alias)
    }
}
