//
//  RustMateApp.swift
//  RustMate
//
//  Created by Fine Ke on 31/12/2025.
//

import SwiftUI
import Combine

// MARK: - Global Window Activation Function

func activateMainWindow() {
    print("🔔 Global: Received OpenMainWindow notification")
    print("📊 Global: Total windows: \(NSApp.windows.count)")

    // Activate the app
    NSApp.activate(ignoringOtherApps: true)
    print("✅ Global: Application activated")

    // Find and activate the main window
    DispatchQueue.main.async {
        // Log all windows for debugging
        for (index, window) in NSApp.windows.enumerated() {
            let className = String(describing: type(of: window))
            print("  Window \(index): title='\(window.title)', class=\(className), styleMask=\(window.styleMask.rawValue), isVisible=\(window.isVisible), canBecomeKey=\(window.canBecomeKey), level=\(window.level.rawValue)")
        }

        // Strategy 1: Try to find window by class name (exclude MenuBarExtra windows)
        for window in NSApp.windows {
            let className = String(describing: type(of: window))
            if !className.contains("MenuBar") && !className.contains("StatusBar") && !className.contains("NSStatusBar") {
                print("🎯 Global: Found content window by class: '\(window.title)', class=\(className)")
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                // Also try to deminiaturize if minimized
                if window.isMiniaturized {
                    window.deminiaturize(nil)
                }
                return
            }
        }

        // Strategy 2: Try to find any window that can become key
        for window in NSApp.windows where window.canBecomeKey {
            print("🎯 Global: Found key window: '\(window.title)'")
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            return
        }

        // Strategy 3: No window found - trigger window creation
        print("⚠️ Global: No main window found, attempting to open new window")

        // Use NSApp to open a new window
        if #available(macOS 13.0, *) {
            // Try using the new window opening API
            NSApp.sendAction(Selector(("newDocument:")), to: nil, from: nil)
        }

        // Wait a bit for window creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("📊 Global: After window creation, total windows: \(NSApp.windows.count)")

            // Try to find and activate the newly created window
            for window in NSApp.windows {
                let className = String(describing: type(of: window))
                if !className.contains("StatusBar") && window.canBecomeKey {
                    print("🎯 Global: Found newly created window: '\(window.title)'")
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                    return
                }
            }

            print("⚠️ Global: Still no suitable window found after creation attempt")
        }
    }
}

