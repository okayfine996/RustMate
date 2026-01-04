//
//  TaskNotificationManager.swift
//  RustMate
//
//  Manages system notifications for long-running tasks
//

import Foundation
import UserNotifications
import Combine

@MainActor
class TaskNotificationManager: NSObject, ObservableObject {
    static let shared = TaskNotificationManager()

    let objectWillChange = ObservableObjectPublisher()

    private let notificationCenter = UNUserNotificationCenter.current()
    private var activeNotifications: [UUID: String] = [:]

    private override init() {
        super.init()
        notificationCenter.delegate = self
    }

    /// Request notification permission from the user
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            print("⚠️ Failed to request notification authorization: \(error)")
            return false
        }
    }

    /// Show notification when a task starts
    func notifyTaskStarted(_ task: TaskRecord) async {
        // Check if notifications are enabled
        guard AppSettings.default.enableTaskNotifications else {
            print("ℹ️ Task notifications are disabled in settings")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = formatOperation(task.operation)
        content.body = formatTaskStartMessage(task)
        content.sound = nil // Silent notification for start

        let identifier = "task-\(task.id.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Show immediately
        )

        do {
            try await notificationCenter.add(request)
            activeNotifications[task.id] = identifier
            print("✅ Notification sent for task: \(task.operation)")
        } catch {
            print("⚠️ Failed to send notification: \(error)")
        }
    }

    /// Update notification when task completes
    func notifyTaskCompleted(_ task: TaskRecord) async {
        // Remove the running notification first
        if let identifier = activeNotifications[task.id] {
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
            activeNotifications.removeValue(forKey: task.id)
        }

        // Check if notifications are enabled
        guard AppSettings.default.enableTaskNotifications else {
            print("ℹ️ Task notifications are disabled in settings")
            return
        }

        // Send completion notification
        let content = UNMutableNotificationContent()
        content.title = formatOperation(task.operation)
        content.body = formatTaskCompletionMessage(task)

        // Set sound for completion
        if task.status == .success {
            content.sound = .default
        } else if task.status == .failed {
            content.sound = .defaultCritical
        }

        let identifier = "task-complete-\(task.id.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        do {
            try await notificationCenter.add(request)
            print("✅ Completion notification sent for task: \(task.operation)")
        } catch {
            print("⚠️ Failed to send completion notification: \(error)")
        }
    }

    /// Cancel notification for a task
    func cancelNotification(for taskId: UUID) {
        if let identifier = activeNotifications[taskId] {
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
            activeNotifications.removeValue(forKey: taskId)
        }
    }

    /// Clear all notifications
    func clearAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        activeNotifications.removeAll()
    }

    // MARK: - Formatting Helpers

    private func formatOperation(_ operation: String) -> String {
        switch operation {
        case "install":
            return "Installing Toolchain"
        case "uninstall":
            return "Uninstalling Toolchain"
        case "update":
            return "Updating Toolchain"
        case "updateAll":
            return "Updating All Toolchains"
        case "setDefault":
            return "Setting Default Toolchain"
        case "addComponent":
            return "Installing Component"
        case "removeComponent":
            return "Removing Component"
        case "addTarget":
            return "Installing Target"
        case "removeTarget":
            return "Removing Target"
        default:
            return operation.capitalized
        }
    }

    private func formatTaskStartMessage(_ task: TaskRecord) -> String {
        if let target = task.target {
            return "Processing \(target)..."
        } else {
            return "Processing..."
        }
    }

    private func formatTaskCompletionMessage(_ task: TaskRecord) -> String {
        let targetInfo = task.target.map { " \($0)" } ?? ""

        switch task.status {
        case .success:
            if let duration = task.duration {
                return "Completed\(targetInfo) in \(formatDuration(duration))"
            } else {
                return "Completed\(targetInfo)"
            }
        case .failed:
            if let errorMessage = task.errorMessage {
                return "Failed: \(errorMessage)"
            } else {
                return "Failed\(targetInfo)"
            }
        case .cancelled:
            return "Cancelled\(targetInfo)"
        case .running:
            return "In progress\(targetInfo)"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(seconds)s"
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension TaskNotificationManager: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    /// Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // User tapped on notification - could navigate to tasks view
        completionHandler()
    }
}
