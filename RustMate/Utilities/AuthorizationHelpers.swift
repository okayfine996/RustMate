//
//  AuthorizationHelpers.swift
//  RustMate
//
//  Shared authorization error handling utilities
//  Extracts common authorization logic used across views
//

import Foundation

/// Shared authorization error handling utilities
enum AuthorizationHelpers {

    // MARK: - Error Type Detection

    /// Check if an error is an authorization-related error
    /// - Parameter error: Error to check
    /// - Returns: True if the error requires authorization
    static func isAuthorizationError(_ error: Error?) -> Bool {
        guard let error = error else { return false }

        if error is AuthorizationError {
            return true
        }

        if let execError = error as? RustupExecutionError {
            switch execError {
            case .missingAuthorization:
                return true
            default:
                return false
            }
        }

        return false
    }

    // MARK: - Purpose Extraction

    /// Extract missing authorization purposes from an error
    /// - Parameter error: Error to analyze
    /// - Returns: Array of missing directory purposes
    static func extractMissingPurposes(from error: Error?) -> [AuthorizedDirectory.DirectoryPurpose] {
        guard let error = error else { return [] }

        if let authError = error as? AuthorizationError {
            switch authError {
            case .missingScope(let purpose):
                return [purpose]
            case .staleBookmark(_, let purpose),
                 .accessDenied(_, let purpose),
                 .invalidSelection(_, let purpose, _):
                return [purpose]
            }
        } else if let execError = error as? RustupExecutionError {
            switch execError {
            case .missingAuthorization(let purpose, _, _):
                return [purpose]
            default:
                return []
            }
        }

        return []
    }

    // MARK: - Authorization Request

    /// Handle an authorization error by requesting necessary permissions
    /// - Parameter error: Authorization error to handle
    /// - Returns: True if authorization was requested
    @discardableResult
    static func handleAuthorizationError(_ error: Error?) -> Bool {
        guard let error = error else { return false }

        let purposes = extractMissingPurposes(from: error)
        guard !purposes.isEmpty else { return false }

        // Request authorization via coordinator
        AuthorizationCoordinator.requestAuthorization(for: purposes)
        return true
    }

    /// Open the settings window to manage authorizations
    static func openSettings() {
        EventBus.shared.publishWithLegacy(.openSettings, notification: Constants.Notifications.openSettings)
    }
}
