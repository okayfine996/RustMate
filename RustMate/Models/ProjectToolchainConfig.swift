//
//  ProjectToolchainConfig.swift
//  RustMate
//
//  Model for project toolchain configuration (rust-toolchain.toml)
//

import Foundation

/// Represents toolchain configuration for a project, stored in rust-toolchain.toml
struct ProjectToolchainConfig: Codable, Sendable, Equatable {
    var channel: ToolchainChannel?
    var version: String?
    var components: [String]
    var targets: [String]
    var profile: ToolchainProfile?
    
    init(
        channel: ToolchainChannel? = nil,
        version: String? = nil,
        components: [String] = [],
        targets: [String] = [],
        profile: ToolchainProfile? = nil
    ) {
        self.channel = channel
        self.version = version
        self.components = components
        self.targets = targets
        self.profile = profile
    }
    
    enum ToolchainChannel: String, Codable, Sendable {
        case stable
        case beta
        case nightly
        
        var displayText: String {
            switch self {
            case .stable: return "Stable"
            case .beta: return "Beta"
            case .nightly: return "Nightly"
            }
        }
    }
    
    enum ToolchainProfile: String, Codable, Sendable {
        case minimal
        case `default`
        case complete
        
        var displayText: String {
            switch self {
            case .minimal: return "Minimal"
            case .default: return "Default"
            case .complete: return "Complete"
            }
        }
        
        var description: String {
            switch self {
            case .minimal: return "Essential components only"
            case .default: return "Standard set (clippy, rustfmt)"
            case .complete: return "All available components/docs"
            }
        }
        
        var icon: String {
            switch self {
            case .minimal: return "line.3.horizontal"
            case .default: return "checkmark.square.fill"
            case .complete: return "doc.text.fill"
            }
        }
    }
    
    // MARK: - Validation
    
    /// Validates toolchain version string format
    /// Supports: channel names (stable/beta/nightly), semver (1.75.0), or nightly-date (nightly-2024-01-01)
    static func validateVersion(_ version: String) -> Bool {
        let patterns = [
            "^stable$",
            "^beta$",
            "^nightly$",
            "^\\d+\\.\\d+\\.\\d+$",  // Semver
            "^nightly-\\d{4}-\\d{2}-\\d{2}$"  // Nightly date
        ]
        return patterns.contains { version.range(of: $0, options: .regularExpression) != nil }
    }
    
    /// Validates component name
    /// Common components: rustfmt, clippy, rust-src, rust-analyzer, llvm-tools-preview
    static func validateComponent(_ component: String) -> Bool {
        let validComponents = ["rustfmt", "clippy", "rust-src", "rust-analyzer", "llvm-tools-preview"]
        return validComponents.contains(component) ||
               component.range(of: "^[A-Za-z0-9._-]+$", options: .regularExpression) != nil
    }
    
    /// Validates target triple format
    static func validateTarget(_ target: String) -> Bool {
        return target.range(of: "^[A-Za-z0-9._-]+$", options: .regularExpression) != nil &&
               target.count <= 128
    }
    
    /// Validates the entire configuration
    func validate() -> [String] {
        var errors: [String] = []
        
        if let version = version, !Self.validateVersion(version) {
            errors.append("Invalid version format: \(version)")
        }
        
        for component in components {
            if !Self.validateComponent(component) {
                errors.append("Invalid component name: \(component)")
            }
        }
        
        for target in targets {
            if !Self.validateTarget(target) {
                errors.append("Invalid target name: \(target)")
            }
        }
        
        return errors
    }
}
