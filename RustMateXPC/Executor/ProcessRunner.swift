//
//  ProcessRunner.swift
//  RustMateXPC
//
//  Wrapper for Process execution with stdout/stderr capture
//

import Foundation

struct ProcessRunner {

    struct ProcessResult {
        let exitCode: Int
        let stdout: String?
        let stderr: String?
    }

    /// Run a command and capture output
    func run(command: String, args: [String], workingDirectory: String? = nil) async throws -> ProcessResult {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = args

            // Set working directory if provided
            if let workingDirectory = workingDirectory {
                process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
            }

            let outputPipe = Pipe()
            let errorPipe = Pipe()

            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()

                // Read output asynchronously
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                process.waitUntilExit()

                let stdout = String(data: outputData, encoding: .utf8)
                let stderr = String(data: errorData, encoding: .utf8)

                let result = ProcessResult(
                    exitCode: Int(process.terminationStatus),
                    stdout: stdout,
                    stderr: stderr
                )

                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Truncate output to max size (32KB per spec)
    private func truncate(_ string: String?, maxBytes: Int = 32_768) -> String? {
        guard let string = string else { return nil }
        guard let data = string.data(using: .utf8), data.count > maxBytes else {
            return string
        }

        let truncated = data.prefix(maxBytes)
        return String(data: truncated, encoding: .utf8) ?? string
    }
}
