//
//  AppUpdateService.swift
//  RustMate
//
//  T010: Update coordinator/service wrapping Sparkle updater
//  Based on specs/005-sparkle-auto-update/plan.md
//
//  ⚠️ PREREQUISITE: Sparkle 2 must be added via SPM (see SPARKLE_INTEGRATION.md)
//

import Foundation
import Sparkle  // ⚠️ Requires Sparkle 2 package dependency
import Combine

// MARK: - App Update Service

/// Coordinates application updates using Sparkle 2
/// Provides a clean interface for checking, downloading, and installing updates
@MainActor
class AppUpdateService: NSObject, ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var updateState: UpdateState = .idle
    @Published private(set) var currentChannel: AppSettings.UpdateChannel = .stable
    
    var automaticallyDownloadsUpdates: Bool {
        get {
            updaterController.updater.automaticallyDownloadsUpdates
        }
        set {
            updaterController.updater.automaticallyDownloadsUpdates = newValue
            objectWillChange.send()
        }
    }
    
    // MARK: - Private Properties
    
    private var updaterController: SPUStandardUpdaterController
    private var feedURL: URL
    
    // MARK: - Initialization
    
    /// Initialize the update service with a specific channel
    /// - Parameter channel: The update channel to use (stable/beta)
    init(channel: AppSettings.UpdateChannel = .stable) {
        self.currentChannel = channel
        let feedConfig = UpdateFeedConfig.feed(for: channel)
        self.feedURL = feedConfig.url
        
        // Initialize updater controller placeholder
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        super.init()
        
        // Now reinitialize with self as delegate
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
        
        // Sync channel preference to UserDefaults (used by delegate in background thread)
        UserDefaults.standard.set(channel.rawValue, forKey: "updateChannel")
        
        // Configure the updater
        configureUpdater()
        
        print("✅ AppUpdateService: Initialized with \(channel.displayText) channel")
        print("📡 AppUpdateService: Feed URL: \(feedURL.absoluteString)")
    }
    
    // MARK: - Configuration
    
    private func configureUpdater() {
        let updater = updaterController.updater
        
        // T013: Enable automatic checks and downloads
        updater.automaticallyChecksForUpdates = true
        updater.automaticallyDownloadsUpdates = true
        
        // Note: feedURL is set via delegate method feedURLString(for:)
        // This allows dynamic channel switching at runtime
        
        // Validate feed URL security (Contract requirement: HTTPS only)
        let validation = UpdateValidation.validateFeedURL(feedURL)
        if !validation.isValid {
            print("⚠️ AppUpdateService: Feed URL validation failed: \(validation.errorMessage ?? "unknown")")
        }
        
        print("✅ AppUpdateService: Updater configured")
        print("   - Automatic checks: \(updater.automaticallyChecksForUpdates)")
        print("   - Automatic downloads: \(updater.automaticallyDownloadsUpdates)")
    }
    
    // MARK: - Public API
    
    /// Manually check for updates
    func checkForUpdates() {
        print("🔍 AppUpdateService: Manually checking for updates...")
        
        // Sync channel preference to UserDefaults (used by delegate in background thread)
        UserDefaults.standard.set(currentChannel.rawValue, forKey: "updateChannel")
        
        updateState = .checking
        
        updaterController.checkForUpdates(nil)
    }
    
    /// Switch to a different update channel
    /// - Parameter channel: The new channel to use
    /// - Note: In Sparkle 2, feed URL is read-only. Channel change takes effect on next check.
    func switchChannel(to channel: AppSettings.UpdateChannel) {
        guard channel != currentChannel else {
            print("ℹ️ AppUpdateService: Already on \(channel.displayText) channel")
            return
        }
        
        print("🔄 AppUpdateService: Switching from \(currentChannel.displayText) to \(channel.displayText)")
        
        currentChannel = channel
        let feedConfig = UpdateFeedConfig.feed(for: channel)
        feedURL = feedConfig.url
        
        // Sync to UserDefaults (used by delegate in background thread)
        UserDefaults.standard.set(channel.rawValue, forKey: "updateChannel")
        
        // Note: Sparkle 2's feedURL is read-only at runtime.
        // The new channel will be used on next update check via delegate method.
        print("ℹ️ AppUpdateService: Channel preference saved.")
        print("📡 AppUpdateService: Will use feed: \(feedURL.absoluteString)")
    }
    
    /// Get the current update state as display text
    var stateDisplayText: String {
        updateState.displayText
    }
    
    /// Check if an update operation is currently in progress
    var isUpdating: Bool {
        updateState.isInProgress
    }
}

