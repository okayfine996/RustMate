//
//  ComponentParser.swift
//  RustMate
//
//  Parser for rustup component list output
//

import Foundation

struct ComponentParser {
    /// Parse output from `rustup component list --toolchain <name>`
    ///
    /// Expected format:
    /// ```
    /// cargo-x86_64-apple-darwin (installed)
    /// clippy-x86_64-apple-darwin (installed)
    /// llvm-tools-preview-x86_64-apple-darwin
    /// rust-analysis-x86_64-apple-darwin
    /// rust-docs-x86_64-apple-darwin (installed)
    /// rust-src (installed)
    /// rustc-x86_64-apple-darwin (installed)
    /// rustfmt-x86_64-apple-darwin (installed)
    /// ```
    ///
    /// - Parameter output: Raw stdout from rustup component list
    /// - Returns: Array of ComponentInfo representing available components
    static func parse(_ output: String) -> [ComponentInfo] {
        let lines = output.split(separator: "\n").map(String.init)
        var components: [ComponentInfo] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Check if installed
            let isInstalled = trimmed.contains("(installed)")

            // Extract component name (everything before " (installed)" or end of line)
            var name = trimmed
            if let parenIndex = name.firstIndex(of: "(") {
                name = String(name[..<parenIndex]).trimmingCharacters(in: .whitespaces)
            }

            // Determine component type based on common patterns
            let componentType = determineComponentType(name)

            components.append(ComponentInfo(
                name: name,
                displayName: cleanDisplayName(name),
                toolchainName: nil, // Will be set by caller
                isInstalled: isInstalled,
                componentType: componentType,
                description: descriptionForComponent(name)
            ))
        }

        return components
    }

    /// Determine component type based on name patterns
    private static func determineComponentType(_ name: String) -> ComponentInfo.ComponentType {
        let lowercaseName = name.lowercased()

        if lowercaseName.contains("rust-src") {
            return .rustSrc
        } else if lowercaseName.contains("rustfmt") {
            return .rustfmt
        } else if lowercaseName.contains("clippy") {
            return .clippy
        } else if lowercaseName.contains("llvm-tools") {
            return .llvmTools
        } else if lowercaseName.contains("rust-docs") {
            return .rustDocs
        } else if lowercaseName.contains("rust-analyzer") || lowercaseName.contains("rust-analysis") {
            return .rustAnalyzer
        } else {
            return .other
        }
    }

    /// Clean display name by removing host triple suffix
    private static func cleanDisplayName(_ name: String) -> String {
        // Remove common host triple patterns like "-x86_64-apple-darwin"
        let hostPatterns = [
            "-x86_64-apple-darwin",
            "-aarch64-apple-darwin",
            "-x86_64-unknown-linux-gnu",
            "-x86_64-pc-windows-msvc"
        ]

        var cleanName = name
        for pattern in hostPatterns {
            if let range = cleanName.range(of: pattern) {
                cleanName.removeSubrange(range)
            }
        }

        return cleanName
    }

    /// Provide human-readable description for common components
    private static func descriptionForComponent(_ name: String) -> String? {
        let lowercaseName = name.lowercased()

        if lowercaseName.contains("rust-src") {
            return "Rust standard library source code (for IDE features)"
        } else if lowercaseName.contains("rustfmt") {
            return "Code formatter for Rust source code"
        } else if lowercaseName.contains("clippy") {
            return "Linting tool to catch common mistakes"
        } else if lowercaseName.contains("llvm-tools") {
            return "LLVM tools (profiler, coverage, etc.)"
        } else if lowercaseName.contains("rust-docs") {
            return "Offline documentation for Rust standard library"
        } else if lowercaseName.contains("rust-analyzer") || lowercaseName.contains("rust-analysis") {
            return "Compiler metadata for IDE support"
        } else {
            return nil
        }
    }
}
