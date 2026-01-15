//
//  EventBus.swift
//  RustMate
//
//  Type-safe event bus for app-wide communication
//  Replaces NotificationCenter with compile-time type safety
//

import Combine
import Foundation
import SwiftUI

// MARK: - App Events

/// All events that can occur in the application
/// This enum provides type-safe event definitions with associated values
enum AppEvent: Equatable {

    // MARK: Window Events

    /// Request to open the main application window
    case openMainWindow

    /// Request to open the settings window
    case openSettings

    // MARK: Setup Events

    /// Setup flow has been completed successfully
    case setupCompleted

    // MARK: Authorization Events

    /// Authorization is required (missing or stale)
    /// - Parameter purposes: Array of missing authorization purposes
    case authorizationRequired(purposes: [AuthorizedDirectory.DirectoryPurpose])

    /// Authorization request has been made
    /// - Parameters:
    ///   - purposes: Array of purposes being requested
    ///   - scope: Optional authorization scope
    case authorizationRequested(purposes: [AuthorizedDirectory.DirectoryPurpose], scope: String?)

    /// A single authorization has been completed
    /// - Parameter purpose: The purpose that was authorized
    case authorizationCompleted(purpose: AuthorizedDirectory.DirectoryPurpose)

    /// All authorizations in the queue have been completed
    case allAuthorizationsCompleted

    // MARK: Settings Events

    /// Settings have been reset to defaults
    case settingsReset

    // MARK: - Equatable Implementation

    static func == (lhs: AppEvent, rhs: AppEvent) -> Bool {
        switch (lhs, rhs) {
        case (.openMainWindow, .openMainWindow),
             (.openSettings, .openSettings),
             (.setupCompleted, .setupCompleted),
             (.allAuthorizationsCompleted, .allAuthorizationsCompleted),
             (.settingsReset, .settingsReset):
            return true

        case let (.authorizationRequired(lPurposes), .authorizationRequired(rPurposes)):
            return lPurposes == rPurposes

        case let (.authorizationRequested(lPurposes, lScope), .authorizationRequested(rPurposes, rScope)):
            return lPurposes == rPurposes && lScope == rScope

        case let (.authorizationCompleted(lPurpose), .authorizationCompleted(rPurpose)):
            return lPurpose == rPurpose

        default:
            return false
        }
    }
}

// MARK: - Event Bus

/// Type-safe event bus for app-wide communication
/// Provides a centralized, compile-time safe alternative to NotificationCenter
@MainActor
final class EventBus: ObservableObject {

    /// Shared singleton instance
    static let shared = EventBus()

    /// Internal event subject for publishing events
    private let eventSubject = PassthroughSubject<AppEvent, Never>()

    /// Event history for debugging (last 100 events)
    private var eventHistory: [EventHistoryEntry] = []
    private let maxHistorySize = 100

    private init() {
        #if DEBUG
        // In debug mode, log all events
        eventSubject
            .sink { [weak self] event in
                self?.logEvent(event)
            }
            .store(in: &cancellables)
        #endif
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public API

    /// Publish an event to all subscribers
    /// - Parameter event: The event to publish
    func publish(_ event: AppEvent) {
        print("📢 EventBus: Publishing \(event)")
        eventSubject.send(event)
        recordEventInHistory(event)
    }

    /// Get a publisher for all events
    /// Use this to subscribe to the event stream
    var events: AnyPublisher<AppEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    /// Subscribe to a specific event type
    /// - Parameters:
    ///   - filter: Closure that returns true for events you want to receive
    ///   - handler: Closure called when matching events occur
    /// - Returns: AnyCancellable that must be retained to keep subscription alive
    func subscribe(
        matching filter: @escaping (AppEvent) -> Bool,
        handler: @escaping (AppEvent) -> Void
    ) -> AnyCancellable {
        eventSubject
            .filter(filter)
            .sink(receiveValue: handler)
    }

    /// Subscribe to events of a specific case (without associated values)
    /// - Parameters:
    ///   - eventCase: The event case to match
    ///   - handler: Closure called when the event occurs
    /// - Returns: AnyCancellable that must be retained
    func subscribe(
        to eventCase: AppEvent,
        handler: @escaping () -> Void
    ) -> AnyCancellable {
        eventSubject
            .filter { $0 == eventCase }
            .sink { _ in handler() }
    }

    // MARK: - Debug Support

    private struct EventHistoryEntry {
        let event: AppEvent
        let timestamp: Date
    }

    private func recordEventInHistory(_ event: AppEvent) {
        eventHistory.append(EventHistoryEntry(event: event, timestamp: Date()))
        if eventHistory.count > maxHistorySize {
            eventHistory.removeFirst()
        }
    }

    private func logEvent(_ event: AppEvent) {
        let eventName = String(describing: event)
        print("🔔 EventBus: \(eventName)")
    }

    /// Get recent event history (for debugging)
    func getEventHistory() -> [(event: String, timestamp: Date)] {
        eventHistory.map { (event: String(describing: $0.event), timestamp: $0.timestamp) }
    }
}

// MARK: - SwiftUI Integration

extension View {

