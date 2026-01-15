//
//  UserDefaultsStore.swift
//  RustMate
//
//  Type-safe UserDefaults access layer
//  Eliminates direct UserDefaults.standard calls and provides compile-time type checking
//

import Foundation

// MARK: - Property Wrapper

/// Property wrapper for type-safe UserDefaults access
/// Automatically handles encoding/decoding and provides a clean interface
@propertyWrapper
struct UserDefault<Value> {
    let key: String
    let defaultValue: Value
    let storage: UserDefaults

    init(key: String, defaultValue: Value, storage: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }

    var wrappedValue: Value {
        get {
            storage.object(forKey: key) as? Value ?? defaultValue
        }
        nonmutating set {
            storage.set(newValue, forKey: key)
        }
    }

    var projectedValue: UserDefault<Value> {
        return self
    }

    /// Remove the value from UserDefaults
    func remove() {
        storage.removeObject(forKey: key)
    }
}

// MARK: - Codable Support

/// Property wrapper for Codable types in UserDefaults
@propertyWrapper
struct CodableUserDefault<Value: Codable> {
    let key: String
    let defaultValue: Value
    let storage: UserDefaults

    init(key: String, defaultValue: Value, storage: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }

    var wrappedValue: Value {
        get {
            guard let data = storage.data(forKey: key) else {
                return defaultValue
            }
            do {
                let value = try JSONDecoder().decode(Value.self, from: data)
                return value
            } catch {
                print("⚠️ UserDefaultsStore: Failed to decode \(key): \(error)")
                return defaultValue
            }
        }
        nonmutating set {
            do {
                let data = try JSONEncoder().encode(newValue)
                storage.set(data, forKey: key)
            } catch {
                print("❌ UserDefaultsStore: Failed to encode \(key): \(error)")
            }
        }
    }

    var projectedValue: CodableUserDefault<Value> {
        return self
    }

    /// Remove the value from UserDefaults
    func remove() {
        storage.removeObject(forKey: key)
    }
}

// MARK: - Optional Support

/// Property wrapper for optional values in UserDefaults
@propertyWrapper
struct OptionalUserDefault<Value> {
    let key: String
    let storage: UserDefaults

    init(key: String, storage: UserDefaults = .standard) {
        self.key = key
        self.storage = storage
    }

    var wrappedValue: Value? {
        get {
            storage.object(forKey: key) as? Value
        }
        nonmutating set {
            if let value = newValue {
                storage.set(value, forKey: key)
            } else {
                storage.removeObject(forKey: key)
            }
        }
    }

    var projectedValue: OptionalUserDefault<Value> {
        return self
    }

    /// Remove the value from UserDefaults
    func remove() {
        storage.removeObject(forKey: key)
    }
}

/// Property wrapper for optional Codable values in UserDefaults
@propertyWrapper
struct OptionalCodableUserDefault<Value: Codable> {
    let key: String
    let storage: UserDefaults

    init(key: String, storage: UserDefaults = .standard) {
        self.key = key
        self.storage = storage
    }

    var wrappedValue: Value? {
        get {
            guard let data = storage.data(forKey: key) else {
                return nil
            }
            return try? JSONDecoder().decode(Value.self, from: data)
        }
        nonmutating set {
            if let value = newValue {
                if let data = try? JSONEncoder().encode(value) {
                    storage.set(data, forKey: key)
                }
            } else {
                storage.removeObject(forKey: key)
            }
        }
    }

    var projectedValue: OptionalCodableUserDefault<Value> {
        return self
    }

    /// Remove the value from UserDefaults
    func remove() {
        storage.removeObject(forKey: key)
    }
}

// MARK: - Centralized Storage

/// Centralized type-safe access to all UserDefaults keys
/// This is the single source of truth for app configuration
@MainActor
final class AppUserDefaults {

    // MARK: - Singleton

    static let shared = AppUserDefaults()
    private init() {}

    // MARK: - App Lifecycle

    @UserDefault(
        key: Constants.UserDefaultsKeys.hasCompletedFirstLaunch,
        defaultValue: false
    )
    var hasCompletedFirstLaunch: Bool

    // MARK: - Settings

    @OptionalCodableUserDefault(key: Constants.UserDefaultsKeys.appSettings)
    var appSettings: AppSettings?

    // MARK: - Projects

    @CodableUserDefault(
        key: Constants.UserDefaultsKeys.projectBookmarks,
        defaultValue: []
    )
    var projectBookmarks: [ProjectBookmark]

    // MARK: - Preferences

    @UserDefault(
        key: Constants.UserDefaultsKeys.overrideMode,
        defaultValue: Constants.Defaults.overrideMode
    )
    var overrideMode: String

    // MARK: - Utility Methods

    /// Reset all stored preferences to defaults
    func resetToDefaults() {
        _hasCompletedFirstLaunch.remove()
        _appSettings.remove()
        _projectBookmarks.remove()
        _overrideMode.remove()

        print("🔄 AppUserDefaults: Reset all preferences to defaults")
    }

    /// Print current state for debugging
    func printState() {
        print("""
        📊 AppUserDefaults State:
        - hasCompletedFirstLaunch: \(hasCompletedFirstLaunch)
        - appSettings: \(appSettings != nil ? "set" : "nil")
        - projectBookmarks count: \(projectBookmarks.count)
        - overrideMode: \(overrideMode)
        """)
    }
}

// MARK: - Backward Compatibility Helpers

extension AppUserDefaults {

    /// Legacy support: Load settings from old key if needed
    func migrateFromLegacyIfNeeded() {
        // Check if we need to migrate from old UserDefaults keys
        // This can be implemented if there are old keys to migrate from
    }
}