@main
struct RustMateApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var menuBarViewModel = MenuBarToolchainViewModel()

    init() {
        // Set up notification observer for opening main window
        // This needs to be at app level to ensure it's always active
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenMainWindow"),
            object: nil,
            queue: .main
        ) { _ in
            activateMainWindow()
        }
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            RootView()
                .environmentObject(appState)
                .task {
                    // Initialize menu bar state on app launch
                    print("📊 App: Initializing menu bar state")
                    await menuBarViewModel.loadState()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenMainWindow"))) { _ in
                    print("🔔 RootView: Received OpenMainWindow in SwiftUI context")
                    // Window already exists if this code runs, just bring it to front
                    activateMainWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 800, height: 600)
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

        // Menu bar entry with display space fallback
        MenuBarExtra {
            MenuBarToolchainMenu(viewModel: menuBarViewModel)
        } label: {
            if let defaultToolchain = menuBarViewModel.currentDefaultToolchainId {
                // Fallback strategy: show shortened version if too long
                let displayName = shortenToolchainName(defaultToolchain)
                Text(displayName)
                    .font(.system(.caption, design: .monospaced))
            } else if menuBarViewModel.status == .loading {
                Image(systemName: "arrow.clockwise")
            } else {
                Image(systemName: "gearshape")
            }
        }
        #endif
    }

    // MARK: - Helper Functions

    /// Shorten toolchain name for menu bar display
    /// - Parameter name: Full toolchain name
    /// - Returns: Shortened name if too long
    private func shortenToolchainName(_ name: String) -> String {
        // If name is short enough, return as-is
        if name.count <= 20 {
            return name
        }

        // Try to extract the channel (stable, beta, nightly)
        let components = name.split(separator: "-")
        if let channel = components.first {
            return String(channel)
        }

        // Fallback: truncate with ellipsis
        let prefix = name.prefix(17)
        return "\(prefix)..."
    }
}

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var settings = AppSettings() {
        didSet {
            saveSettings()
        }
    }
    @Published var showSettings = false
    @Published var needsSetup = false

    private let firstLaunchKey = "RustMate.hasCompletedFirstLaunch"
    private let settingsKey = "RustMate.AppSettings"

    init() {
        loadSettings()
        checkSetupStatus()
    }

    // MARK: - Settings Persistence

    private func saveSettings() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
            print("💾 AppState: Saved settings, authorized directories count: \(settings.authorizedDirectories.count)")
        } catch {
            print("❌ AppState: Failed to save settings: \(error)")
        }
    }

    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else {
            print("📂 AppState: No saved settings found, using defaults")
            return
        }

        do {
            let decoder = JSONDecoder()
            settings = try decoder.decode(AppSettings.self, from: data)
            print("📂 AppState: Loaded settings, authorized directories count: \(settings.authorizedDirectories.count)")
        } catch {
            print("❌ AppState: Failed to load settings: \(error)")
        }
    }

    private func checkSetupStatus() {
        // Check if this is first launch
        let hasCompletedFirstLaunch = UserDefaults.standard.bool(forKey: firstLaunchKey)

        if !hasCompletedFirstLaunch {
            // First launch - need setup
            needsSetup = true
            print("🔍 AppState: First launch detected, showing setup")
        } else {
            // Not first launch, but check if all required authorizations exist
            // Always require authorizations for sandboxed local execution
            needsSetup = !settings.hasAllRequiredAuthorizations
            print("🔍 AppState: Not first launch, has all required authorizations: \(settings.hasAllRequiredAuthorizations)")
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
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var showAuthorizationSheet = false
    @State private var authorizationPurposes: [AuthorizedDirectory.DirectoryPurpose] = []
    @State private var authorizationQueue: [AuthorizedDirectory.DirectoryPurpose] = []
    @State private var isProcessingAuthorizationQueue = false

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
        // T042/T046: Handle authorization requests from anywhere in the app
        .onReceive(NotificationCenter.default.publisher(for: AuthorizationCoordinator.authorizationRequestedNotification)) { notification in
            handleAuthorizationRequest(notification)
        }
        // Handle authorization completion to process queue
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AuthorizationCompleted"))) { _ in
            processAuthorizationQueue()
        }
        // Handle "Open Settings" notifications
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenSettings"))) { _ in
            appState.showSettings = true
        }
    }

    private func handleAuthorizationRequest(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let purposes = userInfo[AuthorizationCoordinator.missingPurposesKey] as? [AuthorizedDirectory.DirectoryPurpose],
              !purposes.isEmpty else {
            print("⚠️ RootView: Invalid authorization request notification")
            return
        }

        print("📢 RootView: Handling authorization request for \(purposes.count) purposes: \(purposes)")

        // Set up authorization queue
        authorizationQueue = purposes
        isProcessingAuthorizationQueue = true

        // Open settings and start authorizing first purpose
        Task { @MainActor in
            appState.showSettings = true
            // Small delay to let the settings sheet appear
            try? await Task.sleep(nanoseconds: 100_000_000)
            processAuthorizationQueue()
        }
    }

    private func processAuthorizationQueue() {
        guard isProcessingAuthorizationQueue, !authorizationQueue.isEmpty else {
            // Queue is empty, stop processing
            if isProcessingAuthorizationQueue {
                isProcessingAuthorizationQueue = false
                print("📢 RootView: Authorization queue completed, posting AllAuthorizationsCompleted notification")
                // Post notification that all authorizations are complete
                NotificationCenter.default.post(
                    name: NSNotification.Name("AllAuthorizationsCompleted"),
                    object: nil
                )
            }
            return
        }

        // Get the next purpose from queue
        let nextPurpose = authorizationQueue.removeFirst()
        print("📢 RootView: Processing authorization queue, authorizing \(nextPurpose.displayText). Remaining: \(authorizationQueue.count)")

        // Trigger authorization for this purpose
        settingsViewModel.authorizeDirectory(purpose: nextPurpose)

        // When authorization completes, AuthorizationCompleted notification will fire
        // and call this function again to process the next item
    }
}