// MARK: - Sparkle Delegate (Future Enhancement)

/// Custom delegate for Sparkle updater events
/// This can be used to map Sparkle events to our UpdateState enum
/// T014/T019: Will be implemented for state tracking and error handling
extension AppUpdateService {
    
    // TODO: Implement SPUUpdaterDelegate methods to track:
    // - Update found (updateState = .updateAvailable)
    // - Download progress (updateState = .downloading)
    // - Download complete (updateState = .readyToInstall)
    // - Errors (updateState = .failed)
    
    // TODO: Implement SPUUserDriver for custom UI
    // - Show update prompts in our Settings UI
    // - Display download progress
    // - Handle "Install and Restart" vs "Later" choices
}

// MARK: - Error Mapping (T019)

extension AppUpdateService {
    
    /// Map Sparkle errors to our structured UpdateError
    /// T019: Maps Sparkle error types to user-actionable UpdateError
    func mapSparkleError(_ error: Error) -> UpdateError {
        let nsError = error as NSError
        
        // Check for network errors
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .networkUnavailable()
            case NSURLErrorTimedOut, NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return .feedUnavailable(url: feedURL.absoluteString)
            case NSURLErrorBadServerResponse:
                return .invalidFeed(reason: "Server returned invalid response")
            default:
                return .downloadFailed(reason: nsError.localizedDescription)
            }
        }
        
        // Check for Sparkle-specific errors
        let errorDescription = error.localizedDescription.lowercased()
        
        // T022: Signature validation failures
        if errorDescription.contains("signature") || errorDescription.contains("verification") {
            return .signatureInvalid()
        }
        
        // Feed parsing errors
        if errorDescription.contains("appcast") || errorDescription.contains("feed") || errorDescription.contains("xml") {
            return .invalidFeed(reason: "Failed to parse update feed")
        }
        
        // Download errors
        if errorDescription.contains("download") {
            return .downloadFailed(reason: error.localizedDescription)
        }
        
        // System version errors (handled separately in validation)
        if errorDescription.contains("system") || errorDescription.contains("version") {
            let currentVersion = ProcessInfo.processInfo.operatingSystemVersion
            let currentVersionString = "\(currentVersion.majorVersion).\(currentVersion.minorVersion)"
            return .unsupportedSystemVersion(required: "15.0", current: currentVersionString)
        }
        
        // Default: unknown error with message
        return .unknown(message: error.localizedDescription)
    }
    
    /// Handle update errors and update state
    /// T019: Centralized error handling
    func handleUpdateError(_ error: Error) {
        let mappedError = mapSparkleError(error)
        updateState = .failed(mappedError)
        
        print("❌ AppUpdateService: Update failed")
        print("   Category: \(mappedError.category)")
        print("   Message: \(mappedError.userMessage)")
        print("   Recovery: \(mappedError.recoverySuggestion)")
        
        if let debugContext = mappedError.debugContext {
            print("   Debug: \(debugContext)")
        }
    }
}

// MARK: - SPUUpdaterDelegate

extension AppUpdateService: SPUUpdaterDelegate {
    /// Provide the feed URL dynamically based on current channel
    /// This allows runtime channel switching without app restart
    nonisolated func feedURLString(for updater: SPUUpdater) -> String? {
        // Return the feed URL based on stored channel preference
        // Note: This is called from Sparkle's background thread, so we use UserDefaults
        let channelRawValue = UserDefaults.standard.string(forKey: "updateChannel") ?? "stable"
        let channel = AppSettings.UpdateChannel(rawValue: channelRawValue) ?? .stable
        let config = UpdateFeedConfig.feed(for: channel)
        return config.url.absoluteString
    }
    
