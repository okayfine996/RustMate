//
//  RustupCommandResolver.swift
//  RustMate
//
//  Determines which rustup executable to run from authorized directories
//

import Foundation

/// Resolves the rustup executable path from settings and authorized directories
struct RustupCommandResolver {

    /// Resolves the rustup executable path
    /// - Parameters:
    ///   - settings: App settings containing authorized directories
    ///   - authService: Authorization service for resolving bookmarks
    /// - Returns: Path to rustup executable
    /// - Throws: RustupExecutionError if rustup cannot be found
    static func resolveRustupPath(
        settings: AppSettings,
        authService: AuthorizationService
    ) throws -> String {
        // Priority 1: Use custom path from settings if specified
        if let customPath = settings.rustupPath, !customPath.isEmpty {
            let url = URL(fileURLWithPath: customPath)
            if FileManager.default.fileExists(atPath: url.path) {
                return url.path
            }
        }

        // Priority 2: Use authorized rustup executable directory
        guard let executableDirAuth = settings.authorizedDirectory(for: .rustupExecutableDir) else {
            throw RustupExecutionError.rustupNotFound(
                message: "No authorized directory for rustup executable. Please authorize ~/.cargo/bin in Settings.",
                suggestedFix: "Open Settings > Permissions and authorize the directory containing rustup (usually ~/.cargo/bin)."
            )
        }

        // Resolve the authorized directory
        let resource: AuthorizedResource
        do {
            resource = try authService.resolveAuthorization(
                for: .rustupExecutableDir,
                settings: settings
            )
        } catch let error as AuthorizationError {
            throw RustupExecutionError.missingAuthorization(
                purpose: .rustupExecutableDir,
                message: error.userFacingMessage,
                suggestedFix: error.suggestedFix
            )
        } catch {
            throw RustupExecutionError.rustupNotFound(
                message: "Failed to resolve rustup executable directory: \(error.localizedDescription)",
                suggestedFix: "Re-authorize the rustup executable directory in Settings > Permissions."
            )
        }

        defer { resource.stopAccessing() }

        // Look for rustup executable in the authorized directory
        let rustupPath = resource.url.appendingPathComponent("rustup").path

        guard FileManager.default.fileExists(atPath: rustupPath) else {
            throw RustupExecutionError.rustupNotFound(
                message: "rustup executable not found at \(rustupPath)",
                suggestedFix: """
                Ensure rustup is installed and located at \(rustupPath).
                If rustup is in a different location, authorize the correct directory in Settings > Permissions.
                """
            )
        }

        return rustupPath
    }

    /// Builds environment variables for rustup execution
    /// - Parameters:
    ///   - settings: App settings
    ///   - authService: Authorization service
    /// - Returns: Environment variables dictionary
    /// - Throws: RustupExecutionError if required directories cannot be resolved
    static func buildEnvironment(
        settings: AppSettings,
        authService: AuthorizationService
    ) throws -> [String: String] {
        var env: [String: String] = [:]

        // Add custom environment variables from settings
        for (key, value) in settings.environmentVariables {
            env[key] = value
        }

        // Resolve and set CARGO_HOME if authorized
        if let cargoHomeAuth = settings.authorizedDirectory(for: .cargoHome) {
            do {
                let resource = try authService.resolveAuthorization(
                    for: .cargoHome,
                    settings: settings
                )
                defer { resource.stopAccessing() }
                env["CARGO_HOME"] = resource.url.path
            } catch {
                // Non-fatal: continue without CARGO_HOME
            }
        }

        // Resolve and set RUSTUP_HOME if authorized
        if let rustupHomeAuth = settings.authorizedDirectory(for: .rustupHome) {
            do {
                let resource = try authService.resolveAuthorization(
                    for: .rustupHome,
                    settings: settings
                )
                defer { resource.stopAccessing() }
                env["RUSTUP_HOME"] = resource.url.path
            } catch {
                // Non-fatal: continue without RUSTUP_HOME
            }
        }

        return env
    }
}
