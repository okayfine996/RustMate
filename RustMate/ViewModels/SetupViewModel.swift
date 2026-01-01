//
//  SetupViewModel.swift
//  RustMate
//
//  ViewModel for SetupView
//

import Foundation
import AppKit
import Combine

@MainActor
class SetupViewModel: ObservableObject {
    @Published var isValidating = false
    @Published var validationResult: ValidationResult?
    @Published var customRustupPath = ""
    @Published var settings: AppSettings
    @Published var setupCompleted = false

    private let validator: EnvironmentValidator
    private let bookmarkManager = BookmarkManager()

    var hasRequiredBookmarks: Bool {
        settings.hasAllRequiredAuthorizations
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

    init(validator: EnvironmentValidator = EnvironmentValidator(), settings: AppSettings = .default) {
        self.validator = validator
        self.settings = settings
    }

    // MARK: - Validation

    func validateEnvironment() async {
        print("🔍 SetupViewModel: validateEnvironment called")
        isValidating = true
        defer {
            print("🔍 SetupViewModel: validateEnvironment finished, isValidating = \(isValidating)")
            isValidating = false
        }

        let path = customRustupPath.isEmpty ? nil : customRustupPath
        print("🔍 SetupViewModel: Validating with path: \(path ?? "nil")")
        validationResult = await validator.validateRustup(at: path)
        print("🔍 SetupViewModel: Validation result: hasRustup=\(validationResult?.hasRustup ?? false), version=\(validationResult?.version ?? "none")")
    }

    // MARK: - Bookmarks

    // Callback to notify when settings change
    var onSettingsChanged: (() -> Void)?

    func authorizeRustupExecutableDir() {
        authorizeDirectory(
            purpose: .rustupExecutableDir,
            message: "Select the directory containing the rustup executable",
            defaultPath: "~/.cargo/bin"
        )
    }

    func authorizeCargoHome() {
        authorizeDirectory(
            purpose: .cargoHome,
            message: "Select your .cargo directory",
            defaultPath: "~/.cargo"
        )
    }

    func authorizeRustupHome() {
        authorizeDirectory(
            purpose: .rustupHome,
            message: "Select your .rustup directory",
            defaultPath: "~/.rustup"
        )
    }

    private func authorizeDirectory(
        purpose: AuthorizedDirectory.DirectoryPurpose,
        message: String,
        defaultPath: String
    ) {
        let panel = NSOpenPanel()
        panel.message = message
        panel.prompt = "Authorize"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.directoryURL = URL(fileURLWithPath: NSString(string: defaultPath).expandingTildeInPath)

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

                    // Notify that settings changed (after authorization completes)
                    self.onSettingsChanged?()

                    print("✅ SetupViewModel: Authorized \(purpose.displayText) at \(url.path)")
                } catch {
                    print("❌ SetupViewModel: Failed to create bookmark for \(purpose.displayText): \(error)")
                }
            }
        }
    }

    func browseForRustup() {
        let panel = NSOpenPanel()
        panel.message = "Select rustup executable"
        panel.prompt = "Select"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/usr/local/bin")

        panel.begin { [weak self] response in
            guard let self = self else { return }

            if response == .OK, let url = panel.url {
                self.customRustupPath = url.path
                Task {
                    await self.validateEnvironment()
                }
            }
        }
    }

    // MARK: - Setup Flow

    func skipSetup() {
        setupCompleted = true
        NotificationCenter.default.post(name: NSNotification.Name("SetupCompleted"), object: nil)
    }

    func completeSetup() {
        guard hasRequiredBookmarks else { return }
        setupCompleted = true
        NotificationCenter.default.post(name: NSNotification.Name("SetupCompleted"), object: nil)
    }
}
