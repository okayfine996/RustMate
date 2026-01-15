//
//  ErrorView.swift
//  RustMate
//
//  Shared error display component
//  Updated: 2026-01-02 - Feature 004-glass-ui-refresh
//

import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let hints: [String]
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String = "Error",
        message: String,
        hints: [String] = [],
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.hints = hints
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: GlassTokens.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(GlassTokens.Colors.warning)

            VStack(spacing: GlassTokens.Spacing.sm) {
                Text(title)
                    .font(.system(size: GlassTokens.Typography.titleSize, weight: GlassTokens.Typography.titleWeight))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text(message)
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if !hints.isEmpty {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                    Text("Suggestions:")
                        .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    ForEach(hints, id: \.self) { hint in
                        HStack(alignment: .top, spacing: GlassTokens.Spacing.sm) {
                            Text("•")
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                            Text(hint)
                                .font(.system(size: GlassTokens.Typography.calloutSize))
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                        }
                    }
                }
                .padding(GlassTokens.Spacing.md)
                .background(GlassTokens.Colors.warningSubtle)
                .cornerRadius(GlassTokens.Radius.md)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .frame(maxWidth: .infinity)
                }
                .primaryGlassButtonStyle()
            }
        }
        .padding(GlassTokens.Spacing.xl)
        .frame(maxWidth: 400)
    }
}

// MARK: - Convenience Initializers

extension ErrorView {
    /// Create ErrorView from TaskResult
    init(taskResult: TaskResult, retryAction: (() -> Void)? = nil) {
        let errorMsg = taskResult.errorMessage ?? taskResult.stderrSnippet ?? "Unknown error occurred"
        let suggestions = taskResult.suggestFix()

        self.init(
            title: "Operation Failed",
            message: errorMsg,
            hints: suggestions,
            actionTitle: retryAction != nil ? "Retry" : nil,
            action: retryAction
        )
    }

    /// Create ErrorView from ValidationResult
    init(validationResult: ValidationResult, settingsAction: (() -> Void)? = nil) {
        self.init(
            title: "Rustup Not Found",
            message: "Rustup must be installed and accessible to use RustMate.",
            hints: validationResult.hints,
            actionTitle: settingsAction != nil ? "Open Settings" : nil,
            action: settingsAction
        )
    }
}

// MARK: - Previews

#Preview("Basic Error") {
    ErrorView(
        message: "Failed to execute rustup command",
        hints: [
            "Check that rustup is properly installed",
            "Try running 'rustup --version' in Terminal"
        ]
    )
}

#Preview("With Action") {
    ErrorView(
        message: "Network connection failed",
        hints: ["Check your internet connection"],
        actionTitle: "Retry",
        action: { print("Retry tapped") }
    )
}

#Preview("From TaskResult") {
    ErrorView(
        taskResult: TaskResult(
            taskId: UUID(),
            toolchainName: "stable",
            operation: "install",
            status: .failed,
            startTime: Date(),
            endTime: Date(),
            exitCode: 1,
            stdoutSnippet: nil,
            stderrSnippet: "error: could not download file",
            errorMessage: "Network timeout"
        ),
        retryAction: { print("Retry") }
    )
}
