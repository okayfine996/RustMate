//
//  ProcessRunner.swift
//  RustMate
//
//  Async wrapper around Process for non-blocking execution
//

import Foundation

/// Result of a process execution
struct ProcessResult {
    let stdout: String
    let stderr: String
    let exitCode: Int32
    let wasSuccessful: Bool

    init(stdout: String, stderr: String, exitCode: Int32) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
        self.wasSuccessful = (exitCode == 0)
    }
}

/// Async process runner that captures output and enforces truncation
actor ProcessRunner: ProcessRunnerProtocol {

    /// Runs a command asynchronously and returns structured output
    /// - Parameters:
    ///   - executable: Path to the executable
    ///   - arguments: Command arguments
    ///   - environment: Environment variables (if any)
    ///   - currentDirectoryURL: Working directory for the process (if any)
    /// - Returns: ProcessResult with stdout, stderr, and exit code
    /// - Throws: Error if process could not be launched
    func run(
        executable: String,
        arguments: [String],
        environment: [String: String]? = nil,
        currentDirectoryURL: URL? = nil
    ) async throws -> ProcessResult {
        return try await withCheckedThrowingContinuation { continuation in
            // Execute process on background thread to avoid blocking UI
            Task.detached(priority: .userInitiated) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments

                // Set working directory if provided
                if let currentDirectoryURL = currentDirectoryURL {
                    process.currentDirectoryURL = currentDirectoryURL
                }

                // Set up environment
                if let environment = environment {
                    var env = ProcessInfo.processInfo.environment
                    for (key, value) in environment {
                        env[key] = value
                    }
                    process.environment = env
                }

                // Capture stdout
                let stdoutPipe = Pipe()
                process.standardOutput = stdoutPipe

                // Capture stderr
                let stderrPipe = Pipe()
                process.standardError = stderrPipe

                // Collect output data
                var stdoutData = Data()
                var stderrData = Data()

                stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty {
                        stdoutData.append(data)
                    }
                }

                stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty {
                        stderrData.append(data)
                    }
                }

                // Handle process termination
                process.terminationHandler = { process in
                    // Close handlers
                    stdoutPipe.fileHandleForReading.readabilityHandler = nil
                    stderrPipe.fileHandleForReading.readabilityHandler = nil

                    // Read any remaining data
                    let remainingStdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    let remainingStderr = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                    if !remainingStdout.isEmpty {
                        stdoutData.append(remainingStdout)
                    }
                    if !remainingStderr.isEmpty {
                        stderrData.append(remainingStderr)
                    }

                    // Truncate output
                    let stdout = ProcessOutputLimiter.truncateStdout(stdoutData)
                    let stderr = ProcessOutputLimiter.truncateStderr(stderrData)

                    let result = ProcessResult(
                        stdout: stdout,
                        stderr: stderr,
                        exitCode: process.terminationStatus
                    )

                    continuation.resume(returning: result)
                }

                // Launch the process
                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Convenience method for running rustup commands
    /// - Parameters:
    ///   - rustupPath: Path to rustup executable
    ///   - arguments: Rustup command arguments
    ///   - environment: Environment variables (if any)
    ///   - currentDirectoryURL: Working directory for the process (if any)
    /// - Returns: ProcessResult
    func runRustup(
        at rustupPath: String,
        arguments: [String],
        environment: [String: String]? = nil,
        currentDirectoryURL: URL? = nil
    ) async throws -> ProcessResult {
        return try await run(
            executable: rustupPath,
            arguments: arguments,
            environment: environment,
            currentDirectoryURL: currentDirectoryURL
        )
    }
}
