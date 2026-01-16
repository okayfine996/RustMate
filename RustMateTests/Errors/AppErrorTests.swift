//
//  AppErrorTests.swift
//  RustMateTests
//
//  Unit tests for AppError conversions and properties
//

import XCTest

@testable import RustMate

final class AppErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testAuthorizationMissing_ErrorDescription() {
        let error = AppError.authorizationMissing(purpose: .rustupExecutableDir)

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("authorization") ?? false)
    }

    func testRustupNotFound_ErrorDescription() {
        let error = AppError.rustupNotFound

        XCTAssertEqual(error.errorDescription, "rustup is not installed or not accessible")
        XCTAssertEqual(error.recoverySuggestion, "Install rustup from https://rustup.rs or add it to your PATH.")
    }

    func testCommandExecutionFailed_ErrorDescription() {
        let error = AppError.commandExecutionFailed(
            command: "rustup install stable",
            exitCode: 1,
            stderr: "error: toolchain 'stable' is already installed"
        )

        XCTAssertTrue(error.errorDescription?.contains("rustup install stable") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("exit code 1") ?? false)
    }

    func testProjectNotFound_ErrorDescription() {
        let error = AppError.projectNotFound(path: "/path/to/project")

        XCTAssertTrue(error.errorDescription?.contains("/path/to/project") ?? false)
        XCTAssertEqual(error.recoverySuggestion, "The project directory may have been moved or deleted.")
    }

    func testNetworkUnavailable_ErrorDescription() {
        let error = AppError.networkUnavailable

        XCTAssertEqual(error.errorDescription, "Network connection is not available")
        XCTAssertEqual(error.recoverySuggestion, "Check your internet connection and try again.")
    }

    // MARK: - Recovery Suggestion Tests

    func testAuthorizationMissing_RecoverySuggestion() {
        let error = AppError.authorizationMissing(purpose: .rustupExecutableDir)

        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion?.contains("Settings") ?? false)
        XCTAssertTrue(error.recoverySuggestion?.contains("Permissions") ?? false)
    }

    func testCommandExecutionFailed_RecoverySuggestion() {
        let error = AppError.commandExecutionFailed(
            command: "rustup",
            exitCode: 1,
            stderr: "network error"
        )

        // Should use TaskResult.suggestFix for stderr
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testParseFailed_RecoverySuggestion() {
        let error = AppError.parseFailed(command: "rustup", output: "", reason: "")

        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion?.contains("rustup self update") ?? false)
    }

    // MARK: - Conversion from RustupExecutionError

    func testConversionFrom_RustupExecutionError_MissingAuthorization() {
        let rustupError = RustupExecutionError.missingAuthorization(
            purpose: .rustupExecutableDir,
            message: "Authorization required",
            suggestedFix: "Grant access in Settings"
        )

        let appError = AppError(rustupError)

        if case .authorizationMissing(let purpose) = appError {
            XCTAssertEqual(purpose, .rustupExecutableDir)
        } else {
            XCTFail("Expected authorizationMissing, got \(appError)")
        }
    }

    func testConversionFrom_RustupExecutionError_RustupNotFound() {
        let rustupError = RustupExecutionError.rustupNotFound(
            message: "rustup not found",
            suggestedFix: "Install rustup"
        )

        let appError = AppError(rustupError)

        if case .rustupNotFound = appError {
            // Success
        } else {
            XCTFail("Expected rustupNotFound, got \(appError)")
        }
    }

    func testConversionFrom_RustupExecutionError_ExecutionFailed() {
        let rustupError = RustupExecutionError.executionFailed(
            command: "rustup install stable",
            exitCode: 1,
            stderr: "error message",
            suggestedFix: "Check your setup"
        )

        let appError = AppError(rustupError)

        if case .commandExecutionFailed(let command, let exitCode, let stderr) = appError {
            XCTAssertEqual(command, "rustup install stable")
            XCTAssertEqual(exitCode, 1)
            XCTAssertEqual(stderr, "error message")
        } else {
            XCTFail("Expected commandExecutionFailed, got \(appError)")
        }
    }

    func testConversionFrom_RustupExecutionError_ParseFailed() {
        let rustupError = RustupExecutionError.parseFailed(
            command: "rustup show",
            output: "invalid output",
            reason: "unexpected format"
        )

        let appError = AppError(rustupError)

        if case .parseFailed(let command, let output, let reason) = appError {
            XCTAssertEqual(command, "rustup show")
            XCTAssertEqual(output, "invalid output")
            XCTAssertEqual(reason, "unexpected format")
        } else {
            XCTFail("Expected parseFailed, got \(appError)")
        }
    }

    func testConversionFrom_RustupExecutionError_Unknown() {
        let rustupError = RustupExecutionError.unknown(
            message: "Unknown error",
            stderr: "stderr output"
        )

        let appError = AppError(rustupError)

        if case .unknownError(let underlying) = appError {
            XCTAssertTrue(underlying.localizedDescription.contains("Unknown error"))
        } else {
            XCTFail("Expected unknownError, got \(appError)")
        }
    }

    // MARK: - Conversion from AuthorizationError

    func testConversionFrom_AuthorizationError_MissingScope() {
        let authError = AuthorizationError.missingScope(purpose: .rustupExecutableDir)

        let appError = AppError(authError)

        if case .authorizationMissing(let purpose) = appError {
            XCTAssertEqual(purpose, .rustupExecutableDir)
        } else {
            XCTFail("Expected authorizationMissing, got \(appError)")
        }
    }

    func testConversionFrom_AuthorizationError_StaleBookmark() {
        let authError = AuthorizationError.staleBookmark(path: "/path/to/rustup", purpose: .rustupExecutableDir)

        let appError = AppError(authError)

        if case .authorizationStale(let path, let purpose) = appError {
            XCTAssertEqual(path, "/path/to/rustup")
            XCTAssertEqual(purpose, .rustupExecutableDir)
        } else {
            XCTFail("Expected authorizationStale, got \(appError)")
        }
    }

    func testConversionFrom_AuthorizationError_AccessDenied() {
        let authError = AuthorizationError.accessDenied(path: "/path/to/rustup", purpose: .rustupExecutableDir)

        let appError = AppError(authError)

        if case .authorizationDenied(let path, let purpose) = appError {
            XCTAssertEqual(path, "/path/to/rustup")
            XCTAssertEqual(purpose, .rustupExecutableDir)
        } else {
            XCTFail("Expected authorizationDenied, got \(appError)")
        }
    }

    func testConversionFrom_AuthorizationError_InvalidSelection() {
        let authError = AuthorizationError.invalidSelection(
            path: "/wrong/path",
            purpose: .rustupExecutableDir,
            reason: "Not a valid rustup directory"
        )

        let appError = AppError(authError)

        if case .authorizationInvalid(let path, let purpose, let reason) = appError {
            XCTAssertEqual(path, "/wrong/path")
            XCTAssertEqual(purpose, .rustupExecutableDir)
            XCTAssertEqual(reason, "Not a valid rustup directory")
        } else {
            XCTFail("Expected authorizationInvalid, got \(appError)")
        }
    }

    // MARK: - Multiple Error Types

    func testMultipleAuthorizationPurposes() {
        let error1 = AppError.authorizationMissing(purpose: .rustupExecutableDir)
        let error2 = AppError.authorizationMissing(purpose: .cargoHome)
        let error3 = AppError.authorizationMissing(purpose: .projectAccess)

        XCTAssertNotNil(error1.errorDescription)
        XCTAssertNotNil(error2.errorDescription)
        XCTAssertNotNil(error3.errorDescription)
    }

    func testProjectErrors() {
        let error1 = AppError.projectNotFound(path: "/path1")
        let error2 = AppError.projectAlreadyAdded(path: "/path2")
        let error3 = AppError.invalidProjectDirectory(path: "/path3", reason: "not a Rust project")

        XCTAssertNotNil(error1.errorDescription)
        XCTAssertNotNil(error2.errorDescription)
        XCTAssertNotNil(error3.errorDescription)
    }
}
