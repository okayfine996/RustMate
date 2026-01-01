//
//  BookmarkAuthView.swift
//  RustMate
//
//  Dedicated view for managing file access permissions
//

import SwiftUI

struct BookmarkAuthView: View {
    @StateObject private var viewModel: BookmarkAuthViewModel
    @Environment(\.dismiss) private var dismiss

    init(bookmarkService: BookmarkServiceProtocol = BookmarkManager()) {
        _viewModel = StateObject(wrappedValue: BookmarkAuthViewModel(bookmarkService: bookmarkService))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("File Access Permissions")
                    .font(.title.bold())

                Text("Grant RustMate access to necessary directories")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Why we need permissions
                    infoSection

                    // Required permissions
                    requiredSection

                    // Optional permissions
                    optionalSection
                }
                .padding(24)
            }

            Divider()

            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.hasRequiredPermissions)
            }
            .padding(16)
        }
        .frame(width: 550, height: 500)
    }

    // MARK: - Info Section

    @ViewBuilder
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)

                Text("About File Access")
                    .font(.headline)
            }

            Text("RustMate runs in the macOS App Sandbox for security. To manage Rust toolchains and projects, you need to grant access to specific directories.")
                .font(.body)
                .foregroundStyle(.secondary)

            Text("Your privacy is protected: RustMate only accesses directories you explicitly authorize.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Required Section

    @ViewBuilder
    private var requiredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Required Permissions")
                .font(.headline)

            authorizationCard(
                title: "Cargo Bin Directory",
                subtitle: "~/.cargo/bin",
                description: "Access to rustup and cargo executables",
                icon: "terminal.fill",
                isAuthorized: viewModel.hasCargoAccess,
                isRequired: true,
                action: {
                    viewModel.authorizeCargoAccess()
                }
            )
        }
    }

    // MARK: - Optional Section

    @ViewBuilder
    private var optionalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optional Permissions")
                .font(.headline)

            Text("You can add these later in Settings as needed")
                .font(.caption)
                .foregroundStyle(.secondary)

            authorizationCard(
                title: "Project Directories",
                subtitle: "Rust project folders",
                description: "View toolchain overrides and manage project-specific settings",
                icon: "folder.fill",
                isAuthorized: !viewModel.authorizedProjects.isEmpty,
                isRequired: false,
                action: {
                    viewModel.authorizeProjectDirectory()
                }
            )

            // Show authorized projects
            if !viewModel.authorizedProjects.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Authorized Projects:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(viewModel.authorizedProjects) { project in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)

                            Text(project.displayName)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()

                            Button {
                                viewModel.removeProject(path: project.path)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
                .padding(.leading, 12)
            }
        }
    }

    // MARK: - Authorization Card

    @ViewBuilder
    private func authorizationCard(
        title: String,
        subtitle: String,
        description: String,
        icon: String,
        isAuthorized: Bool,
        isRequired: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isAuthorized ? Color.green.opacity(0.2) : Color.secondary.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isAuthorized ? .green : .secondary)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline.bold())

                    if isRequired {
                        Text("REQUIRED")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(3)
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Action
            if isAuthorized {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            } else {
                Button("Authorize...") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isAuthorized ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Previews

#Preview("No Access") {
    BookmarkAuthView()
}

#Preview("With Cargo Access") {
    BookmarkAuthView()
}

#Preview("All Access") {
    BookmarkAuthView()
}
