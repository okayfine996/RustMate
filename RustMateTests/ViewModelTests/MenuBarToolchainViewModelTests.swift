//
//  MenuBarToolchainViewModelTests.swift
//  RustMateTests
//
//  Unit tests for MenuBarToolchainViewModel
//

import XCTest
@testable import RustMate

@MainActor
final class MenuBarToolchainViewModelTests: XCTestCase {

    // MARK: - Test: Default Toolchain Derivation

    func testLoadState_DerivesDefaultToolchain() async throws {
        // Given: Mock service with multiple toolchains, one marked as default
        let mockService = TestMockToolchainService()
        mockService.toolchainsToReturn = [
            ToolchainInfo(name: "stable", isDefault: false),
            ToolchainInfo(name: "beta", isDefault: true),
            ToolchainInfo(name: "nightly", isDefault: false)
        ]

        let viewModel = MenuBarToolchainViewModel(service: mockService)

        // When: Load state
        await viewModel.loadState()

        // Then: Default toolchain should be "beta"
        XCTAssertEqual(viewModel.currentDefaultToolchainId, "beta")
        XCTAssertEqual(viewModel.toolchains.count, 3)
        XCTAssertEqual(viewModel.status, .idle)
        XCTAssertNil(viewModel.lastError)
    }

    func testLoadState_NoDefaultToolchain() async throws {
        // Given: Mock service with no default toolchain
        let mockService = TestMockToolchainService()
        mockService.toolchainsToReturn = [
            ToolchainInfo(name: "stable", isDefault: false),
            ToolchainInfo(name: "nightly", isDefault: false)
        ]

        let viewModel = MenuBarToolchainViewModel(service: mockService)

        // When: Load state
        await viewModel.loadState()

        // Then: Current default should be nil
        XCTAssertNil(viewModel.currentDefaultToolchainId)
        XCTAssertEqual(viewModel.toolchains.count, 2)
    }

    // MARK: - Test: Concurrent Switching Strategy

    func testSwitchDefaultToolchain_RejectsConcurrentRequests() async throws {
        // Given: Mock service that delays switch operation
        let mockService = TestMockToolchainService()
        mockService.toolchainsToReturn = [
            ToolchainInfo(name: "stable", isDefault: true),
            ToolchainInfo(name: "beta", isDefault: false)
        ]
        mockService.switchDelay = 0.5 // 500ms delay

        let viewModel = MenuBarToolchainViewModel(service: mockService)
        await viewModel.loadState()

        // When: Start first switch
        Task {
            await viewModel.switchDefaultToolchain(to: "beta")
        }

        // Small delay to ensure first switch is in progress
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then: Status should be switching
        XCTAssertEqual(viewModel.status, .switching)

        // When: Try to start second switch while first is in progress
        await viewModel.switchDefaultToolchain(to: "stable")

        // Then: Second switch should be rejected (status still switching from first operation)
        XCTAssertEqual(viewModel.status, .switching)
    }

    func testSwitchDefaultToolchain_ValidatesToolchainId() async throws {
        // Given: Mock service with known toolchains
        let mockService = TestMockToolchainService()
        mockService.toolchainsToReturn = [
            ToolchainInfo(name: "stable", isDefault: true),
            ToolchainInfo(name: "beta", isDefault: false)
        ]

        let viewModel = MenuBarToolchainViewModel(service: mockService)
        await viewModel.loadState()

        // When: Try to switch to unknown toolchain
        await viewModel.switchDefaultToolchain(to: "unknown-toolchain")

        // Then: Switch should be rejected, status remains idle
        XCTAssertEqual(viewModel.status, .idle)
        XCTAssertEqual(viewModel.currentDefaultToolchainId, "stable")
    }

    // MARK: - Test: Switch Success Path

    func testSwitchDefaultToolchain_Success() async throws {
        // Given: Mock service
        let mockService = TestMockToolchainService()
        mockService.toolchainsToReturn = [
            ToolchainInfo(name: "stable", isDefault: true),
            ToolchainInfo(name: "beta", isDefault: false)
        ]

        let viewModel = MenuBarToolchainViewModel(service: mockService)
        await viewModel.loadState()

        // When: Switch to beta
        await viewModel.switchDefaultToolchain(to: "beta")

        // Then: Default should be updated after refresh
        XCTAssertEqual(viewModel.currentDefaultToolchainId, "beta")
        XCTAssertEqual(viewModel.status, .idle)
        XCTAssertNil(viewModel.lastError)
    }

    // MARK: - Test: Switch Failure Path

    func testSwitchDefaultToolchain_Failure_PreservesOldDefault() async throws {
        // Given: Mock service that will fail the switch
        let mockService = TestMockToolchainService()
        mockService.toolchainsToReturn = [
            ToolchainInfo(name: "stable", isDefault: true),
            ToolchainInfo(name: "beta", isDefault: false)
        ]
        mockService.shouldFailSwitch = true

        let viewModel = MenuBarToolchainViewModel(service: mockService)
        await viewModel.loadState()

        let originalDefault = viewModel.currentDefaultToolchainId

        // When: Switch to beta (will fail)
        await viewModel.switchDefaultToolchain(to: "beta")

        // Then: Default should remain as stable, error should be set
        XCTAssertEqual(viewModel.currentDefaultToolchainId, originalDefault)
        XCTAssertEqual(viewModel.status, .error)
        XCTAssertNotNil(viewModel.lastError)
    }

