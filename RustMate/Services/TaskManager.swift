//
//  TaskManager.swift
//  RustMate
//
//  Singleton for centralized task tracking and event broadcasting
//

import Foundation
import Combine

@MainActor
class TaskManager: ObservableObject {
    static let shared = TaskManager()

    /// Published stream of task updates
    let taskPublisher = PassthroughSubject<TaskRecord, Never>()

    private init() {}

    /// Add or update a task
    func addTask(_ task: TaskRecord) {
        taskPublisher.send(task)
    }

    /// Convenience method to add task from TaskResult
    func addTask(from result: TaskResult) {
        if let record = result.taskRecord {
            addTask(record)
        }
    }
}
