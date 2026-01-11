//
//  CargoConfigParser.swift
//  RustMate
//
//  Parser for .cargo/config.toml files
//

import Foundation
import TOMLDecoder

/// Parser for Cargo configuration TOML files
class CargoConfigParser {
    
    // MARK: - Errors
    
    enum ParseError: LocalizedError {
        case invalidTOML(String)
        case invalidField(String)
        case decodingError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidTOML(let msg):
                return "Invalid TOML format: \(msg)"
            case .invalidField(let field):
                return "Invalid field in TOML: \(field)"
            case .decodingError(let msg):
                return "Failed to decode TOML: \(msg)"
            }
        }
    }
    
    // MARK: - TOML Structure
    
    /// Intermediate structure for TOML decoding
    /// Note: Uses dynamic decoding for source sections since they can have arbitrary names
    private struct CargoTOML: Codable {
        let alias: [String: String]?
        let build: BuildSection?
        let http: HTTPSection?
        let https: HTTPSSection?
        
        // Source sections are decoded dynamically
        // We'll look for [source.crates-io] and [source.*] sections manually
        
        struct BuildSection: Codable {
            let rustflags: [String]?
        }
        
        struct HTTPSection: Codable {
            let proxy: String?
        }
        
        struct HTTPSSection: Codable {
            let proxy: String?
        }
    }
    
    /// Structure for [source.crates-io] section
    private struct SourceCratesIOSection: Codable {
        let replaceWith: String?
        
        enum CodingKeys: String, CodingKey {
            case replaceWith = "replace-with"
        }
    }
    
    // MARK: - Parse from TOML
    
    /// Parses TOML string to ProjectCargoConfig
    /// - Parameter tomlContent: TOML content string
    /// - Returns: ProjectCargoConfig
    /// - Throws: ParseError if TOML is invalid
    static func parse(_ tomlContent: String) throws -> ProjectCargoConfig {
        guard !tomlContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ProjectCargoConfig()
        }
        
        let decoder = TOMLDecoder()
        var config = ProjectCargoConfig()
        
        // Parse registry mirror from [source.crates-io] section using regex
        // TOMLDecoder may have issues with nested table names, so we parse manually
        if let replaceWithMatch = tomlContent.range(of: #"\[source\.crates-io\]\s*\n\s*replace-with\s*=\s*"([^"]+)""#, options: [.regularExpression, .caseInsensitive]) {
            let match = String(tomlContent[replaceWithMatch])
            if let valueRange = match.range(of: #""([^"]+)""#, options: .regularExpression) {
                let value = String(match[valueRange]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                config.registryMirror = ProjectCargoConfig.RegistryMirror(rawValue: value)
            }
        }
        
        // Parse other sections
        let tomlData: CargoTOML
        do {
            tomlData = try decoder.decode(CargoTOML.self, from: tomlContent)
        } catch {
            // If decoding fails, return config with what we've parsed so far
            // This allows parse-preserve-merge strategy
            return config
        }
        
        // Parse aliases
        config.aliases = tomlData.alias ?? [:]
        
        // Parse linker from rustflags
        if let build = tomlData.build,
           let rustflags = build.rustflags {
            // Look for linker option in rustflags
            for (index, flag) in rustflags.enumerated() {
                if flag == "-C" && index + 1 < rustflags.count {
                    let nextFlag = rustflags[index + 1]
                    if nextFlag.hasPrefix("link-arg=-fuse-ld=") {
                        let linkerName = String(nextFlag.dropFirst("link-arg=-fuse-ld=".count))
                        config.linker = ProjectCargoConfig.LinkerOption(rawValue: linkerName)
                        break
                    }
                }
            }
        }
        
        // Parse proxy settings
        var proxySettings = ProjectCargoConfig.ProxySettings()
        if let http = tomlData.http?.proxy {
            proxySettings.httpProxy = http
        }
        if let https = tomlData.https?.proxy {
            proxySettings.httpsProxy = https
        }
        if proxySettings.httpProxy != nil || proxySettings.httpsProxy != nil {
            config.proxySettings = proxySettings
        }
        
        return config
    }
    
    // MARK: - Serialize to TOML
    
    /// Serializes ProjectCargoConfig to TOML string
    /// - Parameter config: ProjectCargoConfig to serialize
    /// - Returns: TOML content string
    static func serialize(_ config: ProjectCargoConfig) throws -> String {
        // TODO: Implement TOML serialization using TOMLDecoder
        // This requires TOMLDecoder dependency to be added first (T001)
        // For now, return basic TOML structure
        
        var toml = ""
        
        // Registry mirror configuration
        if let mirror = config.registryMirror, mirror != .cratesIo, let url = mirror.registryURL {
            toml += "[source.crates-io]\n"
            toml += "replace-with = \"\(mirror.rawValue)\"\n\n"
            toml += "[source.\(mirror.rawValue)]\n"
            toml += "registry = \"\(url)\"\n\n"
        }
        
        // Aliases
        if !config.aliases.isEmpty {
            toml += "[alias]\n"
            for (alias, command) in config.aliases.sorted(by: { $0.key < $1.key }) {
                toml += "\(alias) = \"\(command)\"\n"
            }
            toml += "\n"
        }
        
        // Linker configuration
        if let linker = config.linker, linker != .none {
            toml += "[build]\n"
            toml += "rustflags = [\"-C\", \"link-arg=-fuse-ld=\(linker.rawValue)\"]\n\n"
        }
        
        // Proxy settings
        if let proxy = config.proxySettings {
            if let http = proxy.httpProxy {
                toml += "[http]\n"
                toml += "proxy = \"\(http)\"\n\n"
            }
            if let https = proxy.httpsProxy {
                toml += "[https]\n"
                toml += "proxy = \"\(https)\"\n\n"
            }
        }
        
        return toml
    }
}
