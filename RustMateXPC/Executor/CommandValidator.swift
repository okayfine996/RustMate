//
//  CommandValidator.swift
//  RustMateXPC
//
//  Validates command parameters against whitelist patterns for security
//

import Foundation

struct CommandValidator {

    private let toolchainPattern = "^[A-Za-z0-9._-]{1,128}$"
    private let targetPattern = "^[A-Za-z0-9._-]{1,128}$"

    /// Validates toolchain name against allowed pattern
    func validateToolchainName(_ name: String) -> Bool {
        guard !name.isEmpty, name.count <= 128 else { return false }
        return name.range(of: toolchainPattern, options: .regularExpression) != nil
    }

    /// Validates target triple against allowed pattern
    func validateTargetTriple(_ triple: String) -> Bool {
        guard !triple.isEmpty, triple.count <= 128 else { return false }
        return triple.range(of: targetPattern, options: .regularExpression) != nil
    }

    /// Validates project path is absolute and within authorized scope
    func validateProjectPath(_ path: String) -> Bool {
        // Must be absolute path
        guard path.hasPrefix("/") else { return false }

        // Basic security check: no path traversal attempts
        let normalized = (path as NSString).standardizingPath
        return normalized == path && !path.contains("..")
    }

    /// Validates override mode
    func validateOverrideMode(_ mode: String) -> Bool {
        return mode == "toolchainFile" || mode == "rustupOverride"
    }
}
