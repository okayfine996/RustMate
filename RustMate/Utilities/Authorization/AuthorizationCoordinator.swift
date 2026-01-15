//
//  AuthorizationCoordinator.swift
//  RustMate
//
//  Coordinates authorization requests across the app (T042)
//

import Foundation

/// Coordinates authorization requests between UI and authorization flow
struct AuthorizationCoordinator {

    /// Notification name for requesting authorization
    static let authorizationRequestedNotification = Constants.Notifications.authorizationRequested

    /// Key for AuthorizationScope in notification userInfo
    static let scopeKey = "scope"

    /// Key for missing purposes array in notification userInfo
    static let missingPurposesKey = "missingPurposes"

    /// Post a notification requesting authorization for a specific scope
    /// - Parameters:
    ///   - scope: The authorization scope required
    ///   - missingPurposes: Array of specific missing purposes that need authorization
    static func requestAuthorization(
        for scope: AuthorizationScope,
        missingPurposes: [AuthorizedDirectory.DirectoryPurpose]
    ) {
        let userInfo: [String: Any] = [
            scopeKey: scope,
            missingPurposesKey: missingPurposes
        ]

        NotificationCenter.default.post(
            name: authorizationRequestedNotification,
            object: nil,
            userInfo: userInfo
        )

        print("📢 AuthorizationCoordinator: Requesting authorization for scope: \(scope), missing purposes: \(missingPurposes)")
    }

    /// Post a notification requesting authorization for specific purposes
    /// - Parameter purposes: Array of purposes that need authorization
    static func requestAuthorization(
        for purposes: [AuthorizedDirectory.DirectoryPurpose]
    ) {
        let userInfo: [String: Any] = [
            missingPurposesKey: purposes
        ]

        NotificationCenter.default.post(
            name: authorizationRequestedNotification,
            object: nil,
            userInfo: userInfo
        )

        print("📢 AuthorizationCoordinator: Requesting authorization for purposes: \(purposes)")
    }
}
