//
//  LocalProjectContextService.swift
//  RustMate
//
//  Local (in-app) implementation of ProjectContextServiceProtocol
//  Handles project toolchain context and overrides
//

import Foundation

/// Local implementation of ProjectContextServiceProtocol
class LocalProjectContextService: ProjectContextServiceProtocol {
    private let processRunner = ProcessRunner()
    private let authService: AuthorizationService
    private var settings: AppSettings

    init(settings: AppSettings = .default, authService: AuthorizationService = AuthorizationService()) {
        self.settings = settings
        self.authService = authService
    }

    func getProjectContext(projectPath: String) async throws -> ProjectContextInfo {
        let rustupPath = try RustupCommandResolver.resolveRustupPath(
            settings: settings,
            authService: authService
        )

        let env = try RustupCommandResolver.buildEnvironment(
            settings: settings,
            authService: authService
        )

        // Validate authorization - project context requires project access
        let resources = try authService.validateAndResolve(
            scope: .projectContext,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }

        // Execute rustup show in the project directory
        // Use ProcessRunner to execute on background thread
        let result = try await processRunner.runRustup(
            at: rustupPath,
            arguments: ["show"],
            environment: env,
            currentDirectoryURL: URL(fileURLWithPath: projectPath)
        )

        guard result.wasSuccessful else {
            throw RustupExecutionError.executionFailed(
                command: "rustup show",
                exitCode: result.exitCode,
                stderr: result.stderr,
                suggestedFix: "Check that rustup is working correctly and the project path is valid."
            )
        }

        // Parse output
        return ShowParser.parse(result.stdout, projectPath: projectPath)
    }

    func setProjectOverride(projectPath: String, toolchainName: String, mode: String) async throws -> TaskResult {
        let taskId = UUID()
        let startTime = Date()

        // Mode determines the override strategy
        let overrideStrategy = mode == "toolchainFile"
            ? AppSettings.OverrideStrategy.toolchainFile
            : AppSettings.OverrideStrategy.rustupOverride

        switch overrideStrategy {
        case .toolchainFile:
            return try await setOverrideViaToolchainFile(
                taskId: taskId,
                startTime: startTime,
                projectPath: projectPath,
                toolchainName: toolchainName
            )

        case .rustupOverride:
            return try await setOverrideViaRustupCommand(
                taskId: taskId,
                startTime: startTime,
                projectPath: projectPath,
                toolchainName: toolchainName
            )
        }
    }

    func clearProjectOverride(projectPath: String, mode: String) async throws -> TaskResult {
        let taskId = UUID()
        let startTime = Date()

        let overrideStrategy = mode == "toolchainFile"
            ? AppSettings.OverrideStrategy.toolchainFile
            : AppSettings.OverrideStrategy.rustupOverride

        switch overrideStrategy {
        case .toolchainFile:
            return try await clearOverrideViaToolchainFile(
                taskId: taskId,
                startTime: startTime,
                projectPath: projectPath
            )

        case .rustupOverride:
            return try await clearOverrideViaRustupCommand(
                taskId: taskId,
                startTime: startTime,
                projectPath: projectPath
            )
        }
    }

    // MARK: - Private Helpers

    private func setOverrideViaToolchainFile(
        taskId: UUID,
        startTime: Date,
        projectPath: String,
        toolchainName: String
    ) async throws -> TaskResult {
        // Validate project access authorization
        let resources = try authService.validateAndResolve(
            scope: .projectContext,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }

        let toolchainFilePath = URL(fileURLWithPath: projectPath)
            .appendingPathComponent("rust-toolchain.toml")
            .path

        // Write rust-toolchain.toml
        let content = """
        [toolchain]
        channel = "\(toolchainName)"
        """

        do {
            try content.write(toFile: toolchainFilePath, atomically: true, encoding: .utf8)

            return TaskResult(
                taskId: taskId,
                toolchainName: toolchainName,
                operation: "set-override-file",
                status: .success,
                startTime: startTime,
                endTime: Date(),
                exitCode: 0,
                stdoutSnippet: "Created \(toolchainFilePath)",
                stderrSnippet: nil,
                errorMessage: nil
            )
        } catch {
            return TaskResult(
                taskId: taskId,
                toolchainName: toolchainName,
                operation: "set-override-file",
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: 1,
                stdoutSnippet: nil,
                stderrSnippet: error.localizedDescription,
                errorMessage: "Failed to write rust-toolchain.toml: \(error.localizedDescription)"
            )
        }
    }