    /// Called when no update is found
    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        Task { @MainActor in
            print("ℹ️ AppUpdateService: No update found")
            updateState = .noUpdate
            
            // Reset to idle after a short delay to show the message
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await MainActor.run {
                    if case .noUpdate = updateState {
                        updateState = .idle
                    }
                }
            }
        }
    }
    
    /// Called when update check completes (with potential error)
    nonisolated func updater(_ updater: SPUUpdater, didFinishUpdateCheckFor updateCheck: SPUUpdateCheck, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ AppUpdateService: Update check failed: \(error.localizedDescription)")
                handleUpdateError(error)
            } else {
                print("✅ AppUpdateService: Update check completed")
                // If no update was found, updaterDidNotFindUpdate will be called
                // If update was found, didFindValidUpdate will be called
                // If we're still in checking state after a delay, reset to idle as fallback
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    await MainActor.run {
                        // Only reset if still checking (other methods should have updated state)
                        if case .checking = updateState {
                            print("⚠️ AppUpdateService: Still in checking state, resetting to idle")
                            updateState = .idle
                        }
                    }
                }
            }
        }
    }
    
    /// Called when a valid update is found
    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        Task { @MainActor in
            let versionString = item.versionString
            print("✅ AppUpdateService: Update found - \(versionString)")
            
            // Generate build number from version string
            // Convert "1.0.1" -> "1001000" or "1.2.0-beta.1" -> "1200001"
            let buildNumber = versionStringToBuildNumber(versionString)
            
            let updateInfo = UpdateInfo(
                version: versionString,
                buildNumber: buildNumber,
                releaseNotesURL: item.releaseNotesURL,
                downloadSize: item.contentLength > 0 ? Int64(item.contentLength) : nil
            )
            updateState = .updateAvailable(updateInfo)
        }
    }
    
    /// Convert version string to a numeric build number for comparison
    private func versionStringToBuildNumber(_ version: String) -> String {
        // Remove non-numeric characters except dots and dashes
        var cleaned = version.replacingOccurrences(of: "-", with: ".")
        let components = cleaned.components(separatedBy: ".")
        
        // Extract numeric parts (major.minor.patch)
        var numbers: [Int] = []
        for component in components.prefix(4) { // Limit to 4 components (major.minor.patch.beta)
            if let num = Int(component.filter { $0.isNumber }) {
                numbers.append(num)
            } else {
                break
            }
        }
        
        // Pad to at least 3 components (major.minor.patch)
        while numbers.count < 3 {
            numbers.append(0)
        }
        
        // Convert to build number format: major * 1000000 + minor * 1000 + patch
        // e.g., 1.0.1 -> 1001000, 1.2.0 -> 1020000
        let buildNum = numbers[0] * 1_000_000 + 
                      (numbers.count > 1 ? numbers[1] : 0) * 1_000 + 
                      (numbers.count > 2 ? numbers[2] : 0)
        
        return String(buildNum)
    }
    
    #if DEBUG
    /// Allow insecure downloads in test mode (no signature verification)
    /// ⚠️ Only enabled in DEBUG builds for local testing
    /// This is the correct Sparkle 2 delegate method for bypassing signature verification
    nonisolated func updater(
        _ updater: SPUUpdater,
        shouldAllowInsecureDownloadsFor appcastItem: SUAppcastItem,
        from url: URL
    ) -> Bool {
        // Only allow insecure downloads in test mode
        let isTestMode = ProcessInfo.processInfo.environment["SPARKLE_TEST_MODE"] == "1"
        if isTestMode {
            print("⚠️ AppUpdateService: Allowing insecure download in test mode")
        }
        return isTestMode
    }
    #endif
}

