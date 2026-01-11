//
//  ProjectCargoConfig.swift
//  RustMate
//
//  Model for Cargo build configuration (.cargo/config.toml)
//

import Foundation

/// Represents Cargo build configuration for a project, stored in .cargo/config.toml
struct ProjectCargoConfig: Codable, Sendable {
    var registryMirror: RegistryMirror?
    var aliases: [String: String]
    var linker: LinkerOption?
    var rustflags: String?
    var proxySettings: ProxySettings?
    
    init(
        registryMirror: RegistryMirror? = nil,
        aliases: [String: String] = [:],
        linker: LinkerOption? = nil,
        rustflags: String? = nil,
        proxySettings: ProxySettings? = nil
    ) {
        self.registryMirror = registryMirror
        self.aliases = aliases
        self.linker = linker
        self.rustflags = rustflags
        self.proxySettings = proxySettings
    }
    
    enum RegistryMirror: String, Codable, Sendable {
        case cratesIo = "crates-io"
        case tsinghua
        case ustc
        case byteDance
        
        var displayText: String {
            switch self {
            case .cratesIo: return "Crates.io (Default)"
            case .tsinghua: return "Tsinghua"
            case .ustc: return "USTC"
            case .byteDance: return "ByteDance"
            }
        }
        
        var registryURL: String? {
            switch self {
            case .cratesIo: return nil  // Default, no replacement needed
            case .tsinghua: return "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
            case .ustc: return "https://mirrors.ustc.edu.cn/crates.io-index.git"
            case .byteDance: return "https://rsproxy.cn/crates.io-index"
            }
        }
    }
    
    enum LinkerOption: String, Codable, Sendable {
        case mold
        case zld
        case none
        
        var displayText: String {
            switch self {
            case .mold: return "mold"
            case .zld: return "zld"
            case .none: return "None (Default)"
            }
        }
    }
    
    struct ProxySettings: Codable, Sendable {
        var httpProxy: String?
        var httpsProxy: String?
        
        /// Validates proxy URL format
        static func validateURL(_ url: String) -> Bool {
            guard let urlObj = URL(string: url) else { return false }
            return ["http", "https"].contains(urlObj.scheme?.lowercased())
        }
    }
    
    // MARK: - Validation
    
    /// Validates alias name format
    static func validateAlias(_ alias: String) -> Bool {
        return alias.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil &&
               alias.count <= 32
    }
    
    /// Validates the entire configuration
    func validate() -> [String] {
        var errors: [String] = []
        
        for (alias, _) in aliases {
            if !Self.validateAlias(alias) {
                errors.append("Invalid alias name: \(alias)")
            }
        }
        
        if let proxy = proxySettings {
            if let http = proxy.httpProxy, !ProxySettings.validateURL(http) {
                errors.append("Invalid HTTP proxy URL: \(http)")
            }
            if let https = proxy.httpsProxy, !ProxySettings.validateURL(https) {
                errors.append("Invalid HTTPS proxy URL: \(https)")
            }
        }
        
        return errors
    }
}