    private func clearOverrideViaToolchainFile(
        taskId: UUID,
        startTime: Date,
        projectPath: String
    ) async throws -> TaskResult {
        let resources = try authService.validateAndResolve(
            scope: .projectContext,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }

        let toolchainFilePath = URL(fileURLWithPath: projectPath)
            .appendingPathComponent("rust-toolchain.toml")
            .path

        do {
            if FileManager.default.fileExists(atPath: toolchainFilePath) {
                try FileManager.default.removeItem(atPath: toolchainFilePath)
            }

            return TaskResult(
                taskId: taskId,
                toolchainName: nil,
                operation: "clear-override-file",
                status: .success,
                startTime: startTime,
                endTime: Date(),
                exitCode: 0,
                stdoutSnippet: "Removed \(toolchainFilePath)",
                stderrSnippet: nil,
                errorMessage: nil
            )
        } catch {
            return TaskResult(
                taskId: taskId,
                toolchainName: nil,
                operation: "clear-override-file",
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: 1,
                stdoutSnippet: nil,
                stderrSnippet: error.localizedDescription,
                errorMessage: "Failed to remove rust-toolchain.toml: \(error.localizedDescription)"
            )
        }
    }

    private func setOverrideViaRustupCommand(
        taskId: UUID,
        startTime: Date,
        projectPath: String,
        toolchainName: String
    ) async throws -> TaskResult {
        let rustupPath = try RustupCommandResolver.resolveRustupPath(
            settings: settings,
            authService: authService
        )

        let env = try RustupCommandResolver.buildEnvironment(
            settings: settings,
            authService: authService
        )

        let resources = try authService.validateAndResolve(
            scope: .projectContext,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }

        let result = try await processRunner.runRustup(
            at: rustupPath,
            arguments: ["override", "set", toolchainName, "--path", projectPath],
            environment: env,
            currentDirectoryURL: nil
        )

        return TaskResult(
            taskId: taskId,
            toolchainName: toolchainName,
            operation: "set-override-command",
            status: result.wasSuccessful ? .success : .failed,
            startTime: startTime,
            endTime: Date(),
            exitCode: Int(result.exitCode),
            stdoutSnippet: result.stdout.isEmpty ? nil : result.stdout,
            stderrSnippet: result.stderr.isEmpty ? nil : result.stderr,
            errorMessage: result.wasSuccessful ? nil : "Command failed with exit code \(result.exitCode)"
        )
    }

    private func clearOverrideViaRustupCommand(
        taskId: UUID,
        startTime: Date,
        projectPath: String
    ) async throws -> TaskResult {
        let rustupPath = try RustupCommandResolver.resolveRustupPath(
            settings: settings,
            authService: authService
        )

        let env = try RustupCommandResolver.buildEnvironment(
            settings: settings,
            authService: authService
        )

        let resources = try authService.validateAndResolve(
            scope: .projectContext,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }

        let result = try await processRunner.runRustup(
            at: rustupPath,
            arguments: ["override", "unset", "--path", projectPath],
            environment: env,
            currentDirectoryURL: nil
        )

        return TaskResult(
            taskId: taskId,
            toolchainName: nil,
            operation: "clear-override-command",
            status: result.wasSuccessful ? .success : .failed,
            startTime: startTime,
            endTime: Date(),
            exitCode: Int(result.exitCode),
            stdoutSnippet: result.stdout.isEmpty ? nil : result.stdout,
            stderrSnippet: result.stderr.isEmpty ? nil : result.stderr,
            errorMessage: result.wasSuccessful ? nil : "Command failed with exit code \(result.exitCode)"
        )
    }
}
