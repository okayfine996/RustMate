//
//  MockToolchainService.swift
//  RustMate
//
//  Mock implementation for previews and tests
//

import Foundation

class MockToolchainService: RustToolchainServiceProtocol {

    // MARK: - Test Configuration

    var mockToolchains: [ToolchainInfo] = [
        ToolchainInfo(
            id: UUID(),
            name: "stable-aarch64-apple-darwin",
            version: "1.75.0",
            isDefault: true,
            installDate: Date().addingTimeInterval(-86400 * 30),
            host: "aarch64-apple-darwin"
        ),
        ToolchainInfo(
            id: UUID(),
            name: "nightly-aarch64-apple-darwin",
            version: "1.77.0-nightly",
            isDefault: false,
            installDate: Date().addingTimeInterval(-86400 * 7),
            host: "aarch64-apple-darwin"
        ),
        ToolchainInfo(
            id: UUID(),
            name: "beta-aarch64-apple-darwin",
            version: "1.76.0-beta",
            isDefault: false,
            installDate: Date().addingTimeInterval(-86400 * 14),
            host: "aarch64-apple-darwin"
        )
    ]

    var switchDelay: TimeInterval = 0.5
    var shouldFailSwitch: Bool = false
    var shouldFailLoad: Bool = false

    // MARK: - Toolchain Operations

