//
//  RustMateApp.swift
//  RustMate
//
//  Created by Fine Ke on 31/12/2025.
//

import SwiftUI
import Combine

@main
struct RustMateApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appState.showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        #if os(macOS)
        Settings {
            SettingsView(settings: appState.settings)
        }
        #endif
    }
}

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var settings = AppSettings()
    @Published var showSettings = false
    @Published var needsSetup = false

    private let firstLaunchKey = "RustMate.hasCompletedFirstLaunch"

    init() {
        checkSetupStatus()
    }

    private func checkSetupStatus() {
        // Check if this is first launch
        let hasCompletedFirstLaunch = UserDefaults.standard.bool(forKey: firstLaunchKey)

        if !hasCompletedFirstLaunch {
            // First launch - need setup
            needsSetup = true
        } else {
            // Not first launch, but check if rustup access is still valid
            let bookmarkManager = BookmarkManager()
            let cargoPath = NSString(string: "~/.cargo/bin").expandingTildeInPath

            // For sandbox builds, require bookmark
            #if SANDBOX_ENABLED
            needsSetup = !bookmarkManager.hasBookmark(for: cargoPath)
            #else
            // Without sandbox, skip setup
            needsSetup = false
            #endif
        }
    }

    func completeSetup() {
        // Mark first launch as complete
        UserDefaults.standard.set(true, forKey: firstLaunchKey)
        needsSetup = false
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.needsSetup {
                SetupView()
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SetupCompleted"))) { _ in
                        appState.completeSetup()
                    }
            } else {
                MainContentView()
            }
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView(settings: appState.settings)
        }
    }
}
