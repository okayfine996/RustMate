//
//  UpdateFeeds.swift
//  RustMate
//
//  T008: Update feed configuration (stable/beta channels)
//  Based on specs/005-sparkle-auto-update/contracts/appcast-contract.md
//

import Foundation

// MARK: - Update Feed Configuration

/// Configuration for update feeds (appcast URLs)
struct UpdateFeedConfig {
    let channel: AppSettings.UpdateChannel
    let url: URL
    let minimumSystemVersion: String
    
    // MARK: - Predefined Feeds
    
    /// Stable channel feed (default for all users)
    static let stable = UpdateFeedConfig(
        channel: .stable,
        url: URL(string: stableURL)!,
        minimumSystemVersion: "15.0"
    )
    
    /// Beta channel feed (opt-in for early adopters)
    static let beta = UpdateFeedConfig(
        channel: .beta,
        url: URL(string: betaURL)!,
        minimumSystemVersion: "15.0"
    )
    
    // MARK: - URL Configuration (supports local testing)
    
    /// Get stable feed URL (supports SPARKLE_TEST_MODE environment variable)
    private static var stableURL: String {
        #if DEBUG
        if ProcessInfo.processInfo.environment["SPARKLE_TEST_MODE"] == "1" {
            return "http://192.168.31.70:8000/test-appcast-stable.xml"
        }
        #endif
        return "https://okayfine996.github.io/RustMate/appcast-stable.xml"
    }
    
    /// Get beta feed URL (supports SPARKLE_TEST_MODE environment variable)
    private static var betaURL: String {
        #if DEBUG
        if ProcessInfo.processInfo.environment["SPARKLE_TEST_MODE"] == "1" {
            return "http://192.168.31.70:8000/test-appcast-beta.xml"
        }
        #endif
        return "https://okayfine996.github.io/RustMate/appcast-beta.xml"
    }
    
    // MARK: - Feed Selection
    
    /// Get feed configuration for a specific channel
    static func feed(for channel: AppSettings.UpdateChannel) -> UpdateFeedConfig {
        switch channel {
        case .stable:
            return .stable
        case .beta:
            return .beta
        }
    }
    
    // MARK: - Validation
    
    /// Validate that the feed URL is HTTPS (required by contract)
    var isSecure: Bool {
        url.scheme == "https"
    }
    
    /// Check if current system version meets minimum requirement
    func meetsSystemRequirement() -> Bool {
        let currentVersion = ProcessInfo.processInfo.operatingSystemVersion
        let currentVersionString = "\(currentVersion.majorVersion).\(currentVersion.minorVersion)"
        
        // Simple version comparison (assumes X.Y format)
        let components = minimumSystemVersion.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else { return false }
        
        let requiredMajor = components[0]
        let requiredMinor = components[1]
        
        if currentVersion.majorVersion > requiredMajor {
            return true
        } else if currentVersion.majorVersion == requiredMajor {
            return currentVersion.minorVersion >= requiredMinor
        } else {
            return false
        }
    }
}

// MARK: - Feed URLs (for reference and documentation)

/// Documented feed URLs for external reference
enum FeedURLs {
    /// Stable channel appcast URL
    /// - Hosted on: GitHub Pages
    /// - Contains: Only stable releases (non-pre-release)
    /// - Target: All users (default)
    static let stableAppcast = "https://okayfine996.github.io/RustMate/appcast-stable.xml"
    
    /// Beta channel appcast URL
    /// - Hosted on: GitHub Pages
    /// - Contains: Beta releases + stable releases
    /// - Target: Users who opt-in to "Receive Beta Updates"
    static let betaAppcast = "https://okayfine996.github.io/RustMate/appcast-beta.xml"
    
    /// GitHub Releases base URL
    /// - DMG assets are uploaded here
    /// - Format: https://github.com/okayfine996/RustMate/releases/download/v{version}/RustMate-{version}.dmg
    static let releasesBase = "https://github.com/okayfine996/RustMate/releases"
}

