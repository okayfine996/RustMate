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
