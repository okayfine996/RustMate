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
    @Published var xpcConnectionStatus: Bool?
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

    // Computed properties
    var hasCargoBookmark: Bool {
        !settings.authorizedDirectories.filter { $0.purpose == .rustupAccess }.isEmpty
    }

    var authorizedProjects: [AuthorizedDirectory] {
        settings.authorizedDirectories.filter { $0.purpose == .projectAccess }
    }

    private let validator = EnvironmentValidator()
    private let bookmarkManager = BookmarkManager()
    private let xpcClient = XPCClient.shared

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

    // MARK: - Bookmarks

    func authorizeDirectory(purpose: AuthorizedDirectory.DirectoryPurpose) {
        let panel = NSOpenPanel()
        panel.message = purpose == .rustupAccess
            ? "Select your .cargo/bin directory"
            : "Select a Rust project directory"
        panel.prompt = "Authorize"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        if purpose == .rustupAccess {
            panel.directoryURL = URL(fileURLWithPath: NSString(string: "~/.cargo/bin").expandingTildeInPath)
        }

        panel.begin { [weak self] response in
            guard let self = self else { return }

            if response == .OK, let url = panel.url {
                do {
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

                    // Notify XPC service if this is cargo bookmark
                    if purpose == .rustupAccess {
                        self.xpcClient.updateCargoBookmark()
                    }
                } catch let error as BookmarkManager.BookmarkError {
                    self.handleBookmarkError(error, path: url.path)
                } catch {
                    self.errorMessage = "Failed to create bookmark: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }

    func removeBookmark(purpose: AuthorizedDirectory.DirectoryPurpose) {
        settings.authorizedDirectories.removeAll { $0.purpose == purpose }
        objectWillChange.send()
    }

    func removeProjectBookmark(path: String) {
        settings.authorizedDirectories.removeAll { $0.path == path }
        objectWillChange.send()
    }

    // MARK: - XPC Connection

    func testXPCConnection() async {
        guard let proxy = xpcClient.getProxy() else {
            xpcConnectionStatus = false
            return
        }

        await withCheckedContinuation { continuation in
            proxy.ping { success in
                Task { @MainActor in
                    self.xpcConnectionStatus = success
                    continuation.resume()
                }
            }
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
        xpcConnectionStatus = nil
    }
}
