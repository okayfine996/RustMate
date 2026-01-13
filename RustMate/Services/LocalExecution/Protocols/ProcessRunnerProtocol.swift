//
//  ProcessRunnerProtocol.swift
//  RustMate
//
//  Protocol for process execution to enable mocking
//

import Foundation

protocol ProcessRunnerProtocol {
    /// Runs a command asynchronously and returns structured output
    func run(
        executable: String,
        arguments: [String],
        environment: [String: String]?
    ) async throws -> ProcessResult

    /// Convenience method for running rustup commands
    func runRustup(
        at rustupPath: String,
        arguments: [String],
        environment: [String: String]?
    ) async throws -> ProcessResult
}
