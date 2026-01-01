//
//  EnvironmentValidator.swift
//  RustMate
//
//  Validates rustup installation and environment
//

import Foundation

class EnvironmentValidator {

    private let bookmarkManager: BookmarkServiceProtocol
    private let processRunner = ProcessRunner()

    init(bookmarkManager: BookmarkServiceProtocol = BookmarkManager()) {
        self.bookmarkManager = bookmarkManager
    }

    /// Check if rustup is accessible and executable in sandbox mode
    /// Uses local ProcessRunner to validate rustup and get version
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
            guard checkFileExists(at: expandedPath) else {
                print("❌ EnvironmentValidator: File does not exist at \(expandedPath)")
                continue
            }

            // Try to execute rustup --version
            print("✅ EnvironmentValidator: Found rustup at \(expandedPath), attempting to execute")
            if let version = await tryExecuteRustup(at: expandedPath) {
                print("✅ EnvironmentValidator: Successfully executed rustup, version: \(version)")
                return ValidationResult(
                    hasRustup: true,
                    rustupPath: expandedPath,
                    version: version,
                    hints: []
                )
            } else {
                print("⚠️ EnvironmentValidator: Found rustup but couldn't execute (may need authorization)")
            }
        }

        // Rustup not found or not executable
        print("❌ EnvironmentValidator: Rustup not found or not executable")
        return ValidationResult(
            hasRustup: false,
            rustupPath: nil,
            version: nil,
            hints: [
                "Rustup not found or cannot be executed in sandbox mode",
                "Install rustup: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh",
                "Authorize access to ~/.cargo/bin, ~/.cargo, and ~/.rustup in the setup flow"
            ]
        )
    }

    /// Try to execute rustup --version and parse the output
    private func tryExecuteRustup(at path: String) async -> String? {
        do {
            // Execute rustup --version with authorization if available
            let result = try await executeWithAuthorization(rustupPath: path)

            guard result.wasSuccessful else {
                print("❌ EnvironmentValidator: rustup --version failed with exit code \(result.exitCode)")
                print("   stderr: \(result.stderr)")
                return nil
            }

            // Parse version from output (e.g., "rustup 1.26.0 (5af9b9484 2023-04-05)")
            let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if let versionMatch = output.range(of: #"rustup [\d\.]+"#, options: .regularExpression) {
                return String(output[versionMatch])
            }

            return output.isEmpty ? nil : output
        } catch {
            print("❌ EnvironmentValidator: Failed to execute rustup: \(error)")
            return nil
        }
    }

    /// Execute rustup with authorization (if available)
    private func executeWithAuthorization(rustupPath: String) async throws -> ProcessResult {
        let url = URL(fileURLWithPath: rustupPath)
        let parentPath = url.deletingLastPathComponent().path

        // Try to resolve bookmark and access
        if bookmarkManager.hasBookmark(for: parentPath) {
            do {
                let bookmarkURL = try bookmarkManager.resolveBookmark(for: parentPath)
                guard bookmarkURL.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "EnvironmentValidator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access security-scoped resource"])
                }
                defer {
                    bookmarkURL.stopAccessingSecurityScopedResource()
                }

                return try await processRunner.run(
                    executable: rustupPath,
                    arguments: ["--version"],
                    environment: nil
                )
            } catch {
                print("⚠️ EnvironmentValidator: Bookmark resolution failed: \(error)")
                throw error
            }
        }

        // Fallback: try without bookmark (may fail in sandbox)
        return try await processRunner.run(
            executable: rustupPath,
            arguments: ["--version"],
            environment: nil
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
