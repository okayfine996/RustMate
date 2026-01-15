//
//  Constants.swift
//  RustMate
//
//  Centralized constants for the application
//  Eliminates magic strings and provides type-safe access to keys and identifiers
//

import Foundation

enum Constants {

    // MARK: - Notification Names

    /// Centralized notification names for app-wide events
    enum Notifications {
        /// Request to open the main application window
        static let openMainWindow = NSNotification.Name("OpenMainWindow")

        /// Setup flow has been completed successfully
        static let setupCompleted = NSNotification.Name("SetupCompleted")

        /// A single authorization has been completed
        static let authorizationCompleted = NSNotification.Name("AuthorizationCompleted")

        /// All authorizations in the queue have been completed
        static let allAuthorizationsCompleted = NSNotification.Name("AllAuthorizationsCompleted")

        /// Authorization is required (missing or stale)
        static let authorizationRequired = NSNotification.Name("AuthorizationRequired")

        /// Authorization is being requested (used by AuthorizationCoordinator)
        static let authorizationRequested = NSNotification.Name("RustMate.AuthorizationRequested")

        /// Request to open the settings window
        static let openSettings = NSNotification.Name("OpenSettings")

        /// Settings have been reset to defaults
        static let settingsReset = NSNotification.Name("SettingsReset")
    }

    // MARK: - UserDefaults Keys

    /// Keys for UserDefaults storage
    enum UserDefaultsKeys {
        /// Key for tracking whether the first launch setup has been completed
        static let hasCompletedFirstLaunch = "RustMate.hasCompletedFirstLaunch"

        /// Key for storing the main AppSettings object
        static let appSettings = "RustMate.AppSettings"

        /// Key for storing project bookmarks array
        static let projectBookmarks = "projectBookmarks"

        /// Key for storing the override mode preference (toolchainFile vs rustupOverride)
        static let overrideMode = "overrideMode"
    }

    // MARK: - Keychain Identifiers

    /// Keychain service names and identifiers
    enum Keychain {
        /// Service name for storing security-scoped bookmarks
        static let bookmarkServiceName = "com.finefine.RustMate.bookmarks"
    }

    // MARK: - Bundle Identifiers

    /// Bundle identifiers used in the application
    enum BundleIdentifiers {
        /// Main app bundle identifier
        static let app = "com.finefine.RustMate"
    }

    // MARK: - Default Values

    /// Default values for settings and configurations
    enum Defaults {
        /// Default override mode (toolchainFile = rust-toolchain.toml)
        static let overrideMode = "toolchainFile"
    }
}
