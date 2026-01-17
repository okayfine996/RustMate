//
//  PermissionsSection.swift
//  RustMate
//
//  Directory permissions section for Settings
//

import SwiftUI

struct PermissionsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
            // Information Box
            infoBox

            // Section Header
            Text("CRITICAL DIRECTORIES")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .tracking(0.5)
                .padding(.top, GlassTokens.Spacing.md)

            VStack(spacing: GlassTokens.Spacing.md) {
                // Rustup Executable Directory
                permissionRow(
                    title: "Rustup Bin Directory",
                    description: "Required to run rustup and cargo executables",
                    path: viewModel.settings.authorizedDirectory(for: .rustupExecutableDir)?.path ?? "~/.cargo/bin",
                    isAuthorized: viewModel.hasRustupExecutableDir,
                    state: viewModel.authorizationStates[.rustupExecutableDir] ?? .missing,
                    purpose: .rustupExecutableDir,
                    authorizeAction: {
                        viewModel.authorizeDirectory(purpose: .rustupExecutableDir)
                    },
                    removeAction: {
                        viewModel.removeBookmark(purpose: .rustupExecutableDir)
                    }
                )

                // Cargo Home
                permissionRow(
                    title: "Cargo Home",
                    description: "Required for Cargo configuration and cache",
                    path: viewModel.settings.authorizedDirectory(for: .cargoHome)?.path ?? "~/.cargo",
                    isAuthorized: viewModel.hasCargoHome,
                    state: viewModel.authorizationStates[.cargoHome] ?? .missing,
                    purpose: .cargoHome,
                    authorizeAction: {
                        viewModel.authorizeDirectory(purpose: .cargoHome)
                    },
                    removeAction: {
                        viewModel.removeBookmark(purpose: .cargoHome)
                    }
                )

                // Rustup Home
                permissionRow(
                    title: "Rustup Home",
                    description: "Required to access installed toolchains",
                    path: viewModel.settings.authorizedDirectory(for: .rustupHome)?.path ?? "~/.rustup",
                    isAuthorized: viewModel.hasRustupHome,
                    state: viewModel.authorizationStates[.rustupHome] ?? .missing,
                    purpose: .rustupHome,
                    authorizeAction: {
                        viewModel.authorizeDirectory(purpose: .rustupHome)
                    },
                    removeAction: {
                        viewModel.removeBookmark(purpose: .rustupHome)
                    }
                )
            }
        }
    }

    // MARK: - Info Box

    @ViewBuilder
    private var infoBox: some View {
        HStack(alignment: .top, spacing: GlassTokens.Spacing.md) {
            // Info Icon
            ZStack {
                Circle()
                    .fill(GlassTokens.Colors.accent)
                    .frame(width: 32, height: 32)

                Text("i")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Info Content
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text("Why are these permissions required?")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text("This application needs read/write access to your local Rust toolchain directories for toolchain configuration and management. These permissions are required for the GUI to execute rustup commands safely on your behalf.")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
        }
        .padding(GlassTokens.Spacing.lg)
        .background(GlassTokens.Colors.backgroundSecondary)
        .cornerRadius(GlassTokens.Radius.lg)
    }

    // MARK: - Permission Row

    @ViewBuilder
    private func permissionRow(
        title: String,
        description: String,
        path: String,
        isAuthorized: Bool,
        state: SettingsViewModel.AuthorizationState,
        purpose: AuthorizedDirectory.DirectoryPurpose,
        authorizeAction: @escaping () -> Void,
        removeAction: @escaping () -> Void
    ) -> some View {
        GlassCard {
            HStack(spacing: GlassTokens.Spacing.md) {
                // Icon
                Image(systemName: "folder.fill.badge.gearshape")
                    .font(.system(size: 20))
                    .foregroundColor(GlassTokens.Colors.accent)

                // Title, Status, and Path
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                    // Title and Status Badge
                    HStack(spacing: GlassTokens.Spacing.sm) {
                        Text(title)
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                            .foregroundColor(GlassTokens.Colors.textPrimary)

                        if isAuthorized && state == .authorized {
                            HStack(spacing: GlassTokens.Spacing.xs) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.green)
                                Text("Authorized")
                                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, GlassTokens.Spacing.sm)
                            .padding(.vertical, GlassTokens.Spacing.xs)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(GlassTokens.Radius.pill)
                        }
                    }

                    // Path in gray rounded rectangle
                    Text(path)
                        .font(.system(size: GlassTokens.Typography.captionSize, design: .monospaced))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                        .padding(GlassTokens.Spacing.sm)
                        .background(GlassTokens.Colors.backgroundSecondary)
                        .cornerRadius(GlassTokens.Radius.md)
                }

                Spacer()

                // Change Path button
                Button("Change Path...") {
                    authorizeAction()
                }
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.accent)
                .buttonStyle(.plain)
            }
            .padding(GlassTokens.Spacing.md)
        }
    }
}
