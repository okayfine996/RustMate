//
//  ProjectContextServiceProtocol.swift
//  RustMate
//
//  Protocol for project context service
//

import Foundation

protocol ProjectContextServiceProtocol: Sendable {
    func getProjectContext(projectPath: String) async throws -> ProjectContextInfo
    func setProjectOverride(projectPath: String, toolchainName: String, mode: String) async throws -> TaskResult
    func clearProjectOverride(projectPath: String, mode: String) async throws -> TaskResult
}
