//
//  ProjectHealthStatus.swift
//  RustMate
//
//  Model for project configuration health status
//

import Foundation
import SwiftUI

/// Represents the health/status of a project's configuration
struct ProjectHealthStatus: Codable, Sendable {
    let status: HealthStatus
    let indicatorColor: IndicatorColor
    let lastChecked: Date
    let details: String?
    
    init(
        status: HealthStatus,
        indicatorColor: IndicatorColor,
        lastChecked: Date = Date(),
        details: String? = nil
    ) {
        self.status = status
        self.indicatorColor = indicatorColor
        self.lastChecked = lastChecked
        self.details = details
    }
    
    enum HealthStatus: String, Codable, Sendable {
        case healthy
        case missingComponents
        case versionMismatch
        case overrideConflict
        case unknown
        
        var displayText: String {
            switch self {
            case .healthy: return "Healthy"
            case .missingComponents: return "Missing Components"
            case .versionMismatch: return "Version Mismatch"
            case .overrideConflict: return "Override Conflict"
            case .unknown: return "Unknown"
            }
        }
    }
    
    enum IndicatorColor: String, Codable, Sendable {
        case green
        case red
        case yellow
        
        var systemColor: Color {
            switch self {
            case .green: return .green
            case .red: return .red
            case .yellow: return .yellow
            }
        }
    }
    
    // MARK: - Factory Method
    
    /// Calculates health status from diagnostics and installation status
    static func calculate(
        from diagnostics: ProjectDiagnostics,
        toolchainInstalled: Bool,
        componentsAvailable: Bool
    ) -> ProjectHealthStatus {
        // MSRV violation is the most critical issue - always red
        if let msrv = diagnostics.msrvViolation, msrv.isViolation {
            return ProjectHealthStatus(
                status: .versionMismatch,
                indicatorColor: .red,
                lastChecked: Date(),
                details: msrv.message
            )
        }
        
        // If toolchain is not installed (based on toolchainInstalled flag)
        if !toolchainInstalled {
            // This means both actualToolchainVersion is nil AND toolchainSource is .default
            // This likely means toolchain is not installed or rustup is not working
            return ProjectHealthStatus(
                status: .missingComponents,
                indicatorColor: .red,
                lastChecked: Date(),
                details: "Toolchain not installed or cannot be determined"
            )
        }
        
        if !componentsAvailable {
            return ProjectHealthStatus(
                status: .missingComponents,
                indicatorColor: .red,
                lastChecked: Date(),
                details: "Required components not available"
            )
        }
        
        // Check for override conflicts first (before version mismatch)
        // Override conflicts occur when both rust-toolchain.toml and rustup override exist
        let hasOverrideConflict = diagnostics.conflictDetails.contains(where: { $0.type == .overrideConflict })
        if hasOverrideConflict {
            // Use the message from conflictDetails if available
            let conflictMessage = diagnostics.conflictDetails.first(where: { $0.type == .overrideConflict })?.message ?? "Override conflicts detected"
            return ProjectHealthStatus(
                status: .overrideConflict,
                indicatorColor: .yellow,
                lastChecked: Date(),
                details: conflictMessage
            )
        }
        
        // Version mismatches are warnings (yellow), not errors
        if diagnostics.hasMismatch {
            return ProjectHealthStatus(
                status: .versionMismatch,
                indicatorColor: .yellow,
                lastChecked: Date(),
                details: "Version mismatch detected"
            )
        }

        // Handle cases where actualToolchainVersion is nil (version parsing failed)
        if diagnostics.actualToolchainVersion == nil {
            // If using default toolchain, this is completely normal and healthy
            if diagnostics.toolchainSource == .default {
                return ProjectHealthStatus(
                    status: .healthy,
                    indicatorColor: .green,
                    lastChecked: Date(),
                    details: "Using default toolchain"
                )
            }

            // If using explicit configuration (override or toolchainFile), version parsing failed
            // This is a minor issue - toolchain works but we can't show version
            return ProjectHealthStatus(
                status: .healthy,
                indicatorColor: .green,
                lastChecked: Date(),
                details: "Toolchain is active (version parsing unavailable)"
            )
        }

        // All checks passed - healthy
        return ProjectHealthStatus(
            status: .healthy,
            indicatorColor: .green,
            lastChecked: Date(),
            details: "Configuration is healthy"
        )
    }
}
