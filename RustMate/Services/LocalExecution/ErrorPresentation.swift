//
//  ErrorPresentation.swift
//  RustMate
//
//  Translates authorization and execution errors into user-facing messages
//

import Foundation

/// Handles presentation logic for authorization and execution errors
struct ErrorPresentation {

    /// Converts any error from local execution into a user-presentable format
    /// Returns (title, message, suggestedFix)
    static func present(error: Error) -> (title: String, message: String, suggestedFix: String?) {
        if let authError = error as? AuthorizationError {
            return presentAuthorizationError(authError)
        } else if let execError = error as? RustupExecutionError {
            return presentExecutionError(execError)
        } else {
            return presentUnknownError(error)
        }
    }

    // MARK: - Authorization Errors

    private static func presentAuthorizationError(_ error: AuthorizationError) -> (String, String, String?) {
        let title: String
        let message: String
        let fix: String?

        switch error.category {
        case .missing:
            title = "Authorization Required"
            message = error.userFacingMessage
            fix = error.suggestedFix

        case .stale:
            title = "Authorization Expired"
            message = error.userFacingMessage
            fix = error.suggestedFix

        case .denied:
            title = "Access Denied"
            message = error.userFacingMessage
            fix = error.suggestedFix

        case .invalid:
            title = "Invalid Selection"
            message = error.userFacingMessage
            fix = error.suggestedFix
        }

        return (title, message, fix)
    }

    // MARK: - Execution Errors

    private static func presentExecutionError(_ error: RustupExecutionError) -> (String, String, String?) {
        let title: String
        let message: String
        let fix: String?

        switch error.category {
        case .missingAuthorization:
            title = "Authorization Required"
            message = error.userFacingMessage
            fix = error.suggestedFix

        case .rustupNotFound:
            title = "Rustup Not Found"
            message = error.userFacingMessage
            fix = error.suggestedFix

        case .executionFailed:
            title = "Command Failed"
            message = error.userFacingMessage
            fix = error.suggestedFix

        case .parseFailed:
            title = "Parse Error"
            message = error.userFacingMessage
            fix = error.suggestedFix

        case .unknown:
            title = "Error"
            message = error.userFacingMessage
            fix = error.suggestedFix
        }

        return (title, message, fix)
    }

    // MARK: - Unknown Errors

    private static func presentUnknownError(_ error: Error) -> (String, String, String?) {
        let title = "Unexpected Error"
        let message = """
        An unexpected error occurred:

        \(error.localizedDescription)
        """
        let fix = """
        Please try:
        1. Check Settings > Permissions to ensure all required authorizations are granted
        2. Verify that rustup is installed and working
        3. If the problem persists, file a bug report
        """

        return (title, message, fix)
    }

    // MARK: - User-Facing Error Category

    /// Returns a simple category name for UI routing
    static func category(for error: Error) -> ErrorCategory {
        if let authError = error as? AuthorizationError {
            switch authError.category {
            case .missing, .stale:
                return .requiresAuthorization
            case .denied, .invalid:
                return .authorizationProblem
            }
        } else if let execError = error as? RustupExecutionError {
            switch execError.category {
            case .missingAuthorization:
                return .requiresAuthorization
            case .rustupNotFound:
                return .setupProblem
            case .executionFailed:
                return .executionProblem
            case .parseFailed:
                return .technicalProblem
            case .unknown:
                return .unknown
            }
        }

        return .unknown
    }

    enum ErrorCategory {
        case requiresAuthorization  // Show authorization prompt
        case authorizationProblem   // Show settings link
        case setupProblem           // Show setup instructions
        case executionProblem       // Show retry button
        case technicalProblem       // Show bug report link
        case unknown                // Show generic help
    }
}
