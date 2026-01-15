//
//  ToolchainParser.swift
//  RustMate
//
//  Parser for `rustup toolchain list` command output
//

import Foundation

struct ToolchainParser {

    /// Parse the output of `rustup toolchain list` command
    ///
    /// Expected format:
    /// ```
    /// stable-aarch64-apple-darwin (default)
    /// beta-aarch64-apple-darwin
    /// nightly-aarch64-apple-darwin
    /// 1.75.0-aarch64-apple-darwin
    /// ```
    ///
    /// - Parameter output: The stdout from `rustup toolchain list`
    /// - Returns: Array of ToolchainInfo parsed from the output
    static func parse(_ output: String) -> [ToolchainInfo] {
        let lines = output.split(separator: "\n").map(String.init)
        var toolchains: [ToolchainInfo] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Check if this is the default toolchain
            // Matches patterns like "(default)", "default", "(active, default)"
            let isDefault = trimmed.contains("(default)") ||
                           trimmed.contains("default") ||
                           trimmed.hasSuffix("default")

            // Extract toolchain name (remove markers like "(default)", "(active)", etc.)
            var name = trimmed
            if let parenIndex = name.firstIndex(of: "(") {
                name = String(name[..<parenIndex]).trimmingCharacters(in: .whitespaces)
            }

            // Extract host triple (e.g., "aarch64-apple-darwin")
            // Toolchain names follow pattern: <channel>-<arch>-<vendor>-<os>
            // Examples: stable-aarch64-apple-darwin, nightly-x86_64-pc-windows-msvc
            var host: String?
            let components = name.split(separator: "-")
            if components.count >= 3 {
                // Host is typically the last 3 components (arch-vendor-os)
                host = components.suffix(3).joined(separator: "-")
            }

            toolchains.append(ToolchainInfo(
                name: name,
                version: nil, // Version not available in list output
                isDefault: isDefault,
                installDate: nil,
                host: host
            ))
        }

        return toolchains
    }

    /// Validate if a string looks like valid rustup toolchain list output
    ///
    /// - Parameter output: The string to validate
    /// - Returns: True if output appears to be valid toolchain list format
    static func isValidOutput(_ output: String) -> Bool {
        guard !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        // Valid output should have at least one line that looks like a toolchain name
        // Pattern: word-word-word or word-word-word-word
        let pattern = #"^[\w\d\.]+-[\w\d]+-[\w\d]+"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])

        for line in output.split(separator: "\n") {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)
            if let parenIndex = trimmed.firstIndex(of: "(") {
                let nameOnly = String(trimmed[..<parenIndex]).trimmingCharacters(in: .whitespaces)
                if regex?.firstMatch(in: nameOnly, range: NSRange(nameOnly.startIndex..., in: nameOnly)) != nil {
                    return true
                }
            } else if regex?.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil {
                return true
            }
        }

        return false
    }
}
