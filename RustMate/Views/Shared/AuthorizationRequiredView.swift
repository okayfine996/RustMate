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
        VStack(spacing: GlassTokens.Spacing.xl) {
            // Icon
            Image(systemName: "lock.fill")
                .font(.system(size: 56))
                .foregroundColor(GlassTokens.Colors.warning)

            // Title and Message
            VStack(spacing: GlassTokens.Spacing.sm) {
                Text(title)
                    .font(.system(size: GlassTokens.Typography.titleSize, weight: GlassTokens.Typography.titleWeight))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text(message)
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Missing Purposes List
            if !missingPurposes.isEmpty {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                    Text("Required Authorizations:")
                        .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    ForEach(missingPurposes, id: \.self) { purpose in
                        HStack(spacing: GlassTokens.Spacing.md) {
                            Image(systemName: "folder.fill")
                                .foregroundColor(GlassTokens.Colors.warning)
                                .font(.system(size: 20))

                            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                                Text(purpose.displayText)
                                    .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                                Text(purpose.description)
                                    .font(.system(size: GlassTokens.Typography.captionSize))
                                    .foregroundColor(GlassTokens.Colors.textSecondary)
                            }
                        }
                        .padding(GlassTokens.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(GlassTokens.Colors.warningSubtle)
                        .cornerRadius(GlassTokens.Radius.md)
                    }
                }
                .padding(.horizontal)
            }

            // Instructions Card
            GlassCard {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                    Text("What to do:")
                        .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
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
            }

            // Actions
            HStack(spacing: GlassTokens.Spacing.md) {
                Button(action: onOpenSettings) {
                    Label("Open Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity)
                }
                .secondaryGlassButtonStyle()

                Button(action: onAuthorize) {
                    Label("Authorize Now", systemImage: "lock.open")
                        .frame(maxWidth: .infinity)
                }
                .primaryGlassButtonStyle()
            }
        }
        .padding(GlassTokens.Spacing.xxl)
        .frame(maxWidth: 500)
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: GlassTokens.Spacing.sm) {
            Text(number)
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(GlassTokens.Colors.warning))

            Text(text)
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
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
