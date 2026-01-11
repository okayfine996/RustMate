//
//  ToolchainConfigParser.swift
//  RustMate
//
//  Parser for rust-toolchain.toml files
//

import Foundation
import TOMLDecoder

/// Parser for toolchain configuration TOML files
class ToolchainConfigParser {
    
    // MARK: - Errors
    
    enum ParseError: LocalizedError {
        case invalidTOML(String)
        case missingToolchainSection
        case invalidField(String)
        case decodingError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidTOML(let msg):
                return "Invalid TOML format: \(msg)"
            case .missingToolchainSection:
                return "Missing [toolchain] section in TOML"
            case .invalidField(let field):
                return "Invalid field in TOML: \(field)"
            case .decodingError(let msg):
                return "Failed to decode TOML: \(msg)"
            }
        }
    }
    
    // MARK: - TOML Structure
    
    /// Intermediate structure for TOML decoding
    private struct ToolchainTOML: Codable {
        let toolchain: ToolchainSection?
        
        struct ToolchainSection: Codable {
            let channel: String?
            let version: String?
            let components: [String]?
            let targets: [String]?
            let profile: String?
        }
    }
    
    // MARK: - Parse from TOML
    
    /// Parses TOML string to ProjectToolchainConfig
    /// - Parameter tomlContent: TOML content string
    /// - Returns: ProjectToolchainConfig
    /// - Throws: ParseError if TOML is invalid
    static func parse(_ tomlContent: String) throws -> ProjectToolchainConfig {
        guard !tomlContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ProjectToolchainConfig()
        }
        
        let decoder = TOMLDecoder()
        let tomlData: ToolchainTOML
        
        do {
            tomlData = try decoder.decode(ToolchainTOML.self, from: tomlContent)
        } catch {
            throw ParseError.decodingError(error.localizedDescription)
        }
        
        guard let toolchain = tomlData.toolchain else {
            return ProjectToolchainConfig()
        }
        
        // Convert TOML structure to ProjectToolchainConfig
        var config = ProjectToolchainConfig()
        
        if let channelStr = toolchain.channel {
            config.channel = ProjectToolchainConfig.ToolchainChannel(rawValue: channelStr)
        }
        
        config.version = toolchain.version
        
        config.components = toolchain.components ?? []
        config.targets = toolchain.targets ?? []
        
        if let profileStr = toolchain.profile {
            config.profile = ProjectToolchainConfig.ToolchainProfile(rawValue: profileStr)
        }
        
        return config
    }
    
    // MARK: - Serialize to TOML
    
    /// Serializes ProjectToolchainConfig to TOML string
    /// - Parameter config: ProjectToolchainConfig to serialize
    /// - Returns: TOML content string
    static func serialize(_ config: ProjectToolchainConfig) throws -> String {
        // TODO: Implement TOML serialization using TOMLDecoder
        // This requires TOMLDecoder dependency to be added first (T001)
        // For now, return basic TOML structure
        
        var toml = "[toolchain]\n"
        
        if let channel = config.channel {
            toml += "channel = \"\(channel.rawValue)\"\n"
        }
        
        if let version = config.version {
            toml += "version = \"\(version)\"\n"
        }
        
        if !config.components.isEmpty {
            let componentsStr = config.components.map { "\"\($0)\"" }.joined(separator: ", ")
            toml += "components = [\(componentsStr)]\n"
        }
        
        if !config.targets.isEmpty {
            let targetsStr = config.targets.map { "\"\($0)\"" }.joined(separator: ", ")
            toml += "targets = [\(targetsStr)]\n"
        }
        
        if let profile = config.profile {
            toml += "profile = \"\(profile.rawValue)\"\n"
        }
        
        return toml
    }
}
