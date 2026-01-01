//
//  LocalRustupToolchainService.swift
//  RustMate
//
//  Local (in-app) implementation of RustToolchainServiceProtocol
//  Executes rustup directly in the sandboxed main app
//

import Foundation

/// Local implementation of RustToolchainServiceProtocol using direct process execution
class LocalRustupToolchainService: RustToolchainServiceProtocol {
    private let processRunner = ProcessRunner()
    private let authService: AuthorizationService
    private var settings: AppSettings

    init(settings: AppSettings = .default, authService: AuthorizationService = AuthorizationService()) {
        self.settings = settings
        self.authService = authService
    }

    // MARK: - Toolchain Operations

    func listToolchains() async throws -> [ToolchainInfo] {
        let rustupPath = try RustupCommandResolver.resolveRustupPath(
            settings: settings,
            authService: authService
        )

        let env = try RustupCommandResolver.buildEnvironment(
            settings: settings,
            authService: authService
        )

        // Validate authorization scope
        let resources = try authService.validateAndResolve(
            scope: .toolchainOperations,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }

        // Execute rustup toolchain list
        let result = try await processRunner.runRustup(
            at: rustupPath,
            arguments: ["toolchain", "list"],
            environment: env
        )

        guard result.wasSuccessful else {
            throw RustupExecutionError.executionFailed(
                command: "rustup toolchain list",
                exitCode: result.exitCode,
                stderr: result.stderr,
                suggestedFix: "Check that rustup is working correctly. Try running 'rustup --version' in Terminal."
            )
        }

        // Parse output
        guard ToolchainParser.isValidOutput(result.stdout) else {
            throw RustupExecutionError.parseFailed(
                command: "rustup toolchain list",
                output: result.stdout,
                reason: "Output does not match expected format"
            )
        }

        return ToolchainParser.parse(result.stdout)
    }

    func installToolchain(name: String) async throws -> TaskResult {
        return try await executeToolchainCommand(
            operation: "install",
            toolchainName: name,
            arguments: ["toolchain", "install", name]
        )
    }

    func uninstallToolchain(name: String) async throws -> TaskResult {
        return try await executeToolchainCommand(
            operation: "uninstall",
            toolchainName: name,
            arguments: ["toolchain", "uninstall", name]
        )
    }

    func setDefaultToolchain(name: String) async throws -> TaskResult {
        return try await executeToolchainCommand(
            operation: "set-default",
            toolchainName: name,
            arguments: ["default", name]
        )
    }

    func updateAllToolchains() async throws -> TaskResult {
        return try await executeToolchainCommand(
            operation: "update-all",
            toolchainName: nil,
            arguments: ["update"]
        )
    }

    func updateToolchain(name: String) async throws -> TaskResult {
        return try await executeToolchainCommand(
            operation: "update",
            toolchainName: name,
            arguments: ["toolchain", "install", name, "--force"]
        )
    }

    // MARK: - Component Operations

    func listComponents(toolchainName: String) async throws -> [ComponentInfo] {
        let rustupPath = try RustupCommandResolver.resolveRustupPath(
            settings: settings,
            authService: authService
        )

        let env = try RustupCommandResolver.buildEnvironment(
            settings: settings,
            authService: authService
        )

        let resources = try authService.validateAndResolve(
            scope: .componentOperations,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }

        let result = try await processRunner.runRustup(
            at: rustupPath,
            arguments: ["component", "list", "--toolchain", toolchainName],
            environment: env
        )

        guard result.wasSuccessful else {
            throw RustupExecutionError.executionFailed(
                command: "rustup component list",
                exitCode: result.exitCode,
                stderr: result.stderr,
                suggestedFix: "Check that toolchain '\(toolchainName)' is installed."
            )
        }

        let parsedComponents = ComponentParser.parse(result.stdout)

        // Create new ComponentInfo instances with the toolchain name set
        let components = parsedComponents.map { component in
            ComponentInfo(
                id: component.id,
                name: component.name,
                displayName: component.displayName,
                toolchainName: toolchainName,
                isInstalled: component.isInstalled,
                componentType: component.componentType,
                description: component.description
            )
        }

        return components
    }

    func addComponent(componentName: String, toolchainName: String) async throws -> TaskResult {
        return try await executeComponentCommand(
            operation: "add",
            componentName: componentName,
            toolchainName: toolchainName,
            arguments: ["component", "add", componentName, "--toolchain", toolchainName]
        )
    }

    func removeComponent(componentName: String, toolchainName: String) async throws -> TaskResult {
        return try await executeComponentCommand(
            operation: "remove",
            componentName: componentName,
            toolchainName: toolchainName,
            arguments: ["component", "remove", componentName, "--toolchain", toolchainName]
        )
    }

    // MARK: - Target Operations

