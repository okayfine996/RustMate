//
//  UpdateValidation.swift
//  RustMate
//
//  T009: URL validation and safe degradation for update feeds
//  Based on specs/005-sparkle-auto-update/research.md
//

import Foundation

// MARK: - Update Validation

/// Validation utilities for update feeds and URLs
enum UpdateValidation {
    
    // MARK: - URL Validation
    
    /// Validate that a feed URL meets security requirements
    /// - Parameter url: The feed URL to validate
    /// - Returns: Validation result with error details if invalid
    static func validateFeedURL(_ url: URL) -> UpdateValidationResult {
        #if DEBUG
        // Allow HTTP for local network in test mode
        if ProcessInfo.processInfo.environment["SPARKLE_TEST_MODE"] == "1" {
            // Allow localhost and local network IPs (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
            if let host = url.host {
                if host == "localhost" || 
                   host == "127.0.0.1" ||
                   host.hasPrefix("192.168.") ||
                   host.hasPrefix("10.") ||
                   host.hasPrefix("172.16.") || host.hasPrefix("172.17.") ||
                   host.hasPrefix("172.18.") || host.hasPrefix("172.19.") ||
                   host.hasPrefix("172.20.") || host.hasPrefix("172.21.") ||
                   host.hasPrefix("172.22.") || host.hasPrefix("172.23.") ||
                   host.hasPrefix("172.24.") || host.hasPrefix("172.25.") ||
                   host.hasPrefix("172.26.") || host.hasPrefix("172.27.") ||
                   host.hasPrefix("172.28.") || host.hasPrefix("172.29.") ||
                   host.hasPrefix("172.30.") || host.hasPrefix("172.31.") {
                    return .valid
                }
            }
        }
        #endif
        
        // Contract requirement: MUST be HTTPS
        guard url.scheme == "https" else {
            return .invalid(reason: "Feed URL must use HTTPS (got: \(url.scheme ?? "none"))")
        }
        
        // Validate host is not empty
        guard let host = url.host, !host.isEmpty else {
            return .invalid(reason: "Feed URL must have a valid host")
        }
        
        // Validate path is not empty (should point to an XML file)
        guard !url.path.isEmpty else {
            return .invalid(reason: "Feed URL must have a valid path")
        }
        
        return .valid
    }
    
    /// Validate download URL from appcast entry
    /// - Parameter url: The download URL to validate
    /// - Returns: Validation result with error details if invalid
    static func validateDownloadURL(_ url: URL) -> UpdateValidationResult {
        // Must be HTTPS
        guard url.scheme == "https" else {
            return .invalid(reason: "Download URL must use HTTPS")
        }
        
        // Should point to a DMG file
        let pathExtension = url.pathExtension.lowercased()
        guard pathExtension == "dmg" else {
            return .invalid(reason: "Download URL must point to a DMG file (got: .\(pathExtension))")
        }
        
        return .valid
    }
    
    // MARK: - System Version Validation
    
    /// Check if current system meets minimum version requirement
    /// T021: Enhanced system version validation with clear messaging
    /// - Parameter minimumVersion: Required version string (e.g., "15.0")
    /// - Returns: Validation result with error details if unsupported
    static func validateSystemVersion(minimumVersion: String) -> UpdateValidationResult {
        let currentVersion = ProcessInfo.processInfo.operatingSystemVersion
        
        // Parse minimum version
        let components = minimumVersion.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else {
            return .invalid(reason: "Invalid minimum version format: \(minimumVersion)")
        }
        
        let requiredMajor = components[0]
        let requiredMinor = components[1]
        
        // Compare versions
        if currentVersion.majorVersion > requiredMajor {
            return .valid
        } else if currentVersion.majorVersion == requiredMajor {
            if currentVersion.minorVersion >= requiredMinor {
                return .valid
            }
        }
        
        // T021: System version too old - provide clear message
        let currentVersionString = "\(currentVersion.majorVersion).\(currentVersion.minorVersion).\(currentVersion.patchVersion)"
        print("⚠️ UpdateValidation: System version \(currentVersionString) does not meet minimum \(minimumVersion)")
        print("   This update will be blocked from installation")
        
        return .unsupportedSystem(
            required: minimumVersion,
            current: currentVersionString
        )
    }
    
    /// T021: Check if current system can install updates for this app
    /// Returns true if system meets the minimum macOS 15.0 requirement
    static func canInstallUpdates() -> Bool {
        let result = validateSystemVersion(minimumVersion: "15.0")
        return result.isValid
    }
    
    // MARK: - Safe Degradation
    
    /// Safely handle invalid feed entries by filtering them out
    /// - Parameter entries: Raw feed entries from appcast
    /// - Returns: Filtered entries that pass validation
    static func filterValidEntries(_ entries: [FeedEntry]) -> [FeedEntry] {
        entries.filter { entry in
            // Validate download URL
            guard case .valid = validateDownloadURL(entry.downloadURL) else {
                print("⚠️ UpdateValidation: Skipping entry with invalid download URL: \(entry.downloadURL)")
                return false
            }
            
            // Validate system version
            if let minVersion = entry.minimumSystemVersion {
                guard case .valid = validateSystemVersion(minimumVersion: minVersion) else {
                    print("⚠️ UpdateValidation: Skipping entry with unsupported system version: \(minVersion)")
                    return false
                }
            }
            
            // Validate version strings are not empty
            guard !entry.version.isEmpty, !entry.buildNumber.isEmpty else {
                print("⚠️ UpdateValidation: Skipping entry with empty version info")
                return false
            }
            
            return true
        }
    }
}

// MARK: - Update Validation Result

enum UpdateValidationResult: Equatable {
    case valid
    case invalid(reason: String)
    case unsupportedSystem(required: String, current: String)
    
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let reason):
            return reason
        case .unsupportedSystem(let required, let current):
            return "System version \(current) does not meet minimum requirement \(required)"
        }
    }
}

// MARK: - Feed Entry (placeholder for Sparkle integration)

/// Represents a single entry from an appcast feed
/// This will be mapped from Sparkle's SUAppcastItem in actual implementation
struct FeedEntry {
    let version: String                 // Display version
    let buildNumber: String             // Build number for comparison
    let downloadURL: URL                // DMG download URL
    let minimumSystemVersion: String?   // Minimum macOS version
    let releaseNotesURL: URL?           // Optional release notes
    let fileSize: Int64?                // File size in bytes
}

