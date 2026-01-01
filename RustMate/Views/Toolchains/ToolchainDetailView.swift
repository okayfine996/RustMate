//
//  ToolchainDetailView.swift
//  RustMate
//
//  Detail view showing toolchain metadata and operations
//

import SwiftUI

struct ToolchainDetailView: View {
    let toolchain: ToolchainInfo
    let onSetDefault: () -> Void
    let onUpdate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(toolchain.isDefault ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1))
                                .frame(width: 60, height: 60)

                            Image(systemName: toolchain.isDefault ? "checkmark.circle.fill" : "hammer.fill")
                                .font(.largeTitle)
                                .foregroundStyle(toolchain.isDefault ? .blue : .secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(toolchain.name)
                                    .font(.title.bold())

                                if toolchain.isDefault {
                                    Text("DEFAULT")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.blue)
                                        .cornerRadius(4)
                                }
                            }

                            if let version = toolchain.version {
                                Text("Version \(version)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Divider()

                // Metadata
                VStack(alignment: .leading, spacing: 16) {
                    Text("Toolchain Information")
                        .font(.headline)

                    if let host = toolchain.host {
                        metadataRow(label: "Host Triple", value: host, icon: "cpu")
                    }

                    if let date = toolchain.installDate {
                        metadataRow(
                            label: "Installed",
                            value: formatDate(date),
                            icon: "calendar"
                        )
                    }

                    metadataRow(
                        label: "Status",
                        value: toolchain.isDefault ? "Active (Default)" : "Installed",
                        icon: "info.circle"
                    )
                }

                Divider()

                // Operations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Operations")
                        .font(.headline)

                    if !toolchain.isDefault {
                        Button {
                            onSetDefault()
                        } label: {
                            HStack {
                                Label("Set as Default", systemImage: "star.fill")
                                    .font(.body.bold())
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        onUpdate()
                    } label: {
                        HStack {
                            Label("Update Toolchain", systemImage: "arrow.clockwise")
                                .font(.body.bold())
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    if !toolchain.isDefault {
                        Button {
                            onDelete()
                        } label: {
                            HStack {
                                Label("Uninstall Toolchain", systemImage: "trash")
                                    .font(.body.bold())
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                    }
                }

                Divider()

                // Usage Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Usage")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Set as project override:")
                            .font(.subheadline.bold())

                        Text("rustup override set \(toolchain.name)")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)

                        Text("Or add to rust-toolchain.toml:")
                            .font(.subheadline.bold())
                            .padding(.top, 4)

                        Text("[toolchain]\nchannel = \"\(toolchain.name)\"")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                Spacer()
            }
            .padding(24)
        }
        .navigationTitle(toolchain.name)
        .navigationSubtitle(toolchain.isDefault ? "Default Toolchain" : "Installed Toolchain")
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func metadataRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(6)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview("Default Toolchain") {
    NavigationStack {
        ToolchainDetailView(
            toolchain: ToolchainInfo(
                id: UUID(),
                name: "stable-aarch64-apple-darwin",
                version: "1.75.0",
                isDefault: true,
                installDate: Date().addingTimeInterval(-86400 * 30),
                host: "aarch64-apple-darwin"
            ),
            onSetDefault: {},
            onUpdate: {},
            onDelete: {}
        )
    }
}

#Preview("Non-Default Toolchain") {
    NavigationStack {
        ToolchainDetailView(
            toolchain: ToolchainInfo(
                id: UUID(),
                name: "nightly-aarch64-apple-darwin",
                version: "1.77.0-nightly",
                isDefault: false,
                installDate: Date().addingTimeInterval(-86400 * 7),
                host: "aarch64-apple-darwin"
            ),
            onSetDefault: {},
            onUpdate: {},
            onDelete: {}
        )
    }
}
