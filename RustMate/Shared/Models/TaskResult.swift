import Foundation
import SwiftUI

/// Represents the execution status of a rustup operation
struct TaskResult: Codable, Sendable {
    let taskId: UUID?
    let toolchainName: String?
    let operation: String?
    let status: TaskRecord.TaskStatus
    let startTime: Date?
    let endTime: Date?
    let exitCode: Int
    let stdoutSnippet: String?
    let stderrSnippet: String?
    let errorMessage: String?

    init(
        taskId: UUID? = nil,
        toolchainName: String? = nil,
        operation: String? = nil,
        status: TaskRecord.TaskStatus = .success,
        startTime: Date? = nil,
        endTime: Date? = nil,
        exitCode: Int,
        stdoutSnippet: String? = nil,
        stderrSnippet: String? = nil,
        errorMessage: String? = nil
    ) {
        self.taskId = taskId
        self.toolchainName = toolchainName
        self.operation = operation
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.exitCode = exitCode
        self.stdoutSnippet = stdoutSnippet
        self.stderrSnippet = stderrSnippet
        self.errorMessage = errorMessage
    }

    /// Convert to TaskRecord for tracking
    var taskRecord: TaskRecord? {
        guard let taskId = taskId, let operation = operation else { return nil }

        return TaskRecord(
            id: taskId,
            operation: operation,
            target: toolchainName,
            status: status,
            startTime: startTime ?? Date(),
            endTime: endTime,
            exitCode: exitCode,
            stdoutSnippet: stdoutSnippet,
            stderrSnippet: stderrSnippet,
            errorMessage: errorMessage,
            suggestedFix: Self.suggestFix(for: stderrSnippet ?? "")
        )
    }

    /// Common error patterns and suggested fixes
    func suggestFix() -> [String] {
        var suggestions: [String] = []

        if let stderr = stderrSnippet {
            if stderr.contains("could not download") || stderr.contains("network") {
                suggestions.append("Check your internet connection or try again later")
            }
            if stderr.contains("permission denied") {
                suggestions.append("Grant access to ~/.cargo/bin in Settings")
            }
            if stderr.contains("already installed") {
                suggestions.append("Toolchain is already installed. Try updating instead.")
            }
            if stderr.contains("could not find") {
                suggestions.append("Toolchain name may be incorrect. Check spelling.")
            }
        }

        return suggestions
    }

    /// Common error patterns and suggested fixes
    static func suggestFix(for stderr: String) -> String? {
        if stderr.contains("could not download") || stderr.contains("network") {
            return "Check your internet connection or try again later"
        } else if stderr.contains("permission denied") {
            return "Grant access to ~/.cargo/bin in Settings"
        } else if stderr.contains("already installed") {
            return "Toolchain is already installed. Try updating instead."
        } else if stderr.contains("could not find") {
            return "Toolchain name may be incorrect. Check spelling."
        }
        return nil
    }
}

/// Represents a task record with full metadata
struct TaskRecord: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let operation: String
    let target: String?
    let status: TaskStatus
    let startTime: Date
    let endTime: Date?
    let exitCode: Int?
    let stdoutSnippet: String?
    let stderrSnippet: String?
    let errorMessage: String?
    let suggestedFix: String?

    init(
        id: UUID = UUID(),
        operation: String,
        target: String? = nil,
        status: TaskStatus,
        startTime: Date = Date(),
        endTime: Date? = nil,
        exitCode: Int? = nil,
        stdoutSnippet: String? = nil,
        stderrSnippet: String? = nil,
        errorMessage: String? = nil,
        suggestedFix: String? = nil
    ) {
        self.id = id
        self.operation = operation
        self.target = target
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.exitCode = exitCode
        self.stdoutSnippet = stdoutSnippet
        self.stderrSnippet = stderrSnippet
        self.errorMessage = errorMessage
        self.suggestedFix = suggestedFix
    }

    enum TaskStatus: String, Codable, Sendable, Hashable {
        case running
        case success
        case failed
        case cancelled

        var icon: String {
            switch self {
            case .running: return "arrow.clockwise"
            case .success: return "checkmark.circle"
            case .failed: return "xmark.circle"
            case .cancelled: return "stop.circle"
            }
        }

        var color: Color {
            switch self {
            case .running: return .blue
            case .success: return .green
            case .failed: return .red
            case .cancelled: return .orange
            }
        }
    }

    /// Computed property for display duration
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}
