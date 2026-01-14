//
//  MockProcessRunner.swift
//  RustMateTests
//
//  Mock implementation of ProcessRunnerProtocol for testing
//

import Foundation

@testable import RustMate

class MockProcessRunner: ProcessRunnerProtocol {
    var runCalls: [(executable: String, arguments: [String], environment: [String: String]?, currentDirectoryURL: URL?)] = []

    // Configurable results
    var nextResult: ProcessResult?
    var nextError: Error?

    func run(
        executable: String,
        arguments: [String],
        environment: [String: String]?,
        currentDirectoryURL: URL?
    ) async throws -> ProcessResult {
        runCalls.append((executable, arguments, environment, currentDirectoryURL))

        if let error = nextError {
            throw error
        }

        return nextResult ?? ProcessResult(stdout: "", stderr: "", exitCode: 0)
    }

    func runRustup(
        at rustupPath: String,
        arguments: [String],
        environment: [String: String]?,
        currentDirectoryURL: URL?
    ) async throws -> ProcessResult {
        return try await run(executable: rustupPath, arguments: arguments, environment: environment, currentDirectoryURL: currentDirectoryURL)
    }
}
