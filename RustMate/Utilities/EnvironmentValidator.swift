//
//  EnvironmentValidator.swift
//  RustMate
//
//  Validates rustup installation and environment
//

import Foundation

class EnvironmentValidator {

    private let bookmarkManager: BookmarkServiceProtocol

    init(bookmarkManager: BookmarkServiceProtocol = BookmarkManager()) {
        self.bookmarkManager = bookmarkManager
    }

    /// Check if rustup is accessible at the given path or default locations
    /// In sandbox mode, only checks file existence - actual execution happens in XPC Service
    func validateRustup(at customPath: String? = nil) async -> ValidationResult {
        print("🔍 EnvironmentValidator: validateRustup called with customPath=\(customPath ?? "nil")")

        let possiblePaths = [
            customPath,
            "~/.cargo/bin/rustup",
            "/usr/local/bin/rustup",
            "/opt/homebrew/bin/rustup"
        ].compactMap { $0 }

        print("🔍 EnvironmentValidator: Checking paths: \(possiblePaths)")

        for path in possiblePaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            print("🔍 EnvironmentValidator: Checking path: \(expandedPath)")

            // Check if file exists (with bookmark if available)
            if checkFileExists(at: expandedPath) {
                print("✅ EnvironmentValidator: Found rustup at \(expandedPath)")
                return ValidationResult(
                    hasRustup: true,
                    rustupPath: expandedPath,
                    version: nil, // Version will be checked by XPC Service
                    hints: []
                )
            } else {
                print("❌ EnvironmentValidator: File does not exist at \(expandedPath)")
            }
        }

        // Rustup not found
        print("❌ EnvironmentValidator: Rustup not found at any location")
        return ValidationResult(
            hasRustup: false,
            rustupPath: nil,
            version: nil,
            hints: [
                "Rustup not found at expected locations",
                "Install rustup: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh",
                "Or grant access to ~/.cargo/bin in Settings"
            ]
        )
    }

    /// Check if file exists, using bookmark if available
    private func checkFileExists(at path: String) -> Bool {
        // Try with bookmark first
        let url = URL(fileURLWithPath: path)
        let parentPath = url.deletingLastPathComponent().path

        if bookmarkManager.hasBookmark(for: parentPath) {
            do {
                let bookmarkURL = try bookmarkManager.resolveBookmark(for: parentPath)
                guard bookmarkURL.startAccessingSecurityScopedResource() else {
                    return false
                }
                defer {
                    bookmarkURL.stopAccessingSecurityScopedResource()
                }
                return FileManager.default.fileExists(atPath: path)
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        }

        // Fallback to direct check (may fail in sandbox)
        return FileManager.default.fileExists(atPath: path)
    }

}
