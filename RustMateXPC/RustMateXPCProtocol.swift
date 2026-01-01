//
//  RustMateXPCProtocol.swift
//  RustMateXPC
//
//  XPC Protocol for RustMate - defines all operations that the main app can request from the XPC Service
//

import Foundation

@objc protocol RustMateXPCProtocol {
    // MARK: - Environment & Validation

    /// Ping the service to verify connectivity
    func ping(reply: @escaping (Bool) -> Void)

    /// Set cargo bookmark data for security-scoped resource access
    func setCargoBookmark(
        _ bookmarkData: Data?,
        reply: @escaping (Bool) -> Void
    )

    /// Validate that rustup is accessible and executable
    func validateEnvironment(
        rustupPath: String?,
        reply: @escaping (Data?, Error?) -> Void
    )

    // MARK: - Toolchain Operations

    /// List all installed toolchains
    func listToolchains(reply: @escaping (Data?, Error?) -> Void)

    /// Install a toolchain (stable, beta, nightly, or custom)
    func installToolchain(
        name: String,
        reply: @escaping (Data) -> Void
    )

    /// Uninstall a toolchain
    func uninstallToolchain(
        name: String,
        reply: @escaping (Data) -> Void
    )

    /// Set a toolchain as the default
    func setDefaultToolchain(
        name: String,
        reply: @escaping (Data) -> Void
    )

    /// Update all installed toolchains
    func updateAllToolchains(reply: @escaping (Data) -> Void)

    /// Update a specific toolchain
    func updateToolchain(
        name: String,
        reply: @escaping (Data) -> Void
    )

    // MARK: - Component Operations

    /// List all components for a toolchain
    func listComponents(
        toolchainName: String,
        reply: @escaping (Data?, Error?) -> Void
    )

    /// Add a component to a toolchain
    func addComponent(
        componentName: String,
        toolchainName: String,
        reply: @escaping (Data) -> Void
    )

    /// Remove a component from a toolchain
    func removeComponent(
        componentName: String,
        toolchainName: String,
        reply: @escaping (Data) -> Void
    )

    // MARK: - Target Operations

    /// List all targets for a toolchain
    func listTargets(
        toolchainName: String,
        reply: @escaping (Data?, Error?) -> Void
    )

    /// Add a target to a toolchain
    func addTarget(
        targetTriple: String,
        toolchainName: String,
        reply: @escaping (Data) -> Void
    )

    /// Remove a target from a toolchain
    func removeTarget(
        targetTriple: String,
        toolchainName: String,
        reply: @escaping (Data) -> Void
    )

    // MARK: - Project Context Operations

    /// Get project context (active toolchain and reason)
    func getProjectContext(
        projectPath: String,
        reply: @escaping (Data?, Error?) -> Void
    )

    /// Set project toolchain override
    func setProjectOverride(
        projectPath: String,
        toolchainName: String,
        mode: String,
        reply: @escaping (Data) -> Void
    )

    /// Clear project toolchain override
    func clearProjectOverride(
        projectPath: String,
        mode: String,
        reply: @escaping (Data) -> Void
    )

    // MARK: - Task Management

    /// Cancel a running task (best effort)
    func cancelTask(
        taskID: String,
        reply: @escaping (Bool) -> Void
    )
}
