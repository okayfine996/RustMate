//
//  MenuBarModels.swift
//  RustMate
//
//  Shared models for menu bar functionality
//

import Foundation

/// Represents a toolchain option for menu display
struct ToolchainOption: Identifiable, Hashable {
    let id: String
    let displayName: String
    let isDefault: Bool
    let isSelectable: Bool

    init(id: String, displayName: String, isDefault: Bool, isSelectable: Bool = true) {
        self.id = id
        self.displayName = displayName
        self.isDefault = isDefault
        self.isSelectable = isSelectable
    }
}

/// Represents the result of a menu bar action
struct MenuBarActionResult {
    let actionType: ActionType
    let status: ResultStatus
    let userMessage: String?
    let errorDetail: ErrorDetail?

    enum ActionType {
        case refresh
        case switchDefault
        case openMainWindow
    }

    enum ResultStatus {
        case success
        case failure
    }

    struct ErrorDetail {
        let category: String
        let title: String
        let message: String
        let suggestedFix: String?
    }

    /// Create a success result
    static func success(actionType: ActionType, message: String? = nil) -> MenuBarActionResult {
        MenuBarActionResult(
            actionType: actionType,
            status: .success,
            userMessage: message,
            errorDetail: nil
        )
    }

    /// Create a failure result
    static func failure(
        actionType: ActionType,
        category: String,
        title: String,
        message: String,
        suggestedFix: String? = nil
    ) -> MenuBarActionResult {
        MenuBarActionResult(
            actionType: actionType,
            status: .failure,
            userMessage: nil,
            errorDetail: ErrorDetail(
                category: category,
                title: title,
                message: message,
                suggestedFix: suggestedFix
            )
        )
    }
}