    func listTargets(toolchainName: String) async throws -> [TargetInfo] {
        let rustupPath = try RustupCommandResolver.resolveRustupPath(
            settings: settings,
            authService: authService
        )

        let env = try RustupCommandResolver.buildEnvironment(
            settings: settings,
            authService: authService
        )

        let resources = try authService.validateAndResolve(
            scope: .targetOperations,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }

        let result = try await processRunner.runRustup(
            at: rustupPath,
            arguments: ["target", "list", "--toolchain", toolchainName],
            environment: env
        )

        guard result.wasSuccessful else {
            throw RustupExecutionError.executionFailed(
                command: "rustup target list",
                exitCode: result.exitCode,
                stderr: result.stderr,
                suggestedFix: "Check that toolchain '\(toolchainName)' is installed."
            )
        }

        return TargetParser.parse(result.stdout)
    }

    func addTarget(targetTriple: String, toolchainName: String) async throws -> TaskResult {
        return try await executeTargetCommand(
            operation: "add",
            targetTriple: targetTriple,
            toolchainName: toolchainName,
            arguments: ["target", "add", targetTriple, "--toolchain", toolchainName]
        )
    }

    func removeTarget(targetTriple: String, toolchainName: String) async throws -> TaskResult {
        return try await executeTargetCommand(
            operation: "remove",
            targetTriple: targetTriple,
            toolchainName: toolchainName,
            arguments: ["target", "remove", targetTriple, "--toolchain", toolchainName]
        )
    }

    // MARK: - Private Helpers

    private func executeToolchainCommand(
        operation: String,
        toolchainName: String?,
        arguments: [String]
    ) async throws -> TaskResult {
        let taskId = UUID()
        let startTime = Date()

        let rustupPath = try RustupCommandResolver.resolveRustupPath(
            settings: settings,
            authService: authService
        )

        let env = try RustupCommandResolver.buildEnvironment(
            settings: settings,
            authService: authService
        )

        let resources = try authService.validateAndResolve(
            scope: .toolchainOperations,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }

        let result = try await processRunner.runRustup(
            at: rustupPath,
            arguments: arguments,
            environment: env
        )

        let endTime = Date()

        return TaskResult(
            taskId: taskId,
            toolchainName: toolchainName,
            operation: operation,
            status: result.wasSuccessful ? .success : .failed,
            startTime: startTime,
            endTime: endTime,
            exitCode: Int(result.exitCode),
            stdoutSnippet: result.stdout.isEmpty ? nil : result.stdout,
            stderrSnippet: result.stderr.isEmpty ? nil : result.stderr,
            errorMessage: result.wasSuccessful ? nil : "Command failed with exit code \(result.exitCode)"
        )
    }

    private func executeComponentCommand(
        operation: String,
        componentName: String,
        toolchainName: String,
        arguments: [String]
    ) async throws -> TaskResult {
        let taskId = UUID()
        let startTime = Date()

        let rustupPath = try RustupCommandResolver.resolveRustupPath(
            settings: settings,
            authService: authService
        )

        let env = try RustupCommandResolver.buildEnvironment(
            settings: settings,
            authService: authService
        )

        let resources = try authService.validateAndResolve(
            scope: .componentOperations,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }

        let result = try await processRunner.runRustup(
            at: rustupPath,
            arguments: arguments,
            environment: env
        )

        let endTime = Date()

        return TaskResult(
            taskId: taskId,
            toolchainName: toolchainName,
            operation: "\(operation)-component-\(componentName)",
            status: result.wasSuccessful ? .success : .failed,
            startTime: startTime,
            endTime: endTime,
            exitCode: Int(result.exitCode),
            stdoutSnippet: result.stdout.isEmpty ? nil : result.stdout,
            stderrSnippet: result.stderr.isEmpty ? nil : result.stderr,
            errorMessage: result.wasSuccessful ? nil : "Command failed with exit code \(result.exitCode)"
        )
    }

    private func executeTargetCommand(
        operation: String,
        targetTriple: String,
        toolchainName: String,
        arguments: [String]
    ) async throws -> TaskResult {
        let taskId = UUID()
        let startTime = Date()

        let rustupPath = try RustupCommandResolver.resolveRustupPath(
            settings: settings,
            authService: authService
        )

        let env = try RustupCommandResolver.buildEnvironment(
            settings: settings,
            authService: authService
        )

        let resources = try authService.validateAndResolve(
            scope: .targetOperations,
            settings: settings
        )
        defer { authService.stopAccessing(resources) }

        let result = try await processRunner.runRustup(
            at: rustupPath,
            arguments: arguments,
            environment: env
        )

        let endTime = Date()

        return TaskResult(
            taskId: taskId,
            toolchainName: toolchainName,
            operation: "\(operation)-target-\(targetTriple)",
            status: result.wasSuccessful ? .success : .failed,
            startTime: startTime,
            endTime: endTime,
            exitCode: Int(result.exitCode),
            stdoutSnippet: result.stdout.isEmpty ? nil : result.stdout,
            stderrSnippet: result.stderr.isEmpty ? nil : result.stderr,
            errorMessage: result.wasSuccessful ? nil : "Command failed with exit code \(result.exitCode)"
        )
    }
}
