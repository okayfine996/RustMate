//
//  AppError.swift
//  RustMate
//
//  Unified error type for the application
//  Provides consistent error handling and user-facing messages
//

import Foundation

/// Application-level error that unifies all error types
enum AppError: LocalizedError {

    // MARK: - Authorization Errors

    case authorizationMissing(purpose: AuthorizedDirectory.DirectoryPurpose)
    case authorizationStale(path: String, purpose: AuthorizedDirectory.DirectoryPurpose)
    case authorizationDenied(path: String, purpose: AuthorizedDirectory.DirectoryPurpose)
    case authorizationInvalid(path: String, purpose: AuthorizedDirectory.DirectoryPurpose, reason: String)

    // MARK: - Execution Errors

    case rustupNotFound
    case commandExecutionFailed(command: String, exitCode: Int32, stderr: String)
    case parseFailed(command: String, output: String, reason: String)

    // MARK: - Project Errors

    case projectNotFound(path: String)
    case projectAlreadyAdded(path: String)
    case invalidProjectDirectory(path: String, reason: String)

    // MARK: - Network Errors

    case networkUnavailable
    case updateCheckFailed(reason: String)

    // MARK: - Operation Errors

    case operationFailed(operation: String, message: String)
    case invalidInput(field: String, reason: String)

    // MARK: - System Errors

    case fileSystemError(underlying: Error)
    case unknownError(underlying: Error)

    // MARK: - LocalizedError Protocol

    var errorDescription: String? {
        switch self {
        case .authorizationMissing(let purpose):
            return "Missing authorization for \(purpose.displayText)"

        case .authorizationStale(let path, _):
            return "Authorization for \(path) has expired"

        case .authorizationDenied(let path, _):
            return "Access to \(path) was denied"

        case .authorizationInvalid(let path, let purpose, let reason):
            return "Invalid directory selection for \(purpose.displayText): \(reason)"

        case .rustupNotFound:
            return "rustup is not installed or not accessible"

        case .commandExecutionFailed(let command, let exitCode, _):
            return "Command '\(command)' failed with exit code \(exitCode)"

        case .parseFailed(let command, _, let reason):
            return "Failed to parse output from '\(command)': \(reason)"

        case .projectNotFound(let path):
            return "Project not found at \(path)"

        case .projectAlreadyAdded:
            return "This project is already in your list"

        case .invalidProjectDirectory(let path, let reason):
            return "Invalid project directory at \(path): \(reason)"

        case .operationFailed(let operation, let message):
            return "Operation '\(operation)' failed: \(message)"

        case .invalidInput(let field, let reason):
            return "Invalid \(field): \(reason)"

        case .networkUnavailable:
            return "Network connection is not available"

        case .updateCheckFailed(let reason):
            return "Failed to check for updates: \(reason)"

        case .fileSystemError(let error):
            return "File system error: \(error.localizedDescription)"

        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .authorizationMissing(let purpose):
            if let defaultPath = purpose.defaultPath {
                return "Open Settings > Permissions and authorize \(defaultPath)."
            }
            return "Open Settings > Permissions to authorize the required directory."

        case .authorizationStale(let path, let purpose):
            if let defaultPath = purpose.defaultPath {
                return "Re-authorize access to \(defaultPath) in Settings > Permissions."
            }
            return "Re-authorize access to \"\(path)\" in Settings > Permissions."

        case .authorizationDenied(let path, _):
            return """
            Try these steps:
            1. Open Settings > Permissions
            2. Remove the existing authorization for "\(path)"
            3. Re-authorize the directory
            4. If the problem persists, check System Settings > Privacy & Security
            """

        case .authorizationInvalid(_, let purpose, _):
            if let defaultPath = purpose.defaultPath {
                return "Please select \(defaultPath) when prompted."
            }
            return "Please select the correct directory for \(purpose.displayText)."

        case .rustupNotFound:
            return "Install rustup from https://rustup.rs or add it to your PATH."

        case .commandExecutionFailed(_, _, let stderr):
            return TaskResult.suggestFix(for: stderr)

        case .parseFailed:
            return """
            This may indicate that rustup's output format has changed.

            Please try:
            1. Update rustup: run 'rustup self update' in Terminal
            2. If the problem persists, file a bug report
            """

        case .projectNotFound:
            return "The project directory may have been moved or deleted."

        case .projectAlreadyAdded:
            return nil

        case .invalidProjectDirectory:
            return "Select a valid Rust project directory containing Cargo.toml."

        case .operationFailed:
            return "Please try again or check the task details for more information."

        case .invalidInput:
            return "Please provide valid input and try again."

        case .networkUnavailable:
            return "Check your internet connection and try again."

        case .updateCheckFailed:
            return "Check your internet connection or try again later."

        case .fileSystemError, .unknownError:
            return "Try restarting the app or contact support."
        }
    }

    // MARK: - Error Category for UI Routing

    /// Returns the error category for UI routing decisions
    var category: ErrorPresentation.ErrorCategory {
        switch self {
        case .authorizationMissing:
            return .requiresAuthorization

        case .authorizationStale, .authorizationDenied, .authorizationInvalid:
            return .authorizationProblem

        case .rustupNotFound:
            return .setupProblem

        case .commandExecutionFailed:
            return .executionProblem

        case .parseFailed:
            return .technicalProblem

        case .networkUnavailable, .updateCheckFailed:
            return .technicalProblem

        case .projectNotFound, .projectAlreadyAdded, .invalidProjectDirectory:
            return .executionProblem

        case .operationFailed:
            return .executionProblem

        case .invalidInput:
            return .executionProblem

        case .fileSystemError, .unknownError:
            return .unknown
        }
    }
}

// MARK: - Conversion from Existing Error Types

extension AppError {

    /// Convert from RustupExecutionError
    init(_ error: RustupExecutionError) {
        switch error {
        case .missingAuthorization(let purpose, _, _):
            self = .authorizationMissing(purpose: purpose)

        case .rustupNotFound:
            self = .rustupNotFound

        case .executionFailed(let command, let exitCode, let stderr, _):
            self = .commandExecutionFailed(command: command, exitCode: exitCode, stderr: stderr)

        case .parseFailed(let command, let output, let reason):
            self = .parseFailed(command: command, output: output, reason: reason)

        case .unknown(let message, let stderr):
            let nsError = NSError(domain: "RustupExecution", code: -1, userInfo: [
                NSLocalizedDescriptionKey: message,
                NSLocalizedRecoverySuggestionErrorKey: stderr ?? ""
            ])
            self = .unknownError(underlying: nsError)
        }
    }

    /// Convert from AuthorizationError
    init(_ error: AuthorizationError) {
        switch error {
        case .missingScope(let purpose):
            self = .authorizationMissing(purpose: purpose)

        case .staleBookmark(let path, let purpose):
            self = .authorizationStale(path: path, purpose: purpose)

        case .accessDenied(let path, let purpose):
            self = .authorizationDenied(path: path, purpose: purpose)

        case .invalidSelection(let path, let purpose, let reason):
            self = .authorizationInvalid(path: path, purpose: purpose, reason: reason)
        }
    }
}
