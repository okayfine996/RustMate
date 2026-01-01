//
//  ToolchainRowView.swift
//  RustMate
//
//  Row view for displaying toolchain information
//

import SwiftUI

struct ToolchainRowView: View {
    let toolchain: ToolchainInfo
    let onSetDefault: () -> Void
    let onUpdate: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(toolchain.isDefault ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: toolchain.isDefault ? "checkmark.circle.fill" : "hammer.fill")
                    .font(.title3)
                    .foregroundStyle(toolchain.isDefault ? .blue : .secondary)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(toolchain.name)
                        .font(.body.bold())

                    if toolchain.isDefault {
                        Text("DEFAULT")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(3)
                    }
                }

                HStack(spacing: 12) {
                    if let version = toolchain.version {
                        Label(version, systemImage: "tag")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let host = toolchain.host {
                        Label(host, systemImage: "cpu")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let date = toolchain.installDate {
                        Label(formatDate(date), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Actions (show on hover)
            if isHovering {
                HStack(spacing: 8) {
                    if !toolchain.isDefault {
                        Button {
                            onSetDefault()
                        } label: {
                            Label("Set Default", systemImage: "star.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Button {
                        onUpdate()
                    } label: {
                        Label("Update", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    if !toolchain.isDefault {
                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .foregroundStyle(.red)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isHovering ? Color.secondary.opacity(0.05) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            if !toolchain.isDefault {
                Button {
                    onSetDefault()
                } label: {
                    Label("Set as Default", systemImage: "star.fill")
                }
            }

            Button {
                onUpdate()
            } label: {
                Label("Update", systemImage: "arrow.clockwise")
            }

            Divider()

            if !toolchain.isDefault {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Uninstall", systemImage: "trash")
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Previews

#Preview("Default Toolchain") {
    ToolchainRowView(
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
    .padding()
}

#Preview("Non-Default Toolchain") {
    ToolchainRowView(
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
    .padding()
}

#Preview("Minimal Info") {
    ToolchainRowView(
        toolchain: ToolchainInfo(
            id: UUID(),
            name: "beta",
            version: nil,
            isDefault: false,
            installDate: nil,
            host: nil
        ),
        onSetDefault: {},
        onUpdate: {},
        onDelete: {}
    )
    .padding()
}
