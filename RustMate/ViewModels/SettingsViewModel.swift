//
//  SettingsViewModel.swift
//  RustMate
//
//  ViewModel for SettingsView
//

import Foundation
import AppKit
import Combine
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    // T004/T005: Use Binding to AppState.settings for single source of truth
    private var settingsBinding: Binding<AppSettings>
    
    var settings: AppSettings {
        get { settingsBinding.wrappedValue }
        set { settingsBinding.wrappedValue = newValue }
    }
    
    @Published var rustupVersion: String?
    @Published var currentToolchainVersion: String?
    @Published var isCheckingUpdates = false
    @Published var showResetConfirmation = false

    // Error handling
    @Published var errorMessage: String?
    @Published var showError = false

    // Bindings to settings properties
    @Published var rustupPath: String
    @Published var overrideStrategy: AppSettings.OverrideStrategy
    @Published var autoRefresh: Bool
    @Published var refreshIntervalSeconds: Int
    @Published var enableTaskNotifications: Bool
    @Published var enableToolchainUpdateNotifications: Bool

    // T048: Authorization state for new purposes
    @Published var authorizationStates: [AuthorizedDirectory.DirectoryPurpose: AuthorizationState] = [:]

    // Computed properties
    var hasCargoBookmark: Bool {
        // Use new helper API - supports legacy rustupAccess entries
        settings.hasAuthorization(for: .rustupExecutableDir)
    }

    var hasRustupExecutableDir: Bool {
        settings.hasAuthorization(for: .rustupExecutableDir)
    }

    var hasCargoHome: Bool {
        settings.hasAuthorization(for: .cargoHome)
    }

    var hasRustupHome: Bool {
        settings.hasAuthorization(for: .rustupHome)
    }

    private let validator = EnvironmentValidator()
    private let bookmarkManager = BookmarkManager()
    private let authService = AuthorizationService()

    // MARK: - Authorization State

    enum AuthorizationState {
        case authorized
        case missing
        case stale
        case invalid

        var displayText: String {
            switch self {
            case .authorized: return "Authorized"
            case .missing: return "Not Authorized"
            case .stale: return "Expired"
            case .invalid: return "Invalid"
            }
        }

        var iconName: String {
            switch self {
            case .authorized: return "checkmark.circle.fill"
            case .missing: return "xmark.circle.fill"
            case .stale: return "exclamationmark.triangle.fill"
            case .invalid: return "exclamationmark.triangle.fill"
            }
        }

        var iconColor: String {
            switch self {
            case .authorized: return "green"
            case .missing: return "gray"
            case .stale: return "orange"
            case .invalid: return "red"
            }
        }
    }

    // T004/T005: Accept Binding<AppSettings> to enable write-back
    init(settingsBinding: Binding<AppSettings>) {
        self.settingsBinding = settingsBinding
        let settings = settingsBinding.wrappedValue
        self.rustupPath = settings.rustupPath ?? ""
        self.overrideStrategy = settings.overrideStrategy
        self.autoRefresh = settings.autoRefreshOnActivation
        self.refreshIntervalSeconds = settings.refreshIntervalSeconds
        self.enableTaskNotifications = settings.enableTaskNotifications
        self.enableToolchainUpdateNotifications = settings.enableToolchainUpdateNotifications

        Task {
            await validateEnvironment()
            await loadCurrentToolchainVersion()
            await validateAuthorizationStates() // T053
        }
    }

    // MARK: - Validation

    func validateEnvironment() async {
        let result = await validator.validateRustup(at: settings.rustupPath)
        rustupVersion = result.version

        if let path = result.rustupPath {
            rustupPath = path
            settings.rustupPath = path
        }
    }
    
    // MARK: - Current Toolchain Version
    
    func loadCurrentToolchainVersion() async {
        // Get default toolchain version from rustup show
        do {
            let rustupPath = try RustupCommandResolver.resolveRustupPath(
                settings: settings,
                authService: authService
            )
            
            let env = try RustupCommandResolver.buildEnvironment(
                settings: settings,
                authService: authService
            )
            
            // Use ProcessRunner to execute on background thread
            let processRunner = ProcessRunner()
            let result = try await processRunner.runRustup(
                at: rustupPath,
                arguments: ["show"],
                environment: env,
                currentDirectoryURL: nil
            )
            
            if result.wasSuccessful {
                let output = result.stdout
                
                // Parse toolchain version from output
                // Look for patterns like "stable-aarch64-apple-darwin (default)" and "rustc 1.75.0"
                if let rustcRange = output.range(of: #"rustc\s+(\d+\.\d+\.\d+)"#, options: .regularExpression) {
                    let match = String(output[rustcRange])
                    if let versionRange = match.range(of: #"\d+\.\d+\.\d+"#, options: .regularExpression) {
                        let version = String(match[versionRange])
                        // Extract channel from toolchain name
                        var channel = "stable"
                        if let toolchainLine = output.components(separatedBy: "\n").first(where: { $0.contains("(default)") }) {
                            if toolchainLine.contains("beta") {
                                channel = "beta"
                            } else if toolchainLine.contains("nightly") {
                                channel = "nightly"
                            } else if let versionMatch = toolchainLine.range(of: #"\d+\.\d+\.\d+"#, options: .regularExpression) {
                                channel = String(toolchainLine[versionMatch])
                            }
                        }
                        currentToolchainVersion = "\(version) \(channel)"
                    }
                }
            }
        } catch {
            print("⚠️ SettingsViewModel: Failed to load current toolchain version: \(error)")
        }
    }
    
    func checkForRustupUpdates() {
        Task {
            isCheckingUpdates = true
            defer { isCheckingUpdates = false }
            
            // Refresh both rustup version and toolchain version
            await validateEnvironment()
            await loadCurrentToolchainVersion()
        }
    }

    // MARK: - Rustup Path

    func browseForRustup() {
        let panel = NSOpenPanel()
        panel.message = "Select rustup executable"
        panel.prompt = "Select"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        panel.begin { [weak self] response in
            guard let self = self else { return }

            if response == .OK, let url = panel.url {
                self.rustupPath = url.path
                self.settings.rustupPath = url.path

                Task {
                    await self.validateEnvironment()
                }
            }
        }
    }

    // MARK: - Bookmarks (T046 - Enhanced re-authorization flow)

    func authorizeDirectory(purpose: AuthorizedDirectory.DirectoryPurpose) {
        let panel = NSOpenPanel()
        panel.message = messageForPurpose(purpose)
        panel.prompt = "Authorize"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        // Set default directory based on purpose
        if let defaultURL = defaultDirectoryURL(for: purpose) {
            panel.directoryURL = defaultURL
        }

        panel.begin { [weak self] response in
            guard let self = self else { return }

            if response == .OK, let url = panel.url {
                do {
                    // Remove existing authorization for this purpose (for re-authorization scenarios)
                    self.removeExistingBookmark(for: purpose)

                    let bookmarkData = try self.bookmarkManager.createBookmark(for: url)
                    let directory = AuthorizedDirectory(
                        id: UUID(),
                        path: url.path,
                        bookmarkData: bookmarkData,
                        purpose: purpose,
                        authorizedDate: Date()
                    )
                    self.settings.authorizedDirectories.append(directory)
                    self.objectWillChange.send()

                    print("✅ SettingsViewModel: Authorized \(purpose.displayText) at \(url.path)")

                    // Notify that authorization completed
                    NotificationCenter.default.post(
                        name: Constants.Notifications.authorizationCompleted,
                        object: nil,
                        userInfo: ["purpose": purpose]
                    )
                } catch let error as BookmarkManager.BookmarkError {
                    self.handleBookmarkError(error, path: url.path)
                } catch {
                    self.errorMessage = "Failed to create bookmark: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }

    private func messageForPurpose(_ purpose: AuthorizedDirectory.DirectoryPurpose) -> String {
        switch purpose {
        case .rustupAccess:
            return "Select your .cargo/bin directory (legacy)"
        case .rustupExecutableDir:
            return "Select the directory containing rustup and cargo executables\n\nUsually: ~/.cargo/bin"
        case .cargoHome:
            return "Select your Cargo home directory\n\nUsually: ~/.cargo"
        case .rustupHome:
            return "Select your Rustup home directory\n\nUsually: ~/.rustup"
        case .projectAccess:
            return "Select your Rust project directory"
        case .customToolchainPath:
            return "Select custom toolchain directory"
        }
    }

    private func defaultDirectoryURL(for purpose: AuthorizedDirectory.DirectoryPurpose) -> URL? {
        let homePath = NSString(string: "~").expandingTildeInPath

        switch purpose {
        case .rustupAccess, .rustupExecutableDir:
            return URL(fileURLWithPath: "\(homePath)/.cargo/bin")
        case .cargoHome:
            return URL(fileURLWithPath: "\(homePath)/.cargo")
        case .rustupHome:
            return URL(fileURLWithPath: "\(homePath)/.rustup")
        case .projectAccess, .customToolchainPath:
            return nil
        }
    }

    private func removeExistingBookmark(for purpose: AuthorizedDirectory.DirectoryPurpose) {
        // Get existing directories with this purpose
        let existing = settings.authorizedDirectories.filter { $0.purpose == purpose }

        // Delete from Keychain
        for directory in existing {
            do {
                try bookmarkManager.deleteBookmark(for: directory.path)
            } catch {
                print("⚠️ Failed to delete bookmark for \(directory.path): \(error)")
            }
        }

        // Remove from settings
        settings.authorizedDirectories.removeAll { $0.purpose == purpose }
    }

    func removeBookmark(purpose: AuthorizedDirectory.DirectoryPurpose) {
        removeExistingBookmark(for: purpose)
        objectWillChange.send()
    }

    // MARK: - Authorization Validation (T053)

    /// Validates all authorization bookmarks and updates their states
    func validateAuthorizationStates() async {
        let purposesToValidate: [AuthorizedDirectory.DirectoryPurpose] = [
            .rustupExecutableDir,
            .cargoHome,
            .rustupHome
        ]

        for purpose in purposesToValidate {
            authorizationStates[purpose] = await validateAuthorization(for: purpose)
        }

        print("🔍 SettingsViewModel: Validated authorization states: \(authorizationStates)")
    }

    private func validateAuthorization(for purpose: AuthorizedDirectory.DirectoryPurpose) async -> AuthorizationState {
        // Check if we have any authorization for this purpose
        guard let directory = settings.authorizedDirectory(for: purpose) else {
            return .missing
        }

        // Try to resolve the authorization
        do {
            let resource = try authService.resolveAuthorization(for: purpose, settings: settings)
            // Successfully accessed - clean up and mark as authorized
            authService.stopAccessing([resource])
            return .authorized
        } catch let error as AuthorizationError {
            // Map authorization error to state
            switch error.category {
            case .missing:
                return .missing
            case .stale:
                return .stale
            case .denied, .invalid:
                return .invalid
            }
        } catch {
            print("⚠️ SettingsViewModel: Unexpected error validating \(purpose): \(error)")
            return .invalid
        }
    }

    // MARK: - Settings Updates

    func saveSettings() {
        // T004/T005: Write back to binding (which triggers AppState persistence)
        settings.overrideStrategy = overrideStrategy
        settings.autoRefreshOnActivation = autoRefresh
        settings.refreshIntervalSeconds = refreshIntervalSeconds
        settings.enableTaskNotifications = enableTaskNotifications
        settings.enableToolchainUpdateNotifications = enableToolchainUpdateNotifications
        // Binding automatically propagates changes to AppState
    }

    // MARK: - Error Handling

    private func handleBookmarkError(_ error: BookmarkManager.BookmarkError, path: String) {
        switch error {
        case .creationFailed:
            errorMessage = """
            Failed to create bookmark for "\(path)".

            This directory cannot be accessed due to macOS sandbox restrictions.

            Please try:
            1. Ensure the directory exists and is accessible
            2. Check that you have read permissions for this directory
            3. Try selecting the parent directory instead
            """

        case .resolutionFailed:
            errorMessage = """
            Failed to resolve bookmark for "\(path)".

            The previously authorized directory may have been moved or deleted.

            Please authorize access again.
            """

        case .accessDenied:
            errorMessage = """
            Access denied to "\(path)".

            macOS has blocked access to this directory.

            Please try:
            1. Check System Settings > Privacy & Security
            2. Ensure RustMate has necessary permissions
            3. Try authorizing a different directory
            """

        case .keychainError(let status):
            errorMessage = """
            Keychain error (status: \(status)) while saving bookmark for "\(path)".

            The bookmark could not be securely stored.

            Please try:
            1. Check that Keychain Access is not locked
            2. Restart the app and try again
            3. If the problem persists, check Console.app for errors
            """
        }

        showError = true
    }

    // MARK: - Reset

    func resetAllSettings() {
        // Clear all bookmarks
        for directory in settings.authorizedDirectories {
            try? bookmarkManager.deleteBookmark(for: directory.path)
        }

        // Reset to defaults
        settings = AppSettings()
        rustupPath = ""
        overrideStrategy = .toolchainFile
        autoRefresh = true
        enableTaskNotifications = true
        rustupVersion = nil
        authorizationStates = [:]

        // Trigger setup flow by posting notification
        NotificationCenter.default.post(name: Constants.Notifications.settingsReset, object: nil)
    }
}
