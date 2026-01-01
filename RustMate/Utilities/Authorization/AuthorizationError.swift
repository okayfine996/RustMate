//
//  AuthorizationError.swift
//  RustMate
//
//  Structured authorization errors with user-facing messages
//

import Foundation

/// Errors that occur during authorization validation and resolution
enum AuthorizationError: Error, LocalizedError {
    case missingScope(purpose: AuthorizedDirectory.DirectoryPurpose)
    case staleBookmark(path: String, purpose: AuthorizedDirectory.DirectoryPurpose)
    case accessDenied(path: String, purpose: AuthorizedDirectory.DirectoryPurpose)
    case invalidSelection(path: String, purpose: AuthorizedDirectory.DirectoryPurpose, reason: String)

    var errorDescription: String? {
        return userFacingMessage
    }

    /// User-understandable error message (not raw system error)
    var userFacingMessage: String {
        switch self {
        case .missingScope(let purpose):
            return """
            Missing authorization for \(purpose.displayText).

            To use this feature, you need to authorize access to \(purpose.displayText).
            """

        case .staleBookmark(let path, let purpose):
            return """
            Authorization for "\(path)" has become stale.

            The authorization bookmark for \(purpose.displayText) is no longer valid. \
            This can happen if the directory was moved or macOS security settings changed.
            """

        case .accessDenied(let path, let purpose):
            return """
            Access denied to "\(path)".

            macOS blocked access to \(purpose.displayText). \
            This usually happens when the security-scoped bookmark cannot be activated.
            """

        case .invalidSelection(let path, let purpose, let reason):
            return """
            Invalid directory selection for \(purpose.displayText).

            Path: "\(path)"
            Reason: \(reason)

            Please select the correct directory for \(purpose.displayText).
            """
        }
    }

    /// Suggested fix action for the user
    var suggestedFix: String {
        switch self {
        case .missingScope(let purpose):
            if let defaultPath = purpose.defaultPath {
                return "Open Settings > Permissions and authorize \(defaultPath)."
            }
            return "Open Settings > Permissions to authorize the required directory."

        case .staleBookmark(let path, let purpose):
            if let defaultPath = purpose.defaultPath {
                return "Re-authorize access to \(defaultPath) in Settings > Permissions."
            }
            return "Re-authorize access to \"\(path)\" in Settings > Permissions."

        case .accessDenied(let path, _):
            return """
            Try these steps:
            1. Open Settings > Permissions
            2. Remove the existing authorization for "\(path)"
            3. Re-authorize the directory
            4. If the problem persists, check System Settings > Privacy & Security
            """

        case .invalidSelection(_, let purpose, _):
            if let defaultPath = purpose.defaultPath {
                return "Please select \(defaultPath) when prompted."
            }
            return "Please select the correct directory for \(purpose.displayText)."
        }
    }

    /// Returns the category of this error for UI routing
    var category: AuthorizationErrorCategory {
        switch self {
        case .missingScope:
            return .missing
        case .staleBookmark:
            return .stale
        case .accessDenied:
            return .denied
        case .invalidSelection:
            return .invalid
        }
    }
}

/// Categories of authorization errors for UI routing
enum AuthorizationErrorCategory {
    case missing    // Show authorization prompt
    case stale      // Show re-authorization prompt
    case denied     // Show troubleshooting guide
    case invalid    // Show selection instructions
}