    func listToolchains() async throws -> [ToolchainInfo] {
        if shouldFailLoad {
            throw NSError(
                domain: "MockToolchainService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Mock load failure"]
            )
        }
        return mockToolchains
    }

    func installToolchain(name: String) async throws -> TaskResult {
        try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate 2s operation
        return TaskResult(
            taskId: UUID(),
            toolchainName: name,
            operation: "install",
            status: .success,
            startTime: Date().addingTimeInterval(-2),
            endTime: Date(),
            exitCode: 0,
            stdoutSnippet: "info: syncing channel updates for '\(name)'\ninfo: downloading component 'rust-std'\ninfo: installing component 'rust-std'",
            stderrSnippet: nil,
            errorMessage: nil
        )
    }

    func uninstallToolchain(name: String) async throws -> TaskResult {
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate 1s operation
        return TaskResult(
            taskId: UUID(),
            toolchainName: name,
            operation: "uninstall",
            status: .success,
            startTime: Date().addingTimeInterval(-1),
            endTime: Date(),
            exitCode: 0,
            stdoutSnippet: "info: uninstalling toolchain '\(name)'",
            stderrSnippet: nil,
            errorMessage: nil
        )
    }

    func setDefaultToolchain(name: String) async throws -> TaskResult {
        try await Task.sleep(nanoseconds: UInt64(switchDelay * 1_000_000_000))

        if shouldFailSwitch {
            return TaskResult(
                taskId: UUID(),
                toolchainName: name,
                operation: "setDefault",
                status: .failed,
                startTime: Date().addingTimeInterval(-switchDelay),
                endTime: Date(),
                exitCode: 1,
                stdoutSnippet: nil,
                stderrSnippet: "error: failed to set default toolchain",
                errorMessage: "Mock switch failure"
            )
        }

        // Update mock toolchains to reflect new default
        mockToolchains = mockToolchains.map { toolchain in
            ToolchainInfo(
                id: toolchain.id,
                name: toolchain.name,
                version: toolchain.version,
                isDefault: toolchain.name == name,
                installDate: toolchain.installDate,
                host: toolchain.host
            )
        }

        return TaskResult(
            taskId: UUID(),
            toolchainName: name,
            operation: "setDefault",
            status: .success,
            startTime: Date().addingTimeInterval(-switchDelay),
            endTime: Date(),
            exitCode: 0,
            stdoutSnippet: "info: default toolchain set to '\(name)'",
            stderrSnippet: nil,
            errorMessage: nil
        )
    }

    func updateAllToolchains() async throws -> TaskResult {
        try await Task.sleep(nanoseconds: 3_000_000_000) // Simulate 3s operation
        return TaskResult(
            taskId: UUID(),
            toolchainName: nil,
            operation: "updateAll",
            status: .success,
            startTime: Date().addingTimeInterval(-3),
            endTime: Date(),
            exitCode: 0,
            stdoutSnippet: "info: checking for self-updates\ninfo: updating 'stable-aarch64-apple-darwin'\ninfo: updating 'nightly-aarch64-apple-darwin'",
            stderrSnippet: nil,
            errorMessage: nil
        )
    }

    func updateToolchain(name: String) async throws -> TaskResult {
        try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate 2s operation
        return TaskResult(
            taskId: UUID(),
            toolchainName: name,
            operation: "update",
            status: .success,
            startTime: Date().addingTimeInterval(-2),
            endTime: Date(),
            exitCode: 0,
            stdoutSnippet: "info: updating '\(name)'\ninfo: downloading component 'rust-std'",
            stderrSnippet: nil,
            errorMessage: nil
        )
    }

    // MARK: - Component Operations

    func listComponents(toolchainName: String) async throws -> [ComponentInfo] {
        return [
            ComponentInfo(
                id: UUID(),
                name: "rustfmt",
                toolchainName: toolchainName,
                isInstalled: true,
                description: "The Rust code formatter"
            ),
            ComponentInfo(
                id: UUID(),
                name: "clippy",
                toolchainName: toolchainName,
                isInstalled: true,
                description: "Rust linter"
            ),
            ComponentInfo(
                id: UUID(),
                name: "rust-src",
                toolchainName: toolchainName,
                isInstalled: false,
                description: "Rust source code"
            ),
            ComponentInfo(
                id: UUID(),
                name: "rust-analyzer",
                toolchainName: toolchainName,
                isInstalled: false,
                description: "Rust language server"
            )
        ]
    }

    func addComponent(componentName: String, toolchainName: String) async throws -> TaskResult {
        try await Task.sleep(nanoseconds: 1_500_000_000) // Simulate 1.5s operation
        return TaskResult(
            taskId: UUID(),
            toolchainName: toolchainName,
            operation: "addComponent",
            status: .success,
            startTime: Date().addingTimeInterval(-1.5),
            endTime: Date(),
            exitCode: 0,
            stdoutSnippet: "info: downloading component '\(componentName)'\ninfo: installing component '\(componentName)'",
            stderrSnippet: nil,
            errorMessage: nil
        )
    }

    func removeComponent(componentName: String, toolchainName: String) async throws -> TaskResult {
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate 1s operation
        return TaskResult(
            taskId: UUID(),
            toolchainName: toolchainName,
            operation: "removeComponent",
            status: .success,
            startTime: Date().addingTimeInterval(-1),
            endTime: Date(),
            exitCode: 0,
            stdoutSnippet: "info: removing component '\(componentName)'",
            stderrSnippet: nil,
            errorMessage: nil
        )
    }

    // MARK: - Target Operations

    func listTargets(toolchainName: String) async throws -> [TargetInfo] {
        return [
            TargetInfo(
                id: UUID(),
                triple: "aarch64-apple-darwin",
                toolchainName: toolchainName,
                isInstalled: true,
                description: "64-bit ARM macOS"
            ),
            TargetInfo(
                id: UUID(),
                triple: "x86_64-apple-darwin",
                toolchainName: toolchainName,
                isInstalled: false,
                description: "64-bit Intel macOS"
            ),
            TargetInfo(
                id: UUID(),
                triple: "wasm32-unknown-unknown",
                toolchainName: toolchainName,
                isInstalled: false,
                description: "WebAssembly"
            )
        ]
    }

    func addTarget(targetTriple: String, toolchainName: String) async throws -> TaskResult {
        try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate 2s operation
        return TaskResult(
            taskId: UUID(),
            toolchainName: toolchainName,
            operation: "addTarget",
            status: .success,
            startTime: Date().addingTimeInterval(-2),
            endTime: Date(),
            exitCode: 0,
            stdoutSnippet: "info: downloading component 'rust-std' for '\(targetTriple)'\ninfo: installing component 'rust-std'",
            stderrSnippet: nil,
            errorMessage: nil
        )
    }

    func removeTarget(targetTriple: String, toolchainName: String) async throws -> TaskResult {
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate 1s operation
        return TaskResult(
            taskId: UUID(),
            toolchainName: toolchainName,
            operation: "removeTarget",
            status: .success,
            startTime: Date().addingTimeInterval(-1),
            endTime: Date(),
            exitCode: 0,
            stdoutSnippet: "info: removing component 'rust-std' for '\(targetTriple)'",
            stderrSnippet: nil,
            errorMessage: nil
        )
    }
}