    // MARK: - Test: Error Presentation

    func testErrorPresentation_ProvidesStructuredError() async throws {
        // Given: Mock service that will fail
        let mockService = TestMockToolchainService()
        mockService.shouldFailLoad = true

        let viewModel = MenuBarToolchainViewModel(service: mockService)

        // When: Load state (will fail)
        await viewModel.loadState()

        // Then: Error presentation should be available
        XCTAssertNotNil(viewModel.errorPresentation)
        XCTAssertEqual(viewModel.status, .error)

        if let presentation = viewModel.errorPresentation {
            XCTAssertFalse(presentation.title.isEmpty)
            XCTAssertFalse(presentation.message.isEmpty)
        }
    }

    // MARK: - Test: Toolchain Options

    func testToolchainOptions_ReturnsCorrectStructure() async throws {
        // Given: Mock service with toolchains
        let mockService = TestMockToolchainService()
        mockService.toolchainsToReturn = [
            ToolchainInfo(name: "stable", isDefault: true),
            ToolchainInfo(name: "beta", isDefault: false),
            ToolchainInfo(name: "nightly", isDefault: false)
        ]

        let viewModel = MenuBarToolchainViewModel(service: mockService)
        await viewModel.loadState()

        // When: Get toolchain options
        let options = viewModel.toolchainOptions()

        // Then: Options should match toolchains
        XCTAssertEqual(options.count, 3)
        XCTAssertEqual(options[0].id, "stable")
        XCTAssertTrue(options[0].isDefault)
        XCTAssertEqual(options[1].id, "beta")
        XCTAssertFalse(options[1].isDefault)
        XCTAssertTrue(options[1].isSelectable)
    }

    func testToolchainOptions_DisablesSelectionWhenSwitching() async throws {
        // Given: Mock service
        let mockService = TestMockToolchainService()
        mockService.toolchainsToReturn = [
            ToolchainInfo(name: "stable", isDefault: true),
            ToolchainInfo(name: "beta", isDefault: false)
        ]
        mockService.switchDelay = 1.0 // Long delay

        let viewModel = MenuBarToolchainViewModel(service: mockService)
        await viewModel.loadState()

        // When: Start switch
        Task {
            await viewModel.switchDefaultToolchain(to: "beta")
        }

        // Small delay to ensure switch is in progress
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then: Options should not be selectable
        let options = viewModel.toolchainOptions()
        XCTAssertFalse(options.allSatisfy { $0.isSelectable })
    }
}

// MARK: - Test Mock Service

class TestMockToolchainService: RustToolchainServiceProtocol {
    var toolchainsToReturn: [ToolchainInfo] = []
    var switchDelay: TimeInterval = 0.5
    var shouldFailSwitch = false
    var shouldFailLoad = false

    func listToolchains() async throws -> [ToolchainInfo] {
        if shouldFailLoad {
            throw NSError(domain: "TestMock", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock load failure"])
        }
        return toolchainsToReturn
    }

    func setDefaultToolchain(name: String) async throws -> TaskResult {
        try await Task.sleep(nanoseconds: UInt64(switchDelay * 1_000_000_000))

        if shouldFailSwitch {
            return TaskResult(
                taskId: UUID(),
                toolchainName: name,
                operation: "setDefault",
                status: .failed,
                startTime: Date().addingTimeInterval(-switchDelay),
                endTime: Date(),
                exitCode: 1,
                stdoutSnippet: nil,
                stderrSnippet: "error: failed to set default toolchain",
                errorMessage: "Mock switch failure"
            )
        }

        // Update toolchains to reflect new default
        toolchainsToReturn = toolchainsToReturn.map { toolchain in
            ToolchainInfo(
                id: toolchain.id,
                name: toolchain.name,
                version: toolchain.version,
                isDefault: toolchain.name == name,
                installDate: toolchain.installDate,
                host: toolchain.host
            )
        }

        return TaskResult(
            taskId: UUID(),
            toolchainName: name,
            operation: "setDefault",
            status: .success,
            startTime: Date().addingTimeInterval(-switchDelay),
            endTime: Date(),
            exitCode: 0,
            stdoutSnippet: "info: default toolchain set to '\(name)'",
            stderrSnippet: nil,
            errorMessage: nil
        )
    }

    // Required protocol methods (minimal implementation)
    func installToolchain(name: String) async throws -> TaskResult {
        TaskResult(exitCode: 0)
    }

    func uninstallToolchain(name: String) async throws -> TaskResult {
        TaskResult(exitCode: 0)
    }

    func updateAllToolchains() async throws -> TaskResult {
        TaskResult(exitCode: 0)
    }

    func updateToolchain(name: String) async throws -> TaskResult {
        TaskResult(exitCode: 0)
    }

    func listComponents(toolchainName: String) async throws -> [ComponentInfo] {
        []
    }

    func addComponent(componentName: String, toolchainName: String) async throws -> TaskResult {
        TaskResult(exitCode: 0)
    }

    func removeComponent(componentName: String, toolchainName: String) async throws -> TaskResult {
        TaskResult(exitCode: 0)
    }

    func listTargets(toolchainName: String) async throws -> [TargetInfo] {
        []
    }

    func addTarget(targetTriple: String, toolchainName: String) async throws -> TaskResult {
        TaskResult(exitCode: 0)
    }

    func removeTarget(targetTriple: String, toolchainName: String) async throws -> TaskResult {
        TaskResult(exitCode: 0)
    }
}
