//
//  ShowParser.swift
//  RustMate
//
//  Parser for rustup show output to extract project context
//

import Foundation

struct ShowParser {
    /// Parse output from `rustup show` to extract active toolchain and override source
    ///
    /// Supports both legacy and modern rustup output formats:
    ///
    /// Modern format (rustup 1.26+):
    /// ```
    /// active toolchain
    /// ----------------
    /// name: stable-aarch64-apple-darwin
    /// active because: it's the default toolchain
    /// ```
    ///
    /// Legacy format:
    /// ```
    /// stable-aarch64-apple-darwin (default)
    /// rustc 1.75.0 (82e1608df 2023-12-21)
    /// ```
    ///
    /// - Parameters:
    ///   - output: Raw stdout from rustup show
    ///   - projectPath: Project directory path for context
    /// - Returns: ProjectContextInfo with active toolchain and reason
    static func parse(_ output: String, projectPath: String) -> ProjectContextInfo {
        let lines = output.split(separator: "\n").map(String.init)

        var activeToolchain: String?
        var reason: ProjectContextInfo.ToolchainReason = .default
        var sourcePath: String?

        // Track if we're in the "active toolchain" section
        var inActiveSection = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Detect "active toolchain" section header
            if trimmed == "active toolchain" {
                inActiveSection = true
                continue
            }

            // Skip separator lines (all dashes)
            if !trimmed.isEmpty && trimmed.allSatisfy({ $0 == "-" }) {
                continue
            }

            // Modern format: Parse "name: toolchain-name"
            if inActiveSection && trimmed.starts(with: "name:") {
                let nameValue = trimmed
                    .replacingOccurrences(of: "name:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if !nameValue.isEmpty {
                    activeToolchain = nameValue
                }
                continue
            }

            // Modern format: Parse "active because:" to determine reason
            if inActiveSection && trimmed.starts(with: "active because:") {
                let reasonText = trimmed.lowercased()
                if reasonText.contains("default") {
                    reason = .default
                } else if reasonText.contains("environment") || reasonText.contains("rustup_toolchain") {
                    reason = .environment
                } else if reasonText.contains("directory override") {
                    reason = .override
                    // Try to extract path from reason text
                    if let path = extractPathFromReason(trimmed) {
                        sourcePath = path
                    }
                } else if reasonText.contains("overridden") {
                    // Check if it's a toolchain file
                    if reasonText.contains("rust-toolchain") {
                        reason = .toolchainFile
                        if let path = extractPathFromReason(trimmed) {
                            sourcePath = path
                        }
                    } else {
                        reason = .override
                    }
                }
                continue
            }

            guard !trimmed.isEmpty else { continue }

            // Legacy format: Look for toolchain line with markers
            if trimmed.contains("(default)") {
                if let toolchainName = extractToolchainName(from: trimmed) {
                    activeToolchain = toolchainName
                    reason = .default
                }
            } else if trimmed.contains("(overridden by") {
                if let toolchainName = extractToolchainName(from: trimmed) {
                    activeToolchain = toolchainName

                    if let pathMatch = extractOverridePath(from: trimmed) {
                        sourcePath = pathMatch

                        if pathMatch.contains("rust-toolchain") {
                            reason = .toolchainFile
                        } else {
                            reason = .override
                        }
                    }
                }
            } else if trimmed.contains("(directory override") {
                if let toolchainName = extractToolchainName(from: trimmed) {
                    activeToolchain = toolchainName
                    reason = .override

                    if let pathMatch = extractOverridePath(from: trimmed) {
                        sourcePath = pathMatch
                    }
                }
            }
        }

        return ProjectContextInfo(
            projectPath: projectPath,
            activeToolchain: activeToolchain ?? "unknown",
            reason: reason,
            sourcePath: sourcePath
        )
    }

    /// Extract toolchain name from a line (legacy format)
    private static func extractToolchainName(from line: String) -> String? {
        var cleaned = line

        // Remove markers
        let markers = ["(default)", "(overridden by", "(directory override"]
        for marker in markers {
            if let range = cleaned.range(of: marker) {
                cleaned = String(cleaned[..<range.lowerBound])
            }
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespaces)

        // Toolchain name is typically the first word/token
        let components = cleaned.split(separator: " ")
        guard let first = components.first else { return nil }

        let name = String(first)

        // Validate it looks like a toolchain name
        if name.contains("-") || name == "stable" || name == "beta" || name == "nightly" {
            return name
        }

        return nil
    }

    /// Extract override path from parentheses (legacy format)
    private static func extractOverridePath(from line: String) -> String? {
        // Look for path in single quotes within parentheses
        // Pattern: (overridden by '/path/to/file')

        if let startQuote = line.firstIndex(of: "'"),
           let endQuote = line[line.index(after: startQuote)...].firstIndex(of: "'") {
            let path = String(line[line.index(after: startQuote)..<endQuote])
            return path
        }

        // Try without quotes
        if let startParen = line.firstIndex(of: "("),
           let endParen = line.firstIndex(of: ")") {
            let content = String(line[line.index(after: startParen)..<endParen])

            // Extract path after "overridden by"
            if let byIndex = content.range(of: "overridden by")?.upperBound {
                let path = content[byIndex...].trimmingCharacters(in: .whitespaces)
                return path
            }
        }

        return nil
    }

    /// Extract path from "active because:" line (modern format)
    private static func extractPathFromReason(_ line: String) -> String? {
        // Look for path patterns in the reason text
        // Example: "active because: overridden by '/path/to/rust-toolchain.toml'"

        if let startQuote = line.firstIndex(of: "'"),
           let endQuote = line[line.index(after: startQuote)...].firstIndex(of: "'") {
            let path = String(line[line.index(after: startQuote)..<endQuote])
            return path
        }

        // Try to extract path without quotes
        let components = line.components(separatedBy: ":")
        if components.count > 1 {
            let reasonPart = components[1...].joined(separator: ":")
            // Look for file path patterns
            if let pathRange = reasonPart.range(of: "/[^ ]+", options: .regularExpression) {
                return String(reasonPart[pathRange])
            }
        }

        return nil
    }
}
