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
        if !toolchainInstalled {
            return ProjectHealthStatus(
                status: .missingComponents,
                indicatorColor: .red,
                lastChecked: Date(),
                details: "Toolchain version not installed"
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
        
        if diagnostics.hasMismatch {
            return ProjectHealthStatus(
                status: .versionMismatch,
                indicatorColor: .yellow,
                lastChecked: Date(),
                details: "Version mismatch detected"
            )
        }
        
        if diagnostics.conflictDetails.contains(where: { $0.type == .overrideConflict }) {
            return ProjectHealthStatus(
                status: .overrideConflict,
                indicatorColor: .yellow,
                lastChecked: Date(),
                details: "Override conflicts detected"
            )
        }
        
        if let msrv = diagnostics.msrvViolation, msrv.isViolation {
            return ProjectHealthStatus(
                status: .versionMismatch,
                indicatorColor: .red,
                lastChecked: Date(),
                details: msrv.message
            )
        }
        
        return ProjectHealthStatus(
            status: .healthy,
            indicatorColor: .green,
            lastChecked: Date(),
            details: "Configuration is healthy"
        )
    }
}
