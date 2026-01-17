//
//  ProjectDiagnostics.swift
//  RustMate
//
//  Model for project toolchain configuration diagnostics
//

import Foundation

/// Represents diagnostic information about a project's toolchain configuration
struct ProjectDiagnostics: Codable, Sendable {
    let actualToolchainVersion: String?
    let configuredVersion: String?
    let overrideVersion: String?
    let hasMismatch: Bool
    let msrvViolation: MSRVViolation?
    let conflictDetails: [ConflictDetail]
    let toolchainSource: ToolchainSource
    
    init(
        actualToolchainVersion: String? = nil,
        configuredVersion: String? = nil,
        overrideVersion: String? = nil,
        hasMismatch: Bool = false,
        msrvViolation: MSRVViolation? = nil,
        conflictDetails: [ConflictDetail] = [],
        toolchainSource: ToolchainSource = .default
    ) {
        self.actualToolchainVersion = actualToolchainVersion
        self.configuredVersion = configuredVersion
        self.overrideVersion = overrideVersion
        self.hasMismatch = hasMismatch
        self.msrvViolation = msrvViolation
        self.conflictDetails = conflictDetails
        self.toolchainSource = toolchainSource
    }
    
    enum ToolchainSource: String, Codable, Sendable {
        case environment      // RUSTUP_TOOLCHAIN env var
        case toolchainFile    // rust-toolchain.toml
        case override         // rustup override
        case `default`        // Default toolchain
        
        var displayText: String {
            switch self {
            case .environment: return "Environment Variable"
            case .toolchainFile: return "Toolchain File"
            case .override: return "Directory Override"
            case .default: return "Default Toolchain"
            }
        }
        
        var priority: Int {
            switch self {
            case .environment: return 1
            case .toolchainFile: return 2
            case .override: return 3
            case .default: return 4
            }
        }
    }
    
    struct MSRVViolation: Codable, Sendable {
        let requiredVersion: String          // From Cargo.toml rust-version
        let configuredVersion: String       // From toolchain config
        let isViolation: Bool                // True if configured < required
        let cannotDetermine: Bool            // True if versions cannot be compared (non-semver)

        init(requiredVersion: String, configuredVersion: String, isViolation: Bool, cannotDetermine: Bool = false) {
            self.requiredVersion = requiredVersion
            self.configuredVersion = configuredVersion
            self.isViolation = isViolation
            self.cannotDetermine = cannotDetermine
        }

        var message: String {
            if cannotDetermine {
                return "MSRV check inconclusive: Cannot compare \(configuredVersion) with required \(requiredVersion). Non-semver toolchains (nightly/beta/stable) cannot be reliably compared."
            }
            if isViolation {
                return "MSRV violation: Project requires \(requiredVersion), but toolchain is \(configuredVersion)"
            }
            return "MSRV compliant: Toolchain \(configuredVersion) meets requirement \(requiredVersion)"
        }
    }
    
    struct ConflictDetail: Codable, Sendable {
        let type: ConflictType
        let message: String
        let suggestedFix: String?
        
        enum ConflictType: String, Codable, Sendable {
            case versionMismatch
            case overrideConflict
            case missingToolchain
            case missingComponents
        }
    }
}
