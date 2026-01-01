//
//  XPCProjectContextService.swift
//  RustMate
//
//  XPC client wrapper for project context operations
//

import Foundation

class XPCProjectContextService: ProjectContextServiceProtocol {
    private let xpcClient = XPCClient.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func getProjectContext(projectPath: String) async throws -> ProjectContextInfo {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCProjectContextService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.getProjectContext(projectPath: projectPath) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: NSError(domain: "XPCProjectContextService", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "No data received from XPC service"
                    ]))
                    return
                }

                do {
                    let context = try self.decoder.decode(ProjectContextInfo.self, from: data)
                    continuation.resume(returning: context)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func setProjectOverride(projectPath: String, toolchainName: String, mode: String) async throws -> TaskResult {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCProjectContextService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.setProjectOverride(projectPath: projectPath, toolchainName: toolchainName, mode: mode) { data in
                do {
                    let result = try self.decoder.decode(TaskResult.self, from: data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func clearProjectOverride(projectPath: String, mode: String) async throws -> TaskResult {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCProjectContextService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.clearProjectOverride(projectPath: projectPath, mode: mode) { data in
                do {
                    let result = try self.decoder.decode(TaskResult.self, from: data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
