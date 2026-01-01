//
//  ErrorView.swift
//  RustMate
//
//  Shared error display component
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
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if !hints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions:")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    ForEach(hints, id: \.self) { hint in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(hint)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(24)
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
        message: "Failed to connect to XPC service",
        hints: [
            "Check that RustMateXPC.xpc is properly installed",
            "Try restarting the application"
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
