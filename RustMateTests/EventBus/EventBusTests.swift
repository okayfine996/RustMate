//
//  EventBusTests.swift
//  RustMateTests
//
//  Unit tests for EventBus
//

import XCTest
import Combine

@testable import RustMate

@MainActor
final class EventBusTests: XCTestCase {

    var eventBus: EventBus!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        eventBus = EventBus.shared
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Basic Event Publishing

    func testPublish_SimpleEvent() {
        // Given
        let expectation = expectation(description: "Event received")
        var receivedEvent: AppEvent?

        eventBus.events
            .sink { event in
                receivedEvent = event
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        eventBus.publish(.openMainWindow)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedEvent, .openMainWindow)
    }

    func testPublish_EventWithAssociatedValue() {
        // Given
        let expectation = expectation(description: "Event received")
        var receivedPurposes: [AuthorizedDirectory.DirectoryPurpose]?

        eventBus.events
            .sink { event in
                if case .authorizationRequired(let purposes) = event {
                    receivedPurposes = purposes
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        eventBus.publish(.authorizationRequired(purposes: [.rustupExecutableDir, .projectAccess]))

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedPurposes?.count, 2)
        XCTAssertTrue(receivedPurposes?.contains(.rustupExecutableDir) ?? false)
        XCTAssertTrue(receivedPurposes?.contains(.projectAccess) ?? false)
    }

    func testPublish_MultipleEvents() {
        // Given
        let expectation = expectation(description: "Events received")
        expectation.expectedFulfillmentCount = 3
        var receivedEvents: [AppEvent] = []

        eventBus.events
            .sink { event in
                receivedEvents.append(event)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        eventBus.publish(.openMainWindow)
        eventBus.publish(.setupCompleted)
        eventBus.publish(.openSettings)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedEvents.count, 3)
        XCTAssertEqual(receivedEvents[0], .openMainWindow)
        XCTAssertEqual(receivedEvents[1], .setupCompleted)
        XCTAssertEqual(receivedEvents[2], .openSettings)
    }

    // MARK: - Subscribe with Filter

    func testSubscribe_WithFilter() {
        // Given
        let expectation = expectation(description: "Filtered event received")
        var receivedEvent: AppEvent?

        _ = eventBus.subscribe(matching: { event in
            if case .authorizationRequired = event {
                return true
            }
            return false
        }) { event in
            receivedEvent = event
            expectation.fulfill()
        }

        // When
        eventBus.publish(.openMainWindow) // Should be filtered out
        eventBus.publish(.authorizationRequired(purposes: [.rustupExecutableDir]))

        // Then
        wait(for: [expectation], timeout: 1.0)
        if case .authorizationRequired = receivedEvent {
            // Success
        } else {
            XCTFail("Expected authorizationRequired event")
        }
    }

    func testSubscribe_SpecificEvent() {
        // Given
        let expectation = expectation(description: "Specific event received")
        var eventReceived = false

        _ = eventBus.subscribe(to: .setupCompleted) {
            eventReceived = true
            expectation.fulfill()
        }

        // When
        eventBus.publish(.openMainWindow) // Should not trigger
        eventBus.publish(.setupCompleted) // Should trigger

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(eventReceived)
    }

    // MARK: - Multiple Subscribers

    func testMultipleSubscribers_AllReceiveEvent() {
        // Given
        let expectation1 = expectation(description: "Subscriber 1")
        let expectation2 = expectation(description: "Subscriber 2")
        let expectation3 = expectation(description: "Subscriber 3")

        var count1 = 0
        var count2 = 0
        var count3 = 0

        eventBus.events
            .sink { _ in
                count1 += 1
                expectation1.fulfill()
            }
            .store(in: &cancellables)

        eventBus.events
            .sink { _ in
                count2 += 1
                expectation2.fulfill()
            }
            .store(in: &cancellables)

        eventBus.events
            .sink { _ in
                count3 += 1
                expectation3.fulfill()
            }
            .store(in: &cancellables)

        // When
        eventBus.publish(.openMainWindow)

        // Then
        wait(for: [expectation1, expectation2, expectation3], timeout: 1.0)
        XCTAssertEqual(count1, 1)
        XCTAssertEqual(count2, 1)
        XCTAssertEqual(count3, 1)
    }

    // MARK: - Event Equality

    func testAppEvent_Equality_SimpleEvents() {
        XCTAssertEqual(AppEvent.openMainWindow, AppEvent.openMainWindow)
        XCTAssertEqual(AppEvent.setupCompleted, AppEvent.setupCompleted)
        XCTAssertEqual(AppEvent.settingsReset, AppEvent.settingsReset)

        XCTAssertNotEqual(AppEvent.openMainWindow, AppEvent.openSettings)
        XCTAssertNotEqual(AppEvent.setupCompleted, AppEvent.settingsReset)
    }

    func testAppEvent_Equality_WithAssociatedValues() {
        let event1 = AppEvent.authorizationRequired(purposes: [.rustupExecutableDir])
        let event2 = AppEvent.authorizationRequired(purposes: [.rustupExecutableDir])
        let event3 = AppEvent.authorizationRequired(purposes: [.projectAccess])

        XCTAssertEqual(event1, event2)
        XCTAssertNotEqual(event1, event3)
    }

    func testAppEvent_Equality_AuthorizationCompleted() {
        let event1 = AppEvent.authorizationCompleted(purpose: .rustupExecutableDir)
        let event2 = AppEvent.authorizationCompleted(purpose: .rustupExecutableDir)
        let event3 = AppEvent.authorizationCompleted(purpose: .projectAccess)

        XCTAssertEqual(event1, event2)
        XCTAssertNotEqual(event1, event3)
    }

    func testAppEvent_Equality_AuthorizationRequested() {
        let event1 = AppEvent.authorizationRequested(purposes: [.rustupExecutableDir], scope: "test")
        let event2 = AppEvent.authorizationRequested(purposes: [.rustupExecutableDir], scope: "test")
        let event3 = AppEvent.authorizationRequested(purposes: [.rustupExecutableDir], scope: "other")
        let event4 = AppEvent.authorizationRequested(purposes: [.projectAccess], scope: "test")

        XCTAssertEqual(event1, event2)
        XCTAssertNotEqual(event1, event3) // Different scope
        XCTAssertNotEqual(event1, event4) // Different purposes
    }

    // MARK: - Event History

    func testEventHistory_RecordsEvents() {
        // Given
        let initialHistoryCount = eventBus.getEventHistory().count

        // When
        eventBus.publish(.openMainWindow)
        eventBus.publish(.setupCompleted)

        // Then
        let history = eventBus.getEventHistory()
        XCTAssertEqual(history.count, initialHistoryCount + 2)
    }

    func testEventHistory_IncludesTimestamps() {
        // Given
        let beforePublish = Date()

        // When
        eventBus.publish(.openMainWindow)

        // Then
        let history = eventBus.getEventHistory()
        if let lastEntry = history.last {
            XCTAssertGreaterThanOrEqual(lastEntry.timestamp, beforePublish)
        } else {
            XCTFail("History should not be empty")
        }
    }

    // MARK: - Cancellable Behavior

    func testSubscription_Cancellable() {
        // Given
        var eventCount = 0
        let subscription = eventBus.events
            .sink { _ in
                eventCount += 1
            }

        // When - Before cancellation
        eventBus.publish(.openMainWindow)
        XCTAssertEqual(eventCount, 1)

        // Cancel subscription
        subscription.cancel()

        // When - After cancellation
        eventBus.publish(.openSettings)

        // Then - Should not receive second event
        XCTAssertEqual(eventCount, 1)
    }

    // MARK: - Performance

    func testPerformance_PublishingManyEvents() {
        measure {
            for _ in 0..<1000 {
                eventBus.publish(.openMainWindow)
            }
        }
    }

    func testPerformance_ManySubscribers() {
        // Given
        for _ in 0..<100 {
            eventBus.events
                .sink { _ in }
                .store(in: &cancellables)
        }

        // Then
        measure {
            eventBus.publish(.openMainWindow)
        }
    }
}
