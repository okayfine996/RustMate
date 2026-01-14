//
//  ProcessRunnerProtocol.swift
//  RustMate
//
//  Protocol for process execution to enable mocking
//

import Foundation

protocol ProcessRunnerProtocol {
    /// Runs a command asynchronously and returns structured output
    /// - Parameters:
    ///   - executable: Path to the executable
    ///   - arguments: Command arguments
    ///   - environment: Environment variables (if any)
    ///   - currentDirectoryURL: Working directory for the process (if any)
    /// - Returns: ProcessResult with stdout, stderr, and exit code
    func run(
        executable: String,
        arguments: [String],
        environment: [String: String]?,
        currentDirectoryURL: URL?
    ) async throws -> ProcessResult

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
        environment: [String: String]?,
        currentDirectoryURL: URL?
    ) async throws -> ProcessResult
}