    /// Subscribe to a specific app event
    /// - Parameters:
    ///   - event: The event to listen for (without associated values)
    ///   - action: Closure to execute when event occurs
    /// - Returns: Modified view with event subscription
    func onAppEvent(
        _ event: AppEvent,
        perform action: @escaping () -> Void
    ) -> some View {
        self.onReceive(EventBus.shared.events) { receivedEvent in
            if receivedEvent == event {
                action()
            }
        }
    }

    /// Subscribe to app events matching a condition
    /// - Parameters:
    ///   - filter: Closure that returns true for events to handle
    ///   - action: Closure to execute with the matched event
    /// - Returns: Modified view with event subscription
    func onAppEvent(
        matching filter: @escaping (AppEvent) -> Bool,
        perform action: @escaping (AppEvent) -> Void
    ) -> some View {
        self.onReceive(EventBus.shared.events.filter(filter)) { event in
            action(event)
        }
    }

    /// Subscribe to authorization required events
    /// - Parameter action: Closure called with the missing purposes
    /// - Returns: Modified view with event subscription
    func onAuthorizationRequired(
        perform action: @escaping ([AuthorizedDirectory.DirectoryPurpose]) -> Void
    ) -> some View {
        self.onReceive(EventBus.shared.events) { event in
            if case .authorizationRequired(let purposes) = event {
                action(purposes)
            }
        }
    }

    /// Subscribe to authorization completed events
    /// - Parameter action: Closure called with the completed purpose
    /// - Returns: Modified view with event subscription
    func onAuthorizationCompleted(
        perform action: @escaping (AuthorizedDirectory.DirectoryPurpose) -> Void
    ) -> some View {
        self.onReceive(EventBus.shared.events) { event in
            if case .authorizationCompleted(let purpose) = event {
                action(purpose)
            }
        }
    }
}

// MARK: - Migration Helpers

/// Helper to bridge between NotificationCenter and EventBus during migration
extension EventBus {

    /// Post an event and also send equivalent NotificationCenter notification
    /// Use this during migration to support both old and new code
    /// - Parameters:
    ///   - event: The EventBus event to publish
    ///   - notification: The equivalent NotificationCenter notification
    func publishWithLegacy(_ event: AppEvent, notification: NSNotification.Name) {
        publish(event)
        NotificationCenter.default.post(name: notification, object: nil)
    }

    /// Post an event with associated data to both EventBus and NotificationCenter
    /// - Parameters:
    ///   - event: The EventBus event
    ///   - notification: The NotificationCenter notification name
    ///   - userInfo: User info dictionary for NotificationCenter
    func publishWithLegacy(
        _ event: AppEvent,
        notification: NSNotification.Name,
        userInfo: [AnyHashable: Any]?
    ) {
        publish(event)
        NotificationCenter.default.post(name: notification, object: nil, userInfo: userInfo)
    }
}
