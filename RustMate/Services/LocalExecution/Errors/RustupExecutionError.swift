//
//  RustupExecutionError.swift
//  RustMate
//
//  Structured errors for rustup execution failures
//

import Foundation

/// Errors that occur during rustup command execution
enum RustupExecutionError: Error, LocalizedError {
    case missingAuthorization(
        purpose: AuthorizedDirectory.DirectoryPurpose,
        message: String,
        suggestedFix: String
    )
    case rustupNotFound(message: String, suggestedFix: String)
    case executionFailed(
        command: String,
        exitCode: Int32,
        stderr: String,
        suggestedFix: String
    )
    case parseFailed(
        command: String,
        output: String,
        reason: String
    )
    case unknown(message: String, stderr: String?)

    var errorDescription: String? {
        return userFacingMessage
    }

    /// User-understandable error message
    var userFacingMessage: String {
        switch self {
        case .missingAuthorization(_, let message, _):
            return message

        case .rustupNotFound(let message, _):
            return message

        case .executionFailed(let command, let exitCode, let stderr, _):
            // Extract first few lines of stderr for context
            let stderrPreview = stderr.split(separator: "\n")
                .prefix(5)
                .joined(separator: "\n")

            return """
            Command '\(command)' failed with exit code \(exitCode).

            Error output:
            \(stderrPreview)
            """

        case .parseFailed(let command, let output, let reason):
            let outputPreview = output.split(separator: "\n")
                .prefix(5)
                .joined(separator: "\n")

            return """
            Failed to parse output from '\(command)'.

            Reason: \(reason)

            Output preview:
            \(outputPreview)
            """

        case .unknown(let message, let stderr):
            if let stderr = stderr, !stderr.isEmpty {
                let stderrPreview = stderr.split(separator: "\n")
                    .prefix(3)
                    .joined(separator: "\n")

                return """
                \(message)

                Error details:
                \(stderrPreview)
                """
            }
            return message
        }
    }

    /// Suggested fix action for the user
    var suggestedFix: String {
        switch self {
        case .missingAuthorization(_, _, let fix):
            return fix

        case .rustupNotFound(_, let fix):
            return fix

        case .executionFailed(_, _, _, let fix):
            return fix

        case .parseFailed:
            return """
            This may indicate that rustup's output format has changed.

            Please try:
            1. Update rustup: run 'rustup self update' in Terminal
            2. If the problem persists, file a bug report with the output shown above
            """

        case .unknown:
            return """
            Please try:
            1. Check that rustup is properly installed
            2. Verify authorizations in Settings > Permissions
            3. Try running the command manually in Terminal to see if it works
            4. If the problem persists, file a bug report
            """
        }
    }

    /// Returns the category of this error for UI routing
    var category: RustupExecutionErrorCategory {
        switch self {
        case .missingAuthorization:
            return .missingAuthorization
        case .rustupNotFound:
            return .rustupNotFound
        case .executionFailed:
            return .executionFailed
        case .parseFailed:
            return .parseFailed
        case .unknown:
            return .unknown
        }
    }

    /// Returns a shortened error snippet for task records (max 200 chars)
    var briefErrorSummary: String {
        let message = userFacingMessage
        if message.count <= 200 {
            return message
        }

        let truncated = message.prefix(197)
        return String(truncated) + "..."
    }
}

/// Categories of rustup execution errors for UI routing
enum RustupExecutionErrorCategory {
    case missingAuthorization  // Show authorization prompt
    case rustupNotFound        // Show installation instructions
    case executionFailed       // Show error details + retry
    case parseFailed           // Show technical details + bug report link
    case unknown               // Show generic troubleshooting
}
