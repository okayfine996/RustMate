//
//  TaskCoordinatorTests.swift
//  RustMateTests
//
//  Unit tests for TaskCoordinator
//

import XCTest
import Combine

@testable import RustMate

@MainActor
final class TaskCoordinatorTests: XCTestCase {

    var coordinator: TaskCoordinator!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        coordinator = TaskCoordinator()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        coordinator = nil
        super.tearDown()
    }

    // MARK: - Success Cases

    func testExecute_Success() async {
        // Given
        let expectation = expectation(description: "Task completed")
        var receivedTasks: [TaskRecord] = []

        // Subscribe to task manager events
        TaskManager.shared.taskPublisher
            .sink { task in
                receivedTasks.append(task)
                if task.status != .running {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let expectedResult = TaskResult(
            taskId: UUID(),
            toolchainName: "stable",
            operation: "install",
            status: .success,
            startTime: Date(),
            endTime: Date(),
            exitCode: 0
        )

        // When
        let result = await coordinator.execute(
            operation: "install",
            target: "stable"
        ) {
            return expectedResult
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.operation, "install")
        XCTAssertEqual(result.toolchainName, "stable")
        XCTAssertEqual(result.exitCode, 0)

        // Verify task manager received 2 tasks (started + completed)
        XCTAssertEqual(receivedTasks.count, 2)

        let startedTask = receivedTasks[0]
        XCTAssertEqual(startedTask.status, .running)
        XCTAssertEqual(startedTask.operation, "install")
        XCTAssertEqual(startedTask.target, "stable")

        let completedTask = receivedTasks[1]
        XCTAssertEqual(completedTask.status, .success)
        XCTAssertEqual(completedTask.operation, "install")
    }

    func testExecute_WithoutTarget() async {
        // Given
        let expectation = expectation(description: "Task completed")
        var receivedTasks: [TaskRecord] = []

        TaskManager.shared.taskPublisher
            .sink { task in
                receivedTasks.append(task)
                if task.status != .running {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let expectedResult = TaskResult(
            taskId: UUID(),
            toolchainName: nil,
            operation: "update",
            status: .success,
            startTime: Date(),
            endTime: Date(),
            exitCode: 0
        )

        // When
        let result = await coordinator.execute(
            operation: "update",
            target: nil
        ) {
            return expectedResult
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.operation, "update")
        XCTAssertNil(result.toolchainName)

        // Verify task manager received tasks
        XCTAssertEqual(receivedTasks.count, 2)

        let startedTask = receivedTasks[0]
        XCTAssertNil(startedTask.target)
    }

    // MARK: - Failure Cases

    func testExecute_ThrowsError() async {
        // Given
        let expectation = expectation(description: "Task completed")
        var receivedTasks: [TaskRecord] = []

        TaskManager.shared.taskPublisher
            .sink { task in
                receivedTasks.append(task)
                if task.status != .running {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let testError = NSError(domain: "TestError", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Test error message"
        ])

        // When
        let result = await coordinator.execute(
            operation: "install",
            target: "nightly"
        ) {
            throw testError
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(result.status, .failed)
        XCTAssertEqual(result.operation, "install")
        XCTAssertEqual(result.toolchainName, "nightly")
        XCTAssertEqual(result.exitCode, -1)
        XCTAssertEqual(result.errorMessage, "Test error message")

        // Verify task manager received 2 tasks (started + failed)
        XCTAssertEqual(receivedTasks.count, 2)

        let failedTask = receivedTasks[1]
        XCTAssertEqual(failedTask.status, .failed)
        XCTAssertEqual(failedTask.errorMessage, "Test error message")
        XCTAssertEqual(failedTask.exitCode, -1)
    }

    func testExecute_ReturnsFailedResult() async {
        // Given
        let expectation = expectation(description: "Task completed")
        var receivedTasks: [TaskRecord] = []

        TaskManager.shared.taskPublisher
            .sink { task in
                receivedTasks.append(task)
                if task.status != .running {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let failedResult = TaskResult(
            taskId: UUID(),
            toolchainName: "beta",
            operation: "uninstall",
            status: .failed,
            startTime: Date(),
            endTime: Date(),
            exitCode: 1,
            errorMessage: "Toolchain not found"
        )

        // When
        let result = await coordinator.execute(
            operation: "uninstall",
            target: "beta"
        ) {
            return failedResult
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(result.status, .failed)
        XCTAssertEqual(result.errorMessage, "Toolchain not found")
        XCTAssertEqual(result.exitCode, 1)

        // Verify task manager received 2 tasks
        XCTAssertEqual(receivedTasks.count, 2)

        let completedTask = receivedTasks[1]
        XCTAssertEqual(completedTask.status, .failed)
    }

    // MARK: - Task Record Validation

    func testExecute_TaskRecordHasCorrectTimestamps() async {
        // Given
        let expectation = expectation(description: "Task completed")
        var receivedTasks: [TaskRecord] = []
        let beforeExecution = Date()

        TaskManager.shared.taskPublisher
            .sink { task in
                receivedTasks.append(task)
                if task.status != .running {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        _ = await coordinator.execute(
            operation: "test",
            target: "target"
        ) {
            // Simulate some work
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return TaskResult(
                taskId: UUID(),
                toolchainName: "target",
                operation: "test",
                status: .success,
                startTime: Date(),
                endTime: Date(),
                exitCode: 0
            )
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        let afterExecution = Date()

        XCTAssertEqual(receivedTasks.count, 2)

        let startedTask = receivedTasks[0]
        let completedTask = receivedTasks[1]

        // Started task should have start time within range
        XCTAssertGreaterThanOrEqual(startedTask.startTime, beforeExecution)
        XCTAssertLessThanOrEqual(startedTask.startTime, afterExecution)

        // Completed task should have end time after start time
        XCTAssertNotNil(completedTask.endTime)
        if let endTime = completedTask.endTime {
            XCTAssertGreaterThanOrEqual(endTime, startedTask.startTime)
        }
    }

    // MARK: - Stderr Processing

    func testExecute_ProcessesStderrForSuggestedFix() async {
        // Given
        let expectation = expectation(description: "Task completed")
        var receivedTasks: [TaskRecord] = []

        TaskManager.shared.taskPublisher
            .sink { task in
                receivedTasks.append(task)
                if task.status != .running {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let resultWithStderr = TaskResult(
            taskId: UUID(),
            toolchainName: "stable",
            operation: "install",
            status: .failed,
            startTime: Date(),
            endTime: Date(),
            exitCode: 1,
            stdoutSnippet: nil,
            stderrSnippet: "error: toolchain 'stable' is already installed",
            errorMessage: "Installation failed"
        )

        // When
        _ = await coordinator.execute(
            operation: "install",
            target: "stable"
        ) {
            return resultWithStderr
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)

        let completedTask = receivedTasks[1]
        XCTAssertNotNil(completedTask.stderrSnippet)
        // suggestedFix should be populated by TaskResult.suggestFix
        XCTAssertNotNil(completedTask.suggestedFix)
    }
}
