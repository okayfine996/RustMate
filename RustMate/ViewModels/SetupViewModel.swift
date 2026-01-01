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
    @Published var hasCargoBookmark = false
    @Published var setupCompleted = false

    private let validator: EnvironmentValidator
    private let bookmarkManager = BookmarkManager()

    var hasRequiredBookmarks: Bool {
        hasCargoBookmark
    }

    init(validator: EnvironmentValidator = EnvironmentValidator()) {
        self.validator = validator
        checkExistingBookmarks()
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

    private func checkExistingBookmarks() {
        let cargoPath = NSString(string: "~/.cargo/bin").expandingTildeInPath
        hasCargoBookmark = bookmarkManager.hasBookmark(for: cargoPath)
    }

    func authorizeCargoAccess() {
        let panel = NSOpenPanel()
        panel.message = "Select your .cargo/bin directory"
        panel.prompt = "Authorize"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.directoryURL = URL(fileURLWithPath: NSString(string: "~/.cargo/bin").expandingTildeInPath)

        panel.begin { [weak self] response in
            guard let self = self else { return }

            if response == .OK, let url = panel.url {
                do {
                    _ = try self.bookmarkManager.createBookmark(for: url)
                    self.hasCargoBookmark = true

                    // Notify XPC service about the new bookmark
                    XPCClient.shared.updateCargoBookmark()
                } catch {
                    print("Failed to create bookmark: \(error)")
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
