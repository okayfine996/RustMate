import Foundation
import Combine
import SwiftUI

/// User-configurable application settings
struct AppSettings: Codable, Sendable {
    var rustupPath: String?
    var cargoPath: String?
    var authorizedDirectories: [AuthorizedDirectory]
    var autoRefreshOnActivation: Bool
    var refreshIntervalSeconds: Int
    var enableTaskNotifications: Bool
    var enableToolchainUpdateNotifications: Bool

    // T006: Update channel preference (stable/beta)
    var updateChannel: UpdateChannel

    // Appearance mode preference (light/dark/auto)
    var appearanceMode: AppearanceMode

    init(
        rustupPath: String? = nil,
        cargoPath: String? = nil,
        authorizedDirectories: [AuthorizedDirectory] = [],
        autoRefreshOnActivation: Bool = true,
        refreshIntervalSeconds: Int = 30,
        enableTaskNotifications: Bool = true,
        enableToolchainUpdateNotifications: Bool = false,
        updateChannel: UpdateChannel = .stable,
        appearanceMode: AppearanceMode = .auto
    ) {
        self.rustupPath = rustupPath
        self.cargoPath = cargoPath
        self.authorizedDirectories = authorizedDirectories
        self.autoRefreshOnActivation = autoRefreshOnActivation
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.enableTaskNotifications = enableTaskNotifications
        self.enableToolchainUpdateNotifications = enableToolchainUpdateNotifications
        self.updateChannel = updateChannel
        self.appearanceMode = appearanceMode
    }

    enum OverrideStrategy: String, Codable, Sendable {
        case toolchainFile      // Write rust-toolchain.toml
        case rustupOverride     // Use rustup override set

        var displayText: String {
            switch self {
            case .toolchainFile: return "Write rust-toolchain.toml (recommended)"
            case .rustupOverride: return "Use rustup override"
            }
        }

        var helpText: String {
            switch self {
            case .toolchainFile:
                return "Creates or updates rust-toolchain.toml in the project. Can be committed to version control."
            case .rustupOverride:
                return "Uses rustup's override database. Does not modify project files."
            }
        }
    }
    
    // T006: Update channel enum
    enum UpdateChannel: String, Codable, Sendable {
        case stable
        case beta

        var displayText: String {
            switch self {
            case .stable: return "Stable"
            case .beta: return "Beta"
            }
        }
    }

    // Appearance mode enum
    enum AppearanceMode: String, Codable, Sendable {
        case light
        case dark
        case auto

        var displayText: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .auto: return "Auto"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .auto: return nil  // nil means follow system
            }
        }

        var icon: String {
            switch self {
            case .light: return "sun.max"
            case .dark: return "moon"
            case .auto: return "circle.lefthalf.filled"
            }
        }
    }

    /// Default settings - loads from UserDefaults if available
    static var `default`: AppSettings {
        if let savedSettings = AppUserDefaults.shared.appSettings {
            print("📂 AppSettings.default: Loaded persisted settings, authorized directories count: \(savedSettings.authorizedDirectories.count)")
            return savedSettings
        } else {
            print("📂 AppSettings.default: No saved settings found, returning empty defaults")
            return AppSettings(
                rustupPath: nil,
                cargoPath: nil,
                authorizedDirectories: []
            )
        }
    }

    // MARK: - Authorization Helpers (Single Source of Truth)

    /// Returns all authorized directories for a specific purpose
    /// Handles legacy rustupAccess entries by treating them as rustupExecutableDir
    func authorizedDirectories(for purpose: AuthorizedDirectory.DirectoryPurpose) -> [AuthorizedDirectory] {
        return authorizedDirectories.filter { entry in
            // Direct match
            if entry.purpose == purpose {
                return true
            }
            // Legacy migration: treat rustupAccess as rustupExecutableDir
            if purpose == .rustupExecutableDir && entry.purpose == .rustupAccess {
                return true
            }
            return false
        }
    }

    /// Returns the first authorized directory for a specific purpose (if any)
    func authorizedDirectory(for purpose: AuthorizedDirectory.DirectoryPurpose) -> AuthorizedDirectory? {
        return authorizedDirectories(for: purpose).first
    }

    /// Checks if at least one authorization exists for the given purpose
    func hasAuthorization(for purpose: AuthorizedDirectory.DirectoryPurpose) -> Bool {
        return authorizedDirectory(for: purpose) != nil
    }

    /// Returns all required authorization purposes for sandboxed rustup execution
    static var requiredAuthorizationPurposes: [AuthorizedDirectory.DirectoryPurpose] {
        return [.rustupExecutableDir, .cargoHome, .rustupHome]
    }

    /// Checks if all required authorizations are present
    var hasAllRequiredAuthorizations: Bool {
        return Self.requiredAuthorizationPurposes.allSatisfy { purpose in
            hasAuthorization(for: purpose)
        }
    }

    /// Returns a list of missing required authorization purposes
    var missingRequiredAuthorizations: [AuthorizedDirectory.DirectoryPurpose] {
        return Self.requiredAuthorizationPurposes.filter { purpose in
            !hasAuthorization(for: purpose)
        }
    }
}
