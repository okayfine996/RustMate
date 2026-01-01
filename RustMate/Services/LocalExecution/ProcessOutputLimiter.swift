//
//  ProcessOutputLimiter.swift
//  RustMate
//
//  Enforces output truncation for summary-only results
//

import Foundation

/// Enforces output size limits to prevent memory/UX issues
struct ProcessOutputLimiter {
    /// Maximum bytes to capture from stdout (32 KB)
    static let maxStdoutBytes = 32 * 1024

    /// Maximum bytes to capture from stderr (32 KB)
    static let maxStderrBytes = 32 * 1024

    /// Truncates output to the maximum allowed size
    /// Appends a truncation notice if output was truncated
    static func truncate(_ data: Data, maxBytes: Int, streamName: String) -> String {
        let truncated = data.prefix(maxBytes)
        let output = String(data: truncated, encoding: .utf8) ?? ""

        if data.count > maxBytes {
            let truncatedKB = maxBytes / 1024
            let originalKB = data.count / 1024
            return """
            \(output)

            ... [\(streamName) truncated: showing first \(truncatedKB) KB of \(originalKB) KB]
            """
        }

        return output
    }

    /// Truncates stdout with appropriate limits
    static func truncateStdout(_ data: Data) -> String {
        return truncate(data, maxBytes: maxStdoutBytes, streamName: "stdout")
    }

    /// Truncates stderr with appropriate limits
    static func truncateStderr(_ data: Data) -> String {
        return truncate(data, maxBytes: maxStderrBytes, streamName: "stderr")
    }
}
