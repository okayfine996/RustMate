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
        // According to spec: channel format is <channel>[-<date>][-<host>]
        // channel can be: stable|beta|nightly|<versioned> (e.g., 1.42, 1.42.0)
        var config = ProjectToolchainConfig()
        
        if let channelStr = toolchain.channel {
            // Parse channel string according to spec
            // Examples: "stable", "beta", "nightly", "1.75.0", "1.75", "nightly-2024-01-01"
            
            // Check if it's a named channel (stable, beta, nightly)
            if let channel = ProjectToolchainConfig.ToolchainChannel(rawValue: channelStr) {
                config.channel = channel
            } else if channelStr.range(of: "^nightly-\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) != nil {
                // Nightly with date: "nightly-2024-01-01"
                config.channel = .nightly
                // Extract date part (everything after "nightly-")
                if let dateRange = channelStr.range(of: "nightly-") {
                    let datePart = String(channelStr[dateRange.upperBound...])
                    config.version = "nightly-\(datePart)"
                }
            } else if channelStr.range(of: "^\\d+\\.\\d+(\\.\\d+)?(-beta(\\.\\d+)?)?$", options: .regularExpression) != nil {
                // Version format: "1.75.0", "1.75", "1.75.0-beta", "1.75.0-beta.1"
                // Store as version (not channel)
                config.version = channelStr
            } else {
                // Try to parse as channel with date/host suffix
                // Format: <channel>-<date> or <channel>-<host>
                let parts = channelStr.split(separator: "-", maxSplits: 1)
                if parts.count == 2 {
                    let baseChannel = String(parts[0])
                    let suffix = String(parts[1])
                    
                    if let channel = ProjectToolchainConfig.ToolchainChannel(rawValue: baseChannel) {
                        config.channel = channel
                        // Check if suffix is a date (YYYY-MM-DD) or host triple
                        if suffix.range(of: "^\\d{4}-\\d{2}-\\d{2}$", options: .regularExpression) != nil {
                            // It's a date
                            config.version = "\(baseChannel)-\(suffix)"
                        } else {
                            // Might be host triple, store as version for now
                            config.version = suffix
                        }
                    } else {
                        // Not a recognized format, store as version
                        config.version = channelStr
                    }
                } else {
                    // Unknown format, store as version
                    config.version = channelStr
                }
            }
        }
        
        // Note: According to spec, 'version' field in TOML is not standard
        // But we'll parse it if present for backward compatibility
        if let version = toolchain.version {
            config.version = version
        }
        
        config.components = toolchain.components ?? []
        config.targets = toolchain.targets ?? []
        
        if let profileStr = toolchain.profile {
            config.profile = ProjectToolchainConfig.ToolchainProfile(rawValue: profileStr)
        }
        
        return config
    }
    
    // MARK: - Serialize to TOML
    
    /// Serializes ProjectToolchainConfig to TOML string
    /// According to rust-toolchain.toml spec:
    /// - channel format: <channel>[-<date>][-<host>]
    /// - channel can be: stable|beta|nightly|<versioned> (e.g., 1.42, 1.42.0)
    /// - versioned can have prerelease: <major.minor>|<major.minor.patch>[-beta[.<number>]]
    /// - date format: YYYY-MM-DD (e.g., nightly-2014-12-18)
    /// - Only 'channel' field is used, not 'version' field
    static func serialize(_ config: ProjectToolchainConfig) throws -> String {
        var toml = "[toolchain]\n"
        
        // Build channel string according to spec
        var channelValue: String?
        
        if let channel = config.channel, let version = config.version, !version.isEmpty {
            // Both channel and version specified
            // If version is a semver (1.75.0), use it directly as channel
            // If version is a nightly date (nightly-2024-01-01), use it directly
            // If version is just a number, combine with channel
            if version.range(of: "^\\d+\\.\\d+(\\.\\d+)?$", options: .regularExpression) != nil {
                // Version is semver format (1.75.0 or 1.75), use as channel directly
                channelValue = version
            } else if version.hasPrefix("nightly-") {
                // Version is nightly date format, use as channel
                channelValue = version
            } else {
                // Fallback: combine channel and version
                channelValue = "\(channel.rawValue)-\(version)"
            }
        } else if let channel = config.channel {
            // Only channel specified (stable, beta, nightly)
            channelValue = channel.rawValue
        } else if let version = config.version, !version.isEmpty {
            // Only version specified
            // Version can be semver (1.75.0) or nightly date (nightly-2024-01-01)
            channelValue = version
        }
        
        if let channel = channelValue {
            toml += "channel = \"\(channel)\"\n"
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
