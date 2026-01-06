import Foundation
import Combine

/// User-configurable application settings
struct AppSettings: Codable, Sendable {
    var rustupPath: String?
    var cargoPath: String?
    var overrideStrategy: OverrideStrategy
    var authorizedDirectories: [AuthorizedDirectory]
    var autoRefreshOnActivation: Bool
    var enableTaskNotifications: Bool
    
    // T006: Update channel preference (stable/beta)
    var updateChannel: UpdateChannel

    init(
        rustupPath: String? = nil,
        cargoPath: String? = nil,
        overrideStrategy: OverrideStrategy = .toolchainFile,
        authorizedDirectories: [AuthorizedDirectory] = [],
        autoRefreshOnActivation: Bool = true,
        enableTaskNotifications: Bool = true,
        updateChannel: UpdateChannel = .stable
    ) {
        self.rustupPath = rustupPath
        self.cargoPath = cargoPath
        self.overrideStrategy = overrideStrategy
        self.authorizedDirectories = authorizedDirectories
        self.autoRefreshOnActivation = autoRefreshOnActivation
        self.enableTaskNotifications = enableTaskNotifications
        self.updateChannel = updateChannel
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

    /// Default settings - loads from UserDefaults if available
    static var `default`: AppSettings {
        let settingsKey = "RustMate.AppSettings"

        guard let data = UserDefaults.standard.data(forKey: settingsKey) else {
            print("📂 AppSettings.default: No saved settings found, returning empty defaults")
            return AppSettings(
                rustupPath: nil,
                cargoPath: nil,
                overrideStrategy: .toolchainFile,
                authorizedDirectories: []
            )
        }

        do {
            let decoder = JSONDecoder()
            let settings = try decoder.decode(AppSettings.self, from: data)
            print("📂 AppSettings.default: Loaded persisted settings, authorized directories count: \(settings.authorizedDirectories.count)")
            return settings
        } catch {
            print("❌ AppSettings.default: Failed to decode settings: \(error), returning empty defaults")
            return AppSettings(
                rustupPath: nil,
                cargoPath: nil,
                overrideStrategy: .toolchainFile,
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
