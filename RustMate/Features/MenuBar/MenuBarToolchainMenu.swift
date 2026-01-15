//
//  MenuBarToolchainMenu.swift
//  RustMate
//
//  Menu bar menu view for toolchain management
//

import SwiftUI
import Combine

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
        
        // Activate the app first
        NSApp.activate(ignoringOtherApps: true)
        
        // Check if main window already exists
        var mainWindowExists = false
        for window in NSApp.windows {
            let className = String(describing: type(of: window))
            // Check if this is the main window (not menu bar or status bar windows)
            if !className.contains("MenuBar") && !className.contains("StatusBar") && !className.contains("NSStatusBar") && window.canBecomeKey {
                mainWindowExists = true
                print("✅ MenuBar: Main window already exists, activating it")
                
                // Activate existing window
                if window.isMiniaturized {
                    window.deminiaturize(nil)
                }
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                return
            }
        }
        
        // If window doesn't exist, create a new one
        if !mainWindowExists {
            print("📢 MenuBar: Main window doesn't exist, creating new one")
            openWindow(id: "main")
            
            // Wait a bit for window creation, then activate it
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                for window in NSApp.windows {
                    let className = String(describing: type(of: window))
                    if !className.contains("MenuBar") && !className.contains("StatusBar") && !className.contains("NSStatusBar") && window.canBecomeKey {
                        window.makeKeyAndOrderFront(nil)
                        window.orderFrontRegardless()
                        print("✅ MenuBar: New main window activated")
                        return
                    }
                }
            }
        }
    }
}
