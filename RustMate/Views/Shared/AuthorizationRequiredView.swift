//
//  AuthorizationRequiredView.swift
//  RustMate
//
//  Specialized view for authorization errors (T043)
//

import SwiftUI

/// View displayed when authorization is missing or stale
struct AuthorizationRequiredView: View {
    let title: String
    let message: String
    let missingPurposes: [AuthorizedDirectory.DirectoryPurpose]
    let onAuthorize: () -> Void
    let onOpenSettings: () -> Void

    init(
        title: String = "Authorization Required",
        message: String,
        missingPurposes: [AuthorizedDirectory.DirectoryPurpose] = [],
        onAuthorize: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.missingPurposes = missingPurposes
        self.onAuthorize = onAuthorize
        self.onOpenSettings = onOpenSettings
    }

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "lock.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            // Title and Message
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Missing Purposes List
            if !missingPurposes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Required Authorizations:")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    ForEach(missingPurposes, id: \.self) { purpose in
                        HStack(spacing: 12) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 20))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(purpose.displayText)
                                    .font(.subheadline.bold())
                                Text(purpose.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }

            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("What to do:")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 6) {
                    instructionRow(
                        number: "1",
                        text: "Click 'Authorize Now' to grant required permissions"
                    )
                    instructionRow(
                        number: "2",
                        text: "Select the correct directory when prompted"
                    )
                    instructionRow(
                        number: "3",
                        text: "RustMate will then be able to access your Rust toolchains"
                    )
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)

            // Actions
            HStack(spacing: 12) {
                Button(action: onOpenSettings) {
                    Label("Open Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(action: onAuthorize) {
                    Label("Authorize Now", systemImage: "lock.open")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(32)
        .frame(maxWidth: 500)
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.orange))

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Extensions

extension AuthorizedDirectory.DirectoryPurpose {
    /// User-facing description of what this authorization is for
    var description: String {
        switch self {
        case .rustupAccess:
            return "Legacy rustup access (will be migrated)"
        case .rustupExecutableDir:
            return "Access to rustup and cargo executables (~/.cargo/bin)"
        case .cargoHome:
            return "Access to Cargo configuration and cache (~/.cargo)"
        case .rustupHome:
            return "Access to installed toolchains (~/.rustup)"
        case .projectAccess:
            return "Access to your Rust project directory"
        case .customToolchainPath:
            return "Access to custom toolchain location"
        }
    }
}

// MARK: - Previews

#Preview("Missing Authorization") {
    AuthorizationRequiredView(
        message: "RustMate needs permission to access your Rust toolchains. Please authorize the required directories to continue.",
        missingPurposes: [.rustupExecutableDir, .cargoHome, .rustupHome],
        onAuthorize: { print("Authorize tapped") },
        onOpenSettings: { print("Settings tapped") }
    )
}

#Preview("Stale Bookmark") {
    AuthorizationRequiredView(
        title: "Authorization Expired",
        message: "Your previous authorization has expired or the directory has moved. Please re-authorize to continue.",
        missingPurposes: [.cargoHome],
        onAuthorize: { print("Re-authorize tapped") },
        onOpenSettings: { print("Settings tapped") }
    )
}
