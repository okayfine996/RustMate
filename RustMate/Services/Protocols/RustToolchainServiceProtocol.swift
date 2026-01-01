//
//  RustToolchainServiceProtocol.swift
//  RustMate
//
//  Protocol for toolchain management service
//

import Foundation

protocol RustToolchainServiceProtocol: Sendable {
    // MARK: - Toolchain Operations
    func listToolchains() async throws -> [ToolchainInfo]
    func installToolchain(name: String) async throws -> TaskResult
    func uninstallToolchain(name: String) async throws -> TaskResult
    func setDefaultToolchain(name: String) async throws -> TaskResult
    func updateAllToolchains() async throws -> TaskResult
    func updateToolchain(name: String) async throws -> TaskResult

    // MARK: - Component Operations
    func listComponents(toolchainName: String) async throws -> [ComponentInfo]
    func addComponent(componentName: String, toolchainName: String) async throws -> TaskResult
    func removeComponent(componentName: String, toolchainName: String) async throws -> TaskResult

    // MARK: - Target Operations
    func listTargets(toolchainName: String) async throws -> [TargetInfo]
    func addTarget(targetTriple: String, toolchainName: String) async throws -> TaskResult
    func removeTarget(targetTriple: String, toolchainName: String) async throws -> TaskResult
}
