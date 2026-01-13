//
//  LocalRustupToolchainServiceTests.swift
//  RustMateTests
//
//  Tests for LocalRustupToolchainService logic
//

import XCTest

@testable import RustMate

final class LocalRustupToolchainServiceTests: XCTestCase {
    var service: LocalRustupToolchainService!
    var mockRunner: MockProcessRunner!
    var mockAuthService: MockAuthorizationService!
    var tempDir: URL!
    var fakeRustupPath: String!

    override func setUpWithError() throws {
        // Create a temporary file to act as "rustup"
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let rustupUrl = tempDir.appendingPathComponent("rustup")
        FileManager.default.createFile(atPath: rustupUrl.path, contents: Data(), attributes: nil)
        fakeRustupPath = rustupUrl.path

        // Setup dependencies
        var settings = AppSettings()
        settings.rustupPath = fakeRustupPath

        mockRunner = MockProcessRunner()
        mockAuthService = MockAuthorizationService()

        service = LocalRustupToolchainService(
            settings: settings,
            authService: mockAuthService,
            processRunner: mockRunner
        )
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: tempDir)
    }

    func testInstallToolchain() async throws {
        // Arrange
        mockRunner.nextResult = ProcessResult(
            stdout: "info: installing component 'rustc'\ninfo: installed component 'rustc'",
            stderr: "", exitCode: 0)

        // Act
        let result = try await service.installToolchain(name: "stable")

        // Assert
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(mockRunner.runCalls.count, 1)

        let call = mockRunner.runCalls.first
        XCTAssertEqual(call?.executable, fakeRustupPath)
        XCTAssertEqual(call?.arguments, ["toolchain", "install", "stable"])
    }

    func testUninstallToolchain() async throws {
        // Arrange
        mockRunner.nextResult = ProcessResult(
            stdout: "info: uninstalling toolchain 'stable'", stderr: "", exitCode: 0)

        // Act
        let result = try await service.uninstallToolchain(name: "stable")

        // Assert
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(mockRunner.runCalls.first?.arguments, ["toolchain", "uninstall", "stable"])
    }

    func testAddComponent() async throws {
        // Arrange
        mockRunner.nextResult = ProcessResult(stdout: "", stderr: "", exitCode: 0)

        // Act
        let result = try await service.addComponent(
            componentName: "clippy", toolchainName: "stable")

        // Assert
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(
            mockRunner.runCalls.first?.arguments,
            ["component", "add", "clippy", "--toolchain", "stable"])
    }
}
