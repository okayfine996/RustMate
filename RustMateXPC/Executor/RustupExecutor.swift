//
//  RustupExecutor.swift
//  RustMateXPC
//
//  Actor-based serial executor for rustup commands - ensures thread-safe serial execution
//

import Foundation

actor RustupExecutor {

    // MARK: - Properties

    private let processRunner: ProcessRunner
    private let validator: CommandValidator
    private var runningProcesses: [UUID: Process] = [:]
    private var rustupPath: String?

    // MARK: - Initialization

    init() {
        self.processRunner = ProcessRunner()
        self.validator = CommandValidator()
        // Find rustup on initialization (no sandbox restrictions)
        self.rustupPath = findRustupPath()
        if let path = rustupPath {
            print("✅ RustupExecutor: Found rustup at \(path)")
        } else {
            print("⚠️ RustupExecutor: rustup not found, will use PATH environment")
        }
    }

    /// Find rustup executable path
    private func findRustupPath() -> String? {
        let possiblePaths = [
            "~/.cargo/bin/rustup",
            "/usr/local/bin/rustup",
            "/opt/homebrew/bin/rustup"
        ]

        let fileManager = FileManager.default
        for path in possiblePaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if fileManager.fileExists(atPath: expandedPath) {
                return expandedPath
            }
        }
        return nil
    }

    /// Set cargo bookmark data for security-scoped resource access
    /// Note: This is a no-op when sandbox is disabled
    func setCargoBookmark(_ bookmarkData: Data?) {
        print("ℹ️ RustupExecutor: setCargoBookmark called but sandbox is disabled")
        // No-op: Bookmarks not needed without sandbox
    }

    /// Get rustup command path, falling back to "rustup" if not found
    private func getRustupCommand() -> String {
        return rustupPath ?? "rustup"
    }

    // MARK: - Environment & Validation

    func validateEnvironment(rustupPath: String?) async throws -> ValidationResult {
        let path = rustupPath ?? "~/.cargo/bin/rustup"
        let expandedPath = NSString(string: path).expandingTildeInPath

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: expandedPath) {
            // Try to get version
            let result = try await processRunner.run(command: expandedPath, args: ["--version"])
            if result.exitCode == 0, let version = result.stdout?.components(separatedBy: " ").first {
                // Store the validated rustup path for future use
                self.rustupPath = expandedPath
                return ValidationResult(
                    hasRustup: true,
                    rustupPath: expandedPath,
                    version: version,
                    hints: []
                )
            }
        }

        return ValidationResult(
            hasRustup: false,
            rustupPath: nil,
            version: nil,
            hints: [
                "Rustup not found at \(path)",
                "Grant access to ~/.cargo/bin in Settings",
                "Or specify custom rustup path in Settings"
            ]
        )
    }

    // MARK: - Toolchain Operations

    func listToolchains() async throws -> [ToolchainInfo] {
        let result = try await processRunner.run(command: getRustupCommand(), args: ["toolchain", "list"])
        guard result.exitCode == 0 else {
            throw RustupError.commandFailed(stderr: result.stderr ?? "Unknown error")
        }

        guard let stdout = result.stdout else {
            return []
        }

        // Use ToolchainParser to parse the output
        return ToolchainParser.parse(stdout)
    }

    func installToolchain(name: String) async -> TaskResult {
        guard validator.validateToolchainName(name) else {
            return TaskResult(
                taskId: UUID(),
                toolchainName: name,
                operation: "install",
                status: .failed,
                startTime: Date(),
                endTime: Date(),
                exitCode: 1,
                errorMessage: "Invalid toolchain name"
            )
        }

        let taskId = UUID()
        let startTime = Date()

        do {
            let result = try await processRunner.run(command: getRustupCommand(), args: ["toolchain", "install", name])
            return TaskResult(
                taskId: taskId,
                toolchainName: name,
                operation: "install",
                status: result.exitCode == 0 ? .success : .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdout,
                stderrSnippet: result.stderr,
                errorMessage: result.exitCode != 0 ? "Installation failed" : nil
            )
        } catch {
            return TaskResult(
                taskId: taskId,
                toolchainName: name,
                operation: "install",
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: 1,
                errorMessage: error.localizedDescription
            )
        }
    }

    func uninstallToolchain(name: String) async -> TaskResult {
        guard validator.validateToolchainName(name) else {
            return TaskResult(
                taskId: UUID(),
                toolchainName: name,
                operation: "uninstall",
                status: .failed,
                startTime: Date(),
                endTime: Date(),
                exitCode: 1,
                errorMessage: "Invalid toolchain name"
            )
        }

        let taskId = UUID()
        let startTime = Date()

        do {
            let result = try await processRunner.run(command: getRustupCommand(), args: ["toolchain", "uninstall", name])
            return TaskResult(
                taskId: taskId,
                toolchainName: name,
                operation: "uninstall",
                status: result.exitCode == 0 ? .success : .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdout,
                stderrSnippet: result.stderr,
                errorMessage: result.exitCode != 0 ? "Uninstall failed" : nil
            )
        } catch {
            return TaskResult(
                taskId: taskId,
                toolchainName: name,
                operation: "uninstall",
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: 1,
                errorMessage: error.localizedDescription
            )
        }
    }

    func setDefaultToolchain(name: String) async -> TaskResult {
        guard validator.validateToolchainName(name) else {
            return TaskResult(
                taskId: UUID(),
                toolchainName: name,
                operation: "setDefault",
                status: .failed,
                startTime: Date(),
                endTime: Date(),
                exitCode: 1,
                errorMessage: "Invalid toolchain name"
            )
        }

        let taskId = UUID()
        let startTime = Date()

        do {
            let result = try await processRunner.run(command: getRustupCommand(), args: ["default", name])
            return TaskResult(
                taskId: taskId,
                toolchainName: name,
                operation: "setDefault",
                status: result.exitCode == 0 ? .success : .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdout,
                stderrSnippet: result.stderr,
                errorMessage: result.exitCode != 0 ? "Failed to set default" : nil
            )
        } catch {
            return TaskResult(
                taskId: taskId,
                toolchainName: name,
                operation: "setDefault",
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: 1,
                errorMessage: error.localizedDescription
            )
        }
    }

    func updateAllToolchains() async -> TaskResult {
        let taskId = UUID()
        let startTime = Date()

        do {
            let result = try await processRunner.run(command: getRustupCommand(), args: ["update"])
            return TaskResult(
                taskId: taskId,
                toolchainName: nil,
                operation: "updateAll",
                status: result.exitCode == 0 ? .success : .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdout,
                stderrSnippet: result.stderr,
                errorMessage: result.exitCode != 0 ? "Update failed" : nil
            )
        } catch {
            return TaskResult(
                taskId: taskId,
                toolchainName: nil,
                operation: "updateAll",
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: 1,
                errorMessage: error.localizedDescription
            )
        }
    }

    func updateToolchain(name: String) async -> TaskResult {
        guard validator.validateToolchainName(name) else {
            return TaskResult(
                taskId: UUID(),
                toolchainName: name,
                operation: "update",
                status: .failed,
                startTime: Date(),
                endTime: Date(),
                exitCode: 1,
                errorMessage: "Invalid toolchain name"
            )
        }

        let taskId = UUID()
        let startTime = Date()

        do {
            let result = try await processRunner.run(command: getRustupCommand(), args: ["update", name])
            return TaskResult(
                taskId: taskId,
                toolchainName: name,
                operation: "update",
                status: result.exitCode == 0 ? .success : .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdout,
                stderrSnippet: result.stderr,
                errorMessage: result.exitCode != 0 ? "Update failed" : nil
            )
        } catch {
            return TaskResult(
                taskId: taskId,
                toolchainName: name,
                operation: "update",
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: 1,
                errorMessage: error.localizedDescription
            )
        }
    }

    // MARK: - Component Operations

    func listComponents(toolchainName: String) async throws -> [ComponentInfo] {
        let result = try await processRunner.run(command: getRustupCommand(), args: ["component", "list", "--toolchain", toolchainName])
        guard result.exitCode == 0 else {
            throw RustupError.commandFailed(stderr: result.stderr ?? "Unknown error")
        }

        guard let stdout = result.stdout, !stdout.isEmpty else {
            return []
        }

        return ComponentParser.parse(stdout)
    }

    func addComponent(componentName: String, toolchainName: String) async -> TaskResult {
        let taskId = UUID()
        let startTime = Date()

        do {
            let result = try await processRunner.run(command: getRustupCommand(), args: ["component", "add", componentName, "--toolchain", toolchainName])
            return TaskResult(
                taskId: taskId,
                toolchainName: toolchainName,
                operation: "addComponent",
                status: result.exitCode == 0 ? .success : .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdout,
                stderrSnippet: result.stderr,
                errorMessage: result.exitCode != 0 ? "Component installation failed" : nil
            )
        } catch {
            return TaskResult(
                taskId: taskId,
                toolchainName: toolchainName,
                operation: "addComponent",
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: 1,
                errorMessage: error.localizedDescription
            )
        }
    }

    func removeComponent(componentName: String, toolchainName: String) async -> TaskResult {
        let taskId = UUID()
        let startTime = Date()

        do {
            let result = try await processRunner.run(command: getRustupCommand(), args: ["component", "remove", componentName, "--toolchain", toolchainName])
            return TaskResult(
                taskId: taskId,
                toolchainName: toolchainName,
                operation: "removeComponent",
                status: result.exitCode == 0 ? .success : .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdout,
                stderrSnippet: result.stderr,
                errorMessage: result.exitCode != 0 ? "Component removal failed" : nil
            )
        } catch {
            return TaskResult(
                taskId: taskId,
                toolchainName: toolchainName,
                operation: "removeComponent",
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: 1,
                errorMessage: error.localizedDescription
            )
        }
    }

    // MARK: - Target Operations

    func listTargets(toolchainName: String) async throws -> [TargetInfo] {
        let result = try await processRunner.run(command: getRustupCommand(), args: ["target", "list", "--toolchain", toolchainName])
        guard result.exitCode == 0 else {
            throw RustupError.commandFailed(stderr: result.stderr ?? "Unknown error")
        }

        guard let stdout = result.stdout, !stdout.isEmpty else {
            return []
        }

        return TargetParser.parse(stdout)
    }

    func addTarget(targetTriple: String, toolchainName: String) async -> TaskResult {
        guard validator.validateTargetTriple(targetTriple) else {
            return TaskResult(
                taskId: UUID(),
                toolchainName: toolchainName,
                operation: "addTarget",
                status: .failed,
                startTime: Date(),
                endTime: Date(),
                exitCode: 1,
                errorMessage: "Invalid target triple"
            )
        }

        let taskId = UUID()
        let startTime = Date()

        do {
            let result = try await processRunner.run(command: getRustupCommand(), args: ["target", "add", targetTriple, "--toolchain", toolchainName])
            return TaskResult(
                taskId: taskId,
                toolchainName: toolchainName,
                operation: "addTarget",
                status: result.exitCode == 0 ? .success : .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdout,
                stderrSnippet: result.stderr,
                errorMessage: result.exitCode != 0 ? "Target installation failed" : nil
            )
        } catch {
            return TaskResult(
                taskId: taskId,
                toolchainName: toolchainName,
                operation: "addTarget",
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: 1,
                errorMessage: error.localizedDescription
            )
        }
    }

    func removeTarget(targetTriple: String, toolchainName: String) async -> TaskResult {
        guard validator.validateTargetTriple(targetTriple) else {
            return TaskResult(
                taskId: UUID(),
                toolchainName: toolchainName,
                operation: "removeTarget",
                status: .failed,
                startTime: Date(),
                endTime: Date(),
                exitCode: 1,
                errorMessage: "Invalid target triple"
            )
        }

        let taskId = UUID()
        let startTime = Date()

        do {
            let result = try await processRunner.run(command: getRustupCommand(), args: ["target", "remove", targetTriple, "--toolchain", toolchainName])
            return TaskResult(
                taskId: taskId,
                toolchainName: toolchainName,
                operation: "removeTarget",
                status: result.exitCode == 0 ? .success : .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: result.exitCode,
                stdoutSnippet: result.stdout,
                stderrSnippet: result.stderr,
                errorMessage: result.exitCode != 0 ? "Target removal failed" : nil
            )
        } catch {
            return TaskResult(
                taskId: taskId,
                toolchainName: toolchainName,
                operation: "removeTarget",
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: 1,
                errorMessage: error.localizedDescription
            )
        }
    }

    // MARK: - Project Context Operations

    func getProjectContext(projectPath: String) async throws -> ProjectContextInfo {
        guard validator.validateProjectPath(projectPath) else {
            throw RustupError.invalidPath(projectPath)
        }

        // Run rustup show in the project directory
        let result = try await processRunner.run(
            command: getRustupCommand(),
            args: ["show"],
            workingDirectory: projectPath
        )

        guard result.exitCode == 0 else {
            throw RustupError.commandFailed(stderr: result.stderr ?? "Failed to get project context")
        }

        guard let stdout = result.stdout, !stdout.isEmpty else {
            throw RustupError.commandFailed(stderr: "Empty output from rustup show")
        }

        // Parse output with ShowParser
        return ShowParser.parse(stdout, projectPath: projectPath)
    }

    func setProjectOverride(projectPath: String, toolchainName: String, mode: String) async -> TaskResult {
        let taskId = UUID()
        let startTime = Date()

        do {
            if mode == "toolchainFile" {
                // Write rust-toolchain.toml file
                let tomlPath = (projectPath as NSString).appendingPathComponent("rust-toolchain.toml")
                let content = """
                [toolchain]
                channel = "\(toolchainName)"
                """

                try content.write(toFile: tomlPath, atomically: true, encoding: .utf8)

                return TaskResult(
                    taskId: taskId,
                    toolchainName: toolchainName,
                    operation: "setProjectOverride",
                    status: .success,
                    startTime: startTime,
                    endTime: Date(),
                    exitCode: 0,
                    stdoutSnippet: "Created \(tomlPath)",
                    stderrSnippet: nil,
                    errorMessage: nil
                )
            } else {
                // Use rustup override set
                let result = try await processRunner.run(
                    command: getRustupCommand(),
                    args: ["override", "set", toolchainName],
                    workingDirectory: projectPath
                )

                return TaskResult(
                    taskId: taskId,
                    toolchainName: toolchainName,
                    operation: "setProjectOverride",
                    status: result.exitCode == 0 ? .success : .failed,
                    startTime: startTime,
                    endTime: Date(),
                    exitCode: result.exitCode,
                    stdoutSnippet: result.stdout,
                    stderrSnippet: result.stderr,
                    errorMessage: result.exitCode != 0 ? "Failed to set override" : nil
                )
            }
        } catch {
            return TaskResult(
                taskId: taskId,
                toolchainName: toolchainName,
                operation: "setProjectOverride",
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: 1,
                errorMessage: error.localizedDescription
            )
        }
    }

    func clearProjectOverride(projectPath: String, mode: String) async -> TaskResult {
        let taskId = UUID()
        let startTime = Date()

        do {
            if mode == "toolchainFile" {
                // Delete rust-toolchain.toml or rust-toolchain file
                let fileManager = FileManager.default
                let tomlPath = (projectPath as NSString).appendingPathComponent("rust-toolchain.toml")
                let legacyPath = (projectPath as NSString).appendingPathComponent("rust-toolchain")

                var deleted = false
                var deletedPath: String?

                if fileManager.fileExists(atPath: tomlPath) {
                    try fileManager.removeItem(atPath: tomlPath)
                    deleted = true
                    deletedPath = tomlPath
                }

                if fileManager.fileExists(atPath: legacyPath) {
                    try fileManager.removeItem(atPath: legacyPath)
                    deleted = true
                    deletedPath = legacyPath
                }

                if deleted {
                    return TaskResult(
                        taskId: taskId,
                        toolchainName: nil,
                        operation: "clearProjectOverride",
                        status: .success,
                        startTime: startTime,
                        endTime: Date(),
                        exitCode: 0,
                        stdoutSnippet: "Deleted \(deletedPath ?? "toolchain file")",
                        stderrSnippet: nil,
                        errorMessage: nil
                    )
                } else {
                    return TaskResult(
                        taskId: taskId,
                        toolchainName: nil,
                        operation: "clearProjectOverride",
                        status: .success,
                        startTime: startTime,
                        endTime: Date(),
                        exitCode: 0,
                        stdoutSnippet: "No toolchain file found",
                        stderrSnippet: nil,
                        errorMessage: nil
                    )
                }
            } else {
                // Use rustup override unset
                let result = try await processRunner.run(
                    command: getRustupCommand(),
                    args: ["override", "unset"],
                    workingDirectory: projectPath
                )

                return TaskResult(
                    taskId: taskId,
                    toolchainName: nil,
                    operation: "clearProjectOverride",
                    status: result.exitCode == 0 ? .success : .failed,
                    startTime: startTime,
                    endTime: Date(),
                    exitCode: result.exitCode,
                    stdoutSnippet: result.stdout,
                    stderrSnippet: result.stderr,
                    errorMessage: result.exitCode != 0 ? "Failed to clear override" : nil
                )
            }
        } catch {
            return TaskResult(
                taskId: taskId,
                toolchainName: nil,
                operation: "clearProjectOverride",
                status: .failed,
                startTime: startTime,
                endTime: Date(),
                exitCode: 1,
                errorMessage: error.localizedDescription
            )
        }
    }

    // MARK: - Task Management

    func cancelTask(taskId: UUID) {
        if let process = runningProcesses[taskId] {
            process.terminate()
            runningProcesses.removeValue(forKey: taskId)
        }
    }

    // MARK: - Error Types

    enum RustupError: Error {
        case commandFailed(stderr: String)
        case invalidPath(String)
    }
}
