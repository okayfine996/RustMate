//
//  DateFormatters.swift
//  RustMate
//
//  Shared date and time formatting utilities
//  Extracts common formatting logic used across views
//

import Foundation

/// Shared date and time formatting utilities
enum DateFormatters {

    // MARK: - Duration Formatting

    /// Format a time interval as a compact duration string
    /// - Parameter duration: Time interval in seconds
    /// - Returns: Formatted string (e.g., "8s", "2m 30s")
    static func formatDuration(_ duration: TimeInterval, style: DurationStyle = .compact) -> String {
        if duration < 60 {
            switch style {
            case .compact:
                return String(format: "%.0fs", duration)
            case .verbose:
                return String(format: "%.0f seconds", duration)
            }
        } else {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))

            switch style {
            case .compact:
                return "\(minutes)m \(seconds)s"
            case .verbose:
                return "\(minutes) minutes \(seconds) seconds"
            }
        }
    }

    /// Duration formatting style
    enum DurationStyle {
        case compact    // "2m 30s"
        case verbose    // "2 minutes 30 seconds"
    }

    // MARK: - Time Formatting

    /// Format a date as a short time string
    /// - Parameter date: Date to format
    /// - Returns: Formatted time string (e.g., "10:30 AM")
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Format a date as a relative time string
    /// - Parameter date: Date to format
    /// - Returns: Relative time string (e.g., "2h ago", "just now")
    static func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Format elapsed time from a start date to now
    /// - Parameter startTime: Start date
    /// - Returns: Formatted elapsed time (e.g., "30s", "2m 15s")
    static func formatElapsed(from startTime: Date) -> String {
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < 60 {
            return String(format: "%.0fs", elapsed)
        } else {
            let minutes = Int(elapsed / 60)
            let seconds = Int(elapsed.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(seconds)s"
        }
    }

    // MARK: - Date Formatting

    /// Format a date as a full date and time string
    /// - Parameter date: Date to format
    /// - Returns: Formatted date string (e.g., "Jan 16, 2026 at 10:30 AM")
    static func formatFullDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Format a date as a short date string
    /// - Parameter date: Date to format
    /// - Returns: Formatted date string (e.g., "1/16/26")
    static func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
