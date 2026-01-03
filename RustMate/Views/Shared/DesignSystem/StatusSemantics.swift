//
//  StatusSemantics.swift
//  RustMate
//
//  Created by Speckit on 2026-01-02.
//  Feature: 004-glass-ui-refresh
//

import SwiftUI

/// Maps domain status to visual presentation
/// Provides consistent status semantics across toolchains, components, targets, and tasks
enum StatusSemantics {

    // MARK: - Toolchain Status Mapping

    static func toolchainBadge(isDefault: Bool, hasUpdate: Bool) -> (status: StatusBadgeView.BadgeStatus, text: String)? {
        if isDefault {
            return (.default, "Default")
        } else if hasUpdate {
            return (.update, "Update")
        }
        return nil // Installed but not default, no badge needed
    }

    static func toolchainIcon(isDefault: Bool) -> String {
        isDefault ? "star.fill" : "hammer"
    }

    static func toolchainColor(isDefault: Bool, hasUpdate: Bool) -> Color {
        if isDefault {
            return GlassTokens.Colors.accent
        } else if hasUpdate {
            return GlassTokens.Colors.warning
        }
        return GlassTokens.Colors.success
    }

    // MARK: - Component Status Mapping

    static func componentBadge(isInstalled: Bool) -> (status: StatusBadgeView.BadgeStatus, text: String) {
        isInstalled ? (.installed, "Installed") : (.info, "Available")
    }

    static func componentIcon(isInstalled: Bool) -> String {
        isInstalled ? "checkmark.circle.fill" : "circle"
    }

    static func componentColor(isInstalled: Bool) -> Color {
        isInstalled ? GlassTokens.Colors.success : GlassTokens.Colors.textSecondary
    }

    // MARK: - Target Status Mapping

    static func targetBadge(isInstalled: Bool) -> (status: StatusBadgeView.BadgeStatus, text: String) {
        isInstalled ? (.installed, "Installed") : (.info, "Available")
    }

    static func targetIcon(isInstalled: Bool) -> String {
        isInstalled ? "checkmark.circle.fill" : "circle"
    }

    static func targetColor(isInstalled: Bool) -> Color {
        isInstalled ? GlassTokens.Colors.success : GlassTokens.Colors.textSecondary
    }

    // MARK: - Task Status Mapping

    static func taskBadge(status: TaskRecord.TaskStatus) -> (status: StatusBadgeView.BadgeStatus, text: String) {
        switch status {
        case .running:
            return (.running, "Running")
        case .success:
            return (.success, "Success")
        case .failed:
            return (.failed, "Failed")
        case .cancelled:
            return (.info, "Cancelled")
        }
    }

    static func taskIcon(status: TaskRecord.TaskStatus) -> String {
        switch status {
        case .running:
            return "arrow.triangle.2.circlepath"
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .cancelled:
            return "slash.circle"
        }
    }

    static func taskColor(status: TaskRecord.TaskStatus) -> Color {
        switch status {
        case .running:
            return GlassTokens.Colors.info
        case .success:
            return GlassTokens.Colors.success
        case .failed:
            return GlassTokens.Colors.error
        case .cancelled:
            return GlassTokens.Colors.textTertiary
        }
    }

    // MARK: - Project Override Status

    static func projectOverrideBadge(hasOverride: Bool) -> (status: StatusBadgeView.BadgeStatus, text: String)? {
        hasOverride ? (.info, "Override") : nil
    }

    static func projectOverrideIcon(hasOverride: Bool) -> String {
        hasOverride ? "folder.badge.gearshape" : "folder"
    }
}
