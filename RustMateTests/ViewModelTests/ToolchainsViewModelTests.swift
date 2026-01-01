//
//  ToolchainViewModelTests.swift
//  RustMateTests
//
//  Unit tests for ToolchainViewModel
//

import XCTest
@testable import RustMate

@MainActor
final class ToolchainViewModelTests: XCTestCase {

    var viewModel: ToolchainViewModel!
    var mockService: MockToolchainService!

    override func setUp() async throws {
        mockService = MockToolchainService()
        viewModel = ToolchainViewModel(service: mockService)
    }

    override func tearDown() async throws {
        viewModel = nil
        mockService = nil
    }

    // MARK: - Load Toolchains Tests

    func testLoadToolchains_Success() async throws {
        // Given
        let expectedToolchains = [
            ToolchainInfo(name: "stable-aarch64-apple-darwin", version: nil, isDefault: true, host: "aarch64-apple-darwin"),
            ToolchainInfo(name: "nightly-aarch64-apple-darwin", version: nil, isDefault: false, host: "aarch64-apple-darwin")
        ]
        mockService.toolchainsToReturn = expectedToolchains

        // When
        await viewModel.loadToolchains()

        // Then
        XCTAssertEqual(viewModel.toolchains.count, 2)
        XCTAssertEqual(viewModel.toolchains.first?.name, "stable-aarch64-apple-darwin")
        XCTAssertTrue(viewModel.toolchains.first?.isDefault ?? false)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testLoadToolchains_Empty() async throws {
        // Given
        mockService.toolchainsToReturn = []

        // When
        await viewModel.loadToolchains()

        // Then
        XCTAssertTrue(viewModel.toolchains.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testLoadToolchains_Error() async throws {
        // Given
        mockService.shouldThrowError = true
        mockService.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])

        // When
        await viewModel.loadToolchains()

        // Then
        XCTAssertTrue(viewModel.toolchains.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
    }

    func testLoadToolchains_SetsLoadingState() async throws {
        // Given
        mockService.delayInSeconds = 0.1
        mockService.toolchainsToReturn = []

        // When
        let loadTask = Task {
            await viewModel.loadToolchains()
        }

        // Check loading state is true during load
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01s
        XCTAssertTrue(viewModel.isLoading)

        await loadTask.value

        // Then loading state should be false after completion
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Install Toolchain Tests

    func testInstallToolchain_Success() async throws {
        // Given
        let toolchainName = "stable"
        mockService.taskResultToReturn = TaskResult(
            taskId: UUID(),
            toolchainName: toolchainName,
            operation: "install",
            status: .success,
            exitCode: 0
        )

        // When
        await viewModel.installToolchain(name: toolchainName)

        // Then
        XCTAssertEqual(mockService.lastInstalledToolchain, toolchainName)
        XCTAssertNil(viewModel.error)
    }

    func testInstallToolchain_ReloadsAfterSuccess() async throws {
        // Given
        let toolchainName = "nightly"
        mockService.taskResultToReturn = TaskResult(
            taskId: UUID(),
            toolchainName: toolchainName,
            operation: "install",
            status: .success,
            exitCode: 0
        )
        mockService.toolchainsToReturn = [
            ToolchainInfo(name: "stable-aarch64-apple-darwin", version: nil, isDefault: true, host: "aarch64-apple-darwin"),
            ToolchainInfo(name: "nightly-aarch64-apple-darwin", version: nil, isDefault: false, host: "aarch64-apple-darwin")
        ]

        // When
        await viewModel.installToolchain(name: toolchainName)

        // Then
        XCTAssertEqual(viewModel.toolchains.count, 2)
        XCTAssertTrue(mockService.loadToolchainsCalled)
    }

    func testInstallToolchain_Error() async throws {
        // Given
        mockService.shouldThrowError = true
        mockService.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Install failed"])

        // When
        await viewModel.installToolchain(name: "beta")

        // Then
        XCTAssertNotNil(viewModel.error)
    }

    // MARK: - Uninstall Toolchain Tests

    func testUninstallToolchain_Success() async throws {
        // Given
        let toolchain = ToolchainInfo(name: "beta-aarch64-apple-darwin", version: nil, isDefault: false, host: "aarch64-apple-darwin")
        mockService.taskResultToReturn = TaskResult(
            taskId: UUID(),
            toolchainName: toolchain.name,
            operation: "uninstall",
            status: .success,
            exitCode: 0
        )

        // When
        await viewModel.uninstallToolchain(toolchain)

        // Then
        XCTAssertEqual(mockService.lastUninstalledToolchain, toolchain.name)
        XCTAssertNil(viewModel.error)
    }

    func testUninstallToolchain_ReloadsAfterSuccess() async throws {
        // Given
        let toolchain = ToolchainInfo(name: "nightly-aarch64-apple-darwin", version: nil, isDefault: false, host: "aarch64-apple-darwin")
        mockService.taskResultToReturn = TaskResult(
            taskId: UUID(),
            toolchainName: toolchain.name,
            operation: "uninstall",
            status: .success,
            exitCode: 0
        )
        mockService.toolchainsToReturn = [
            ToolchainInfo(name: "stable-aarch64-apple-darwin", version: nil, isDefault: true, host: "aarch64-apple-darwin")
        ]

        // When
        await viewModel.uninstallToolchain(toolchain)

        // Then
        XCTAssertEqual(viewModel.toolchains.count, 1)
        XCTAssertTrue(mockService.loadToolchainsCalled)
    }

    func testUninstallToolchain_Error() async throws {
        // Given
        let toolchain = ToolchainInfo(name: "stable-aarch64-apple-darwin", version: nil, isDefault: true, host: "aarch64-apple-darwin")
        mockService.shouldThrowError = true
        mockService.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Uninstall failed"])

        // When
        await viewModel.uninstallToolchain(toolchain)

        // Then
        XCTAssertNotNil(viewModel.error)
    }

    // MARK: - Set Default Toolchain Tests

    func testSetDefaultToolchain_Success() async throws {
        // Given
        let toolchain = ToolchainInfo(name: "nightly-aarch64-apple-darwin", version: nil, isDefault: false, host: "aarch64-apple-darwin")
        mockService.taskResultToReturn = TaskResult(
            taskId: UUID(),
            toolchainName: toolchain.name,
            operation: "setDefault",
            status: .success,
            exitCode: 0
        )

        // When
        await viewModel.setDefaultToolchain(toolchain)

        // Then
        XCTAssertEqual(mockService.lastDefaultToolchain, toolchain.name)
        XCTAssertNil(viewModel.error)
    }

    func testSetDefaultToolchain_ReloadsAfterSuccess() async throws {
        // Given
        let toolchain = ToolchainInfo(name: "nightly-aarch64-apple-darwin", version: nil, isDefault: false, host: "aarch64-apple-darwin")
        mockService.taskResultToReturn = TaskResult(
            taskId: UUID(),
            toolchainName: toolchain.name,
            operation: "setDefault",
            status: .success,
            exitCode: 0
        )
        mockService.toolchainsToReturn = [
            ToolchainInfo(name: "stable-aarch64-apple-darwin", version: nil, isDefault: false, host: "aarch64-apple-darwin"),
            ToolchainInfo(name: "nightly-aarch64-apple-darwin", version: nil, isDefault: true, host: "aarch64-apple-darwin")
        ]

        // When
        await viewModel.setDefaultToolchain(toolchain)

        // Then
        let defaultToolchain = viewModel.toolchains.first { $0.isDefault }
        XCTAssertEqual(defaultToolchain?.name, "nightly-aarch64-apple-darwin")
        XCTAssertTrue(mockService.loadToolchainsCalled)
    }

    func testSetDefaultToolchain_Error() async throws {
        // Given
        let toolchain = ToolchainInfo(name: "beta-aarch64-apple-darwin", version: nil, isDefault: false, host: "aarch64-apple-darwin")
        mockService.shouldThrowError = true
        mockService.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Set default failed"])

        // When
        await viewModel.setDefaultToolchain(toolchain)

        // Then
        XCTAssertNotNil(viewModel.error)
    }

    // MARK: - Update All Toolchains Tests

    func testUpdateAllToolchains_Success() async throws {
        // Given
        mockService.taskResultToReturn = TaskResult(
            taskId: UUID(),
            operation: "updateAll",
            status: .success,
            exitCode: 0
        )

        // When
        await viewModel.updateAllToolchains()

        // Then
        XCTAssertTrue(mockService.updateAllToolchainsCalled)
        XCTAssertNil(viewModel.error)
    }

    func testUpdateAllToolchains_ReloadsAfterSuccess() async throws {
        // Given
        mockService.taskResultToReturn = TaskResult(
            taskId: UUID(),
            operation: "updateAll",
            status: .success,
            exitCode: 0
        )
        mockService.toolchainsToReturn = [
            ToolchainInfo(name: "stable-aarch64-apple-darwin", version: nil, isDefault: true, host: "aarch64-apple-darwin")
        ]

        // When
        await viewModel.updateAllToolchains()

        // Then
        XCTAssertTrue(mockService.loadToolchainsCalled)
    }

    func testUpdateAllToolchains_Error() async throws {
        // Given
        mockService.shouldThrowError = true
        mockService.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Update failed"])

        // When
        await viewModel.updateAllToolchains()

        // Then
        XCTAssertNotNil(viewModel.error)
    }
}

// MARK: - Mock Service

@MainActor
class MockToolchainService: RustToolchainServiceProtocol {
    var toolchainsToReturn: [ToolchainInfo] = []
    var componentsToReturn: [ComponentInfo] = []
    var targetsToReturn: [TargetInfo] = []
    var taskResultToReturn: TaskResult = TaskResult(exitCode: 0)
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: 1)
    var delayInSeconds: TimeInterval = 0

    var loadToolchainsCalled = false
    var lastInstalledToolchain: String?
    var lastUninstalledToolchain: String?
    var lastDefaultToolchain: String?
    var lastUpdatedToolchain: String?
    var updateAllToolchainsCalled = false

    // MARK: - Toolchain Operations

    func listToolchains() async throws -> [ToolchainInfo] {
        loadToolchainsCalled = true

        if delayInSeconds > 0 {
            try await Task.sleep(nanoseconds: UInt64(delayInSeconds * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        return toolchainsToReturn
    }

    func installToolchain(name: String) async throws -> TaskResult {
        lastInstalledToolchain = name

        if shouldThrowError {
            throw errorToThrow
        }

        return taskResultToReturn
    }

    func uninstallToolchain(name: String) async throws -> TaskResult {
        lastUninstalledToolchain = name

        if shouldThrowError {
            throw errorToThrow
        }

        return taskResultToReturn
    }

    func setDefaultToolchain(name: String) async throws -> TaskResult {
        lastDefaultToolchain = name

        if shouldThrowError {
            throw errorToThrow
        }

        return taskResultToReturn
    }

    func updateAllToolchains() async throws -> TaskResult {
        updateAllToolchainsCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        return taskResultToReturn
    }

    func updateToolchain(name: String) async throws -> TaskResult {
        lastUpdatedToolchain = name

        if shouldThrowError {
            throw errorToThrow
        }

        return taskResultToReturn
    }

    // MARK: - Component Operations

    func listComponents(toolchainName: String) async throws -> [ComponentInfo] {
        if shouldThrowError {
            throw errorToThrow
        }
        return componentsToReturn
    }

    func addComponent(componentName: String, toolchainName: String) async throws -> TaskResult {
        if shouldThrowError {
            throw errorToThrow
        }
        return taskResultToReturn
    }

    func removeComponent(componentName: String, toolchainName: String) async throws -> TaskResult {
        if shouldThrowError {
            throw errorToThrow
        }
        return taskResultToReturn
    }

    // MARK: - Target Operations

    func listTargets(toolchainName: String) async throws -> [TargetInfo] {
        if shouldThrowError {
            throw errorToThrow
        }
        return targetsToReturn
    }

    func addTarget(targetTriple: String, toolchainName: String) async throws -> TaskResult {
        if shouldThrowError {
            throw errorToThrow
        }
        return taskResultToReturn
    }

    func removeTarget(targetTriple: String, toolchainName: String) async throws -> TaskResult {
        if shouldThrowError {
            throw errorToThrow
        }
        return taskResultToReturn
    }
}
