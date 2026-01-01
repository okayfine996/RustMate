//
//  ProjectContextView.swift
//  RustMate
//
//  Detailed view showing project toolchain context and override management
//

import SwiftUI

struct ProjectContextView: View {
    let context: ProjectContextInfo
    let availableToolchains: [ToolchainInfo]
    let onSetOverride: (ToolchainInfo) -> Void
    let onClearOverride: () -> Void

    @State private var showingOverridePicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Active toolchain section
                activeToolchainSection

                Divider()

                // Override source section
                overrideSourceSection

                Divider()

                // Actions section
                actionsSection
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Active Toolchain Section

    @ViewBuilder
    private var activeToolchainSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active Toolchain", systemImage: "hammer.fill")
                .font(.headline)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.activeToolchain)
                        .font(.title3.bold())
                        .fontDesign(.monospaced)

                    Text(reasonDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - Override Source Section

    @ViewBuilder
    private var overrideSourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Override Source", systemImage: "info.circle")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Reason:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Text(reasonText)
                        .font(.caption)
                        .fontDesign(.monospaced)

                    Spacer()
                }

                if let sourcePath = context.sourcePath {
                    HStack {
                        Text("Source:")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        Text(sourcePath)
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .lineLimit(2)

                        Spacer()
                    }
                }

                HStack {
                    Text("Project:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Text(context.projectPath)
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .lineLimit(2)

                    Spacer()
                }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - Actions Section

    @ViewBuilder
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Manage Override", systemImage: "wrench.and.screwdriver")
                .font(.headline)

            VStack(spacing: 12) {
                // Set override
                Menu {
                    ForEach(availableToolchains) { toolchain in
                        Button {
                            onSetOverride(toolchain)
                        } label: {
                            HStack {
                                Text(toolchain.name)
                                if toolchain.isDefault {
                                    Text("(default)")
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if context.activeToolchain == toolchain.name {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Set Toolchain Override")
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(availableToolchains.isEmpty)

                // Clear override
                if context.reason != .default {
                    Button {
                        onClearOverride()
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clear Override")
                            Spacer()
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var reasonText: String {
        switch context.reason {
        case .default:
            return "default"
        case .toolchainFile:
            return "toolchain file"
        case .override:
            return "rustup override"
        case .environment:
            return "environment variable"
        case .unknown:
            return "unknown"
        }
    }

    private var reasonDescription: String {
        switch context.reason {
        case .default:
            return "Using system default toolchain"
        case .toolchainFile:
            return "Overridden by rust-toolchain file"
        case .override:
            return "Overridden by rustup override"
        case .environment:
            return "Overridden by RUSTUP_TOOLCHAIN environment variable"
        case .unknown:
            return "Toolchain source unknown"
        }
    }
}

// MARK: - Previews

#Preview("Default Toolchain") {
    let context = ProjectContextInfo(
        projectPath: "/Users/user/projects/my-rust-app",
        activeToolchain: "stable-aarch64-apple-darwin",
        reason: .default,
        sourcePath: nil
    )

    let toolchains = [
        ToolchainInfo(
            name: "stable-aarch64-apple-darwin",
            version: "1.75.0",
            isDefault: true,
            installDate: Date(),
            host: "aarch64-apple-darwin"
        ),
        ToolchainInfo(
            name: "nightly-aarch64-apple-darwin",
            version: "1.77.0-nightly",
            isDefault: false,
            installDate: Date(),
            host: "aarch64-apple-darwin"
        )
    ]

    return ProjectContextView(
        context: context,
        availableToolchains: toolchains,
        onSetOverride: { _ in },
        onClearOverride: { }
    )
    .frame(width: 600, height: 600)
}

#Preview("Toolchain File Override") {
    let context = ProjectContextInfo(
        projectPath: "/Users/user/projects/my-rust-app",
        activeToolchain: "nightly-aarch64-apple-darwin",
        reason: .toolchainFile,
        sourcePath: "/Users/user/projects/my-rust-app/rust-toolchain.toml"
    )

    let toolchains = [
        ToolchainInfo(
            name: "stable-aarch64-apple-darwin",
            version: "1.75.0",
            isDefault: true,
            installDate: Date(),
            host: "aarch64-apple-darwin"
        ),
        ToolchainInfo(
            name: "nightly-aarch64-apple-darwin",
            version: "1.77.0-nightly",
            isDefault: false,
            installDate: Date(),
            host: "aarch64-apple-darwin"
        )
    ]

    return ProjectContextView(
        context: context,
        availableToolchains: toolchains,
        onSetOverride: { _ in },
        onClearOverride: { }
    )
    .frame(width: 600, height: 600)
}
