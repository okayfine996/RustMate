//
//  LoadingView.swift
//  RustMate
//
//  Shared loading indicator component
//

import SwiftUI

struct LoadingView: View {
    let message: String
    let showProgress: Bool
    let progress: Double?

    init(
        message: String = "Loading...",
        showProgress: Bool = false,
        progress: Double? = nil
    ) {
        self.message = message
        self.showProgress = showProgress
        self.progress = progress
    }

    var body: some View {
        VStack(spacing: 16) {
            if showProgress, let progress = progress {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(width: 200)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
            }

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Convenience Initializers

extension LoadingView {
    /// Create LoadingView for task operation
    init(operation: String, toolchainName: String? = nil) {
        let operationText = Self.formatOperation(operation)
        let fullMessage: String

        if let toolchainName = toolchainName {
            fullMessage = "\(operationText) \(toolchainName)..."
        } else {
            fullMessage = "\(operationText)..."
        }

        self.init(message: fullMessage, showProgress: false, progress: nil)
    }

    private static func formatOperation(_ operation: String) -> String {
        switch operation {
        case "install": return "Installing"
        case "uninstall": return "Uninstalling"
        case "update": return "Updating"
        case "updateAll": return "Updating all toolchains"
        case "setDefault": return "Setting default"
        case "addComponent": return "Adding component"
        case "removeComponent": return "Removing component"
        case "addTarget": return "Adding target"
        case "removeTarget": return "Removing target"
        case "setProjectOverride": return "Setting project override"
        case "clearProjectOverride": return "Clearing project override"
        default: return operation.capitalized
        }
    }
}

// MARK: - Previews

#Preview("Basic Loading") {
    LoadingView()
}

#Preview("With Message") {
    LoadingView(message: "Fetching toolchains...")
}

#Preview("With Progress") {
    LoadingView(
        message: "Downloading components...",
        showProgress: true,
        progress: 0.65
    )
}

#Preview("Installing Toolchain") {
    LoadingView(operation: "install", toolchainName: "stable-aarch64-apple-darwin")
}

#Preview("Updating All") {
    LoadingView(operation: "updateAll")
}
