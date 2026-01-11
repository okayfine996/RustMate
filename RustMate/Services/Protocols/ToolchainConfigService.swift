//
//  ToolchainConfigService.swift
//  RustMate
//
//  Protocol for toolchain configuration service
//

import Foundation

/// Service protocol for reading and writing project toolchain configuration (rust-toolchain.toml files)
protocol ToolchainConfigService {
    /// Read toolchain configuration from project directory
    func readToolchainConfig(projectPath: String) async throws -> ProjectToolchainConfig
    
    /// Write toolchain configuration to project directory
    func writeToolchainConfig(projectPath: String, config: ProjectToolchainConfig) async throws
    
    /// Validate toolchain version string
    func validateVersion(_ version: String) -> Bool
    
    /// Check if toolchain version is installed
    func isToolchainInstalled(_ version: String) async throws -> Bool
}
