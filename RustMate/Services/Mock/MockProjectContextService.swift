//
//  MockProjectContextService.swift
//  RustMate
//
//  Mock implementation for previews and tests
//

import Foundation

class MockProjectContextService: ProjectContextServiceProtocol {

    func getProjectContext(projectPath: String) async throws -> ProjectContextInfo {
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate 0.5s operation

        // Simulate different scenarios based on path
        if projectPath.contains("rust-toolchain") {
            return ProjectContextInfo(
                projectPath: projectPath,
                activeToolchain: "nightly-aarch64-apple-darwin",
                reason: .toolchainFile,
                sourcePath: "\(projectPath)/rust-toolchain.toml"
            )
        } else if projectPath.contains("override") {
            return ProjectContextInfo(
                projectPath: projectPath,
                activeToolchain: "beta-aarch64-apple-darwin",
                reason: .override,
                sourcePath: "rustup override"
            )
        } else {
            return ProjectContextInfo(
                projectPath: projectPath,
                activeToolchain: "stable-aarch64-apple-darwin",
                reason: .default,
                sourcePath: nil
            )
        }
    }

    func setProjectOverride(projectPath: String, toolchainName: String, mode: String) async throws -> TaskResult {
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate 1s operation

        return TaskResult(
            taskId: UUID(),
            toolchainName: toolchainName,
            operation: "setProjectOverride",
            status: .success,
            startTime: Date().addingTimeInterval(-1),
            endTime: Date(),
            exitCode: 0,
            stdoutSnippet: mode == "toolchainFile"
                ? "info: created '\(projectPath)/rust-toolchain.toml' with toolchain '\(toolchainName)'"
                : "info: override toolchain for '\(projectPath)' set to '\(toolchainName)'",
            stderrSnippet: nil,
            errorMessage: nil
        )
    }

    func clearProjectOverride(projectPath: String, mode: String) async throws -> TaskResult {
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate 0.5s operation

        return TaskResult(
            taskId: UUID(),
            toolchainName: nil,
            operation: "clearProjectOverride",
            status: .success,
            startTime: Date().addingTimeInterval(-0.5),
            endTime: Date(),
            exitCode: 0,
            stdoutSnippet: mode == "toolchainFile"
                ? "info: removed '\(projectPath)/rust-toolchain.toml'"
                : "info: override toolchain for '\(projectPath)' removed",
            stderrSnippet: nil,
            errorMessage: nil
        )
    }
}
