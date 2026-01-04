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
        VStack(spacing: GlassTokens.Spacing.lg) {
            // Icon and Title
            VStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(GlassTokens.Colors.warning)

                Text(title)
                    .font(.system(size: GlassTokens.Typography.titleSize, weight: GlassTokens.Typography.titleWeight))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text(message)
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            // Missing Purposes - Compact List
            if !missingPurposes.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                        Text("Required Authorizations:")
                            .font(.system(size: GlassTokens.Typography.calloutSize, weight: .semibold))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        ForEach(missingPurposes, id: \.self) { purpose in
                            HStack(spacing: GlassTokens.Spacing.sm) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(GlassTokens.Colors.warning)
                                    .font(.system(size: 16))

                                Text(purpose.displayText)
                                    .font(.system(size: GlassTokens.Typography.bodySize))
                                    .foregroundColor(GlassTokens.Colors.textPrimary)
                            }
                        }
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
        .padding(GlassTokens.Spacing.xl)
        .frame(maxWidth: 450)
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
