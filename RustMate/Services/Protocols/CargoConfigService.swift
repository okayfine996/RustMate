//
//  CargoConfigService.swift
//  RustMate
//
//  Protocol for Cargo configuration service
//

import Foundation

/// Service protocol for reading and writing Cargo build configuration (.cargo/config.toml files)
protocol CargoConfigService {
    /// Read Cargo configuration from project directory
    func readCargoConfig(projectPath: String) async throws -> ProjectCargoConfig
    
    /// Write Cargo configuration to project directory
    func writeCargoConfig(projectPath: String, config: ProjectCargoConfig) async throws
    
    /// Validate registry mirror URL
    func validateMirrorURL(_ url: String) -> Bool
    
    /// Validate alias name
    func validateAlias(_ alias: String) -> Bool
}
