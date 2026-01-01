//
//  SettingsViewModel.swift
//  RustMate
//
//  ViewModel for SettingsView
//

import Foundation
import AppKit
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var rustupVersion: String?
    @Published var showResetConfirmation = false

    // Error handling
    @Published var errorMessage: String?
    @Published var showError = false

    // Bindings to settings properties
    @Published var rustupPath: String
    @Published var overrideStrategy: AppSettings.OverrideStrategy
    @Published var showDetailedOutput: Bool
    @Published var autoRefresh: Bool
    @Published var rustupHome: String
    @Published var cargoHome: String

    // T048: Authorization state for new purposes
    @Published var authorizationStates: [AuthorizedDirectory.DirectoryPurpose: AuthorizationState] = [:]

    // Computed properties
    var hasCargoBookmark: Bool {
        // Use new helper API - supports legacy rustupAccess entries
        settings.hasAuthorization(for: .rustupExecutableDir)
    }

    var authorizedProjects: [AuthorizedDirectory] {
        // Use new helper API
        settings.authorizedDirectories(for: .projectAccess)
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

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
        self.rustupPath = settings.rustupPath ?? ""
        self.overrideStrategy = settings.overrideStrategy
        self.showDetailedOutput = settings.showDetailedTaskOutput
        self.autoRefresh = settings.autoRefreshOnActivation
        self.rustupHome = settings.environmentVariables["RUSTUP_HOME"] ?? ""
        self.cargoHome = settings.environmentVariables["CARGO_HOME"] ?? ""

        Task {
            await validateEnvironment()
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
                        name: NSNotification.Name("AuthorizationCompleted"),
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

    func removeProjectBookmark(path: String) {
        settings.authorizedDirectories.removeAll { $0.path == path }
        objectWillChange.send()
    }

    // MARK: - Authorization Validation (T053)

    /// Validates all authorization bookmarks and updates their states
    func validateAuthorizationStates() async {
        let purposesToValidate: [AuthorizedDirectory.DirectoryPurpose] = [
            .rustupExecutableDir,
            .cargoHome,
            .rustupHome,
            .projectAccess
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
        settings.overrideStrategy = overrideStrategy
        settings.showDetailedTaskOutput = showDetailedOutput
        settings.autoRefreshOnActivation = autoRefresh

        if !rustupHome.isEmpty {
            settings.environmentVariables["RUSTUP_HOME"] = rustupHome
        } else {
            settings.environmentVariables.removeValue(forKey: "RUSTUP_HOME")
        }

        if !cargoHome.isEmpty {
            settings.environmentVariables["CARGO_HOME"] = cargoHome
        } else {
            settings.environmentVariables.removeValue(forKey: "CARGO_HOME")
        }
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
        showDetailedOutput = false
        autoRefresh = true
        rustupHome = ""
        cargoHome = ""
        rustupVersion = nil
        authorizationStates = [:]
    }
}
