//
//  TargetParser.swift
//  RustMate
//
//  Parser for rustup target list output
//

import Foundation

struct TargetParser {
    /// Parse output from `rustup target list --toolchain <name>`
    ///
    /// Expected format:
    /// ```
    /// aarch64-apple-darwin (installed)
    /// aarch64-apple-ios
    /// aarch64-linux-android
    /// wasm32-unknown-unknown
    /// x86_64-apple-darwin (installed)
    /// x86_64-pc-windows-msvc
    /// ```
    ///
    /// - Parameter output: Raw stdout from rustup target list
    /// - Returns: Array of TargetInfo representing available targets
    static func parse(_ output: String) -> [TargetInfo] {
        let lines = output.split(separator: "\n").map(String.init)
        var targets: [TargetInfo] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Check if installed
            let isInstalled = trimmed.contains("(installed)")

            // Extract target triple (everything before " (installed)" or end of line)
            var triple = trimmed
            if let parenIndex = triple.firstIndex(of: "(") {
                triple = String(triple[..<parenIndex]).trimmingCharacters(in: .whitespaces)
            }

            // Parse target triple components
            let components = parseTriple(triple)

            targets.append(TargetInfo(
                triple: triple,
                arch: components.arch,
                vendor: components.vendor,
                os: components.os,
                env: components.env,
                isInstalled: isInstalled,
                description: descriptionForTarget(triple)
            ))
        }

        return targets
    }

    /// Parse target triple into components (arch-vendor-os-env)
    private static func parseTriple(_ triple: String) -> (arch: String?, vendor: String?, os: String?, env: String?) {
        let parts = triple.split(separator: "-").map(String.init)

        guard parts.count >= 2 else {
            return (nil, nil, nil, nil)
        }

        let arch = parts[0]

        // Handle different triple formats
        switch parts.count {
        case 2:
            // arch-os (e.g., wasm32-wasi)
            return (arch, nil, parts[1], nil)
        case 3:
            // arch-vendor-os (e.g., x86_64-apple-darwin)
            return (arch, parts[1], parts[2], nil)
        case 4:
            // arch-vendor-os-env (e.g., x86_64-pc-windows-msvc)
            return (arch, parts[1], parts[2], parts[3])
        default:
            return (arch, nil, nil, nil)
        }
    }

    /// Provide human-readable description for common targets
    private static func descriptionForTarget(_ triple: String) -> String? {
        let lower = triple.lowercased()

        // WebAssembly
        if lower.contains("wasm32-unknown-unknown") {
            return "WebAssembly (browser/WASI)"
        } else if lower.contains("wasm32-wasi") {
            return "WebAssembly System Interface"
        }

        // Apple platforms
        else if lower.contains("aarch64-apple-darwin") {
            return "macOS on Apple Silicon (M1/M2/M3)"
        } else if lower.contains("x86_64-apple-darwin") {
            return "macOS on Intel"
        } else if lower.contains("aarch64-apple-ios") {
            return "iOS on ARM64"
        } else if lower.contains("x86_64-apple-ios") {
            return "iOS Simulator"
        }

        // Linux
        else if lower.contains("x86_64-unknown-linux-gnu") {
            return "Linux x86_64 (GNU)"
        } else if lower.contains("aarch64-unknown-linux-gnu") {
            return "Linux ARM64 (GNU)"
        } else if lower.contains("x86_64-unknown-linux-musl") {
            return "Linux x86_64 (musl, static linking)"
        } else if lower.contains("aarch64-unknown-linux-musl") {
            return "Linux ARM64 (musl, static linking)"
        }

        // Windows
        else if lower.contains("x86_64-pc-windows-msvc") {
            return "Windows x86_64 (MSVC)"
        } else if lower.contains("x86_64-pc-windows-gnu") {
            return "Windows x86_64 (MinGW)"
        } else if lower.contains("i686-pc-windows-msvc") {
            return "Windows 32-bit (MSVC)"
        }

        // Android
        else if lower.contains("aarch64-linux-android") {
            return "Android ARM64"
        } else if lower.contains("armv7-linux-androideabi") {
            return "Android ARMv7"
        } else if lower.contains("x86_64-linux-android") {
            return "Android x86_64"
        }

        // Embedded/Bare Metal
        else if lower.contains("thumbv") {
            return "ARM Cortex-M (embedded)"
        } else if lower.contains("riscv") {
            return "RISC-V architecture"
        }

        return nil
    }
}
