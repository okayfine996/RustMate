//
//  MenuBarToolchainMenu.swift
//  RustMate
//
//  Menu bar menu view for toolchain management
//

import SwiftUI

struct MenuBarToolchainMenu: View {
    @ObservedObject var viewModel: MenuBarToolchainViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            // Current default toolchain section (non-interactive display)
            defaultToolchainSection

            Divider()

            // Available toolchains section
            toolchainListSection

            Divider()

            // Actions section
            Button("Refresh") {
                Task {
                    await viewModel.loadState()
                }
            }
            .disabled(viewModel.status.isWorking)

            Button("Open RustMate") {
                openMainWindow()
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .task {
            // Load state only if not already loaded or if data is stale
            if viewModel.toolchains.isEmpty {
                print("📊 MenuBarMenu: Loading state on first appear")
                await viewModel.loadState()
            }
        }
    }

    // MARK: - Default Toolchain Section (T008)

    @ViewBuilder
    private var defaultToolchainSection: some View {
        if viewModel.status == .loading {
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.secondary)
        } else if viewModel.status == .error {
            errorStateView
        } else if let defaultId = viewModel.currentDefaultToolchainId {
            Text("Current: \(defaultId)")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            Text("No default toolchain")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error State View (T010)

    @ViewBuilder
    private var errorStateView: some View {
        if let presentation = viewModel.errorPresentation {
            Text("⚠️ \(presentation.title)")
                .font(.caption)
                .foregroundColor(.secondary)

            if viewModel.requiresAuthorization {
                Button("Open Settings") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
                }
            }
        }
    }

    // MARK: - Toolchain List Section (T012)

    @ViewBuilder
    private var toolchainListSection: some View {
        if viewModel.status == .switching {
            Text("⏳ Switching...")
                .font(.caption)
                .foregroundColor(.secondary)
        } else if !viewModel.toolchains.isEmpty {
            ForEach(viewModel.toolchainOptions(), id: \.id) { option in
                Button {
                    Task {
                        await viewModel.switchDefaultToolchain(to: option.id)
                    }
                } label: {
                    HStack {
                        Text(option.displayName)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        if option.isDefault {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .disabled(!option.isSelectable || option.isDefault)
            }
        }
    }

    // MARK: - Actions (T020)

    private func openMainWindow() {
        print("📢 MenuBar: Opening main window via SwiftUI")

        // First, try to use SwiftUI's openWindow to open/create the window
        openWindow(id: "main")

        // Then activate the app and bring window to front
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)

            // Find and activate the main window (not the menu bar window)
            for window in NSApp.windows {
                let className = String(describing: type(of: window))
                if !className.contains("StatusBar") && window.canBecomeKey {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                    print("✅ MenuBar: Main window activated")
                    return
                }
            }
        }
    }
}
