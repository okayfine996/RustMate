//
//  XPCToolchainService.swift
//  RustMate
//
//  XPC client wrapper for toolchain operations
//
//  ⚠️ LEGACY: This implementation is deprecated as of 002-process-rustup.
//  RustMate now uses LocalRustupToolchainService for in-app sandboxed execution.
//  This file is kept for reference only.
//

import Foundation

@available(*, deprecated, message: "Use LocalRustupToolchainService instead")
class XPCToolchainService: RustToolchainServiceProtocol {
    private let xpcClient = XPCClient.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // MARK: - Toolchain Operations

    func listToolchains() async throws -> [ToolchainInfo] {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCToolchainService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.listToolchains { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: NSError(domain: "XPCToolchainService", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "No data received from XPC service"
                    ]))
                    return
                }

                do {
                    let toolchains = try self.decoder.decode([ToolchainInfo].self, from: data)
                    continuation.resume(returning: toolchains)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func installToolchain(name: String) async throws -> TaskResult {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCToolchainService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.installToolchain(name: name) { data in
                do {
                    let result = try self.decoder.decode(TaskResult.self, from: data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func uninstallToolchain(name: String) async throws -> TaskResult {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCToolchainService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.uninstallToolchain(name: name) { data in
                do {
                    let result = try self.decoder.decode(TaskResult.self, from: data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func setDefaultToolchain(name: String) async throws -> TaskResult {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCToolchainService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.setDefaultToolchain(name: name) { data in
                do {
                    let result = try self.decoder.decode(TaskResult.self, from: data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func updateAllToolchains() async throws -> TaskResult {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCToolchainService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.updateAllToolchains { data in
                do {
                    let result = try self.decoder.decode(TaskResult.self, from: data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func updateToolchain(name: String) async throws -> TaskResult {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCToolchainService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.updateToolchain(name: name) { data in
                do {
                    let result = try self.decoder.decode(TaskResult.self, from: data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Component Operations

    func listComponents(toolchainName: String) async throws -> [ComponentInfo] {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCToolchainService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.listComponents(toolchainName: toolchainName) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: NSError(domain: "XPCToolchainService", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "No data received from XPC service"
                    ]))
                    return
                }

                do {
                    let components = try self.decoder.decode([ComponentInfo].self, from: data)
                    continuation.resume(returning: components)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func addComponent(componentName: String, toolchainName: String) async throws -> TaskResult {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCToolchainService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.addComponent(componentName: componentName, toolchainName: toolchainName) { data in
                do {
                    let result = try self.decoder.decode(TaskResult.self, from: data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func removeComponent(componentName: String, toolchainName: String) async throws -> TaskResult {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCToolchainService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.removeComponent(componentName: componentName, toolchainName: toolchainName) { data in
                do {
                    let result = try self.decoder.decode(TaskResult.self, from: data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Target Operations

    func listTargets(toolchainName: String) async throws -> [TargetInfo] {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCToolchainService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.listTargets(toolchainName: toolchainName) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: NSError(domain: "XPCToolchainService", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "No data received from XPC service"
                    ]))
                    return
                }

                do {
                    let targets = try self.decoder.decode([TargetInfo].self, from: data)
                    continuation.resume(returning: targets)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func addTarget(targetTriple: String, toolchainName: String) async throws -> TaskResult {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCToolchainService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.addTarget(targetTriple: targetTriple, toolchainName: toolchainName) { data in
                do {
                    let result = try self.decoder.decode(TaskResult.self, from: data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func removeTarget(targetTriple: String, toolchainName: String) async throws -> TaskResult {
        guard let proxy = xpcClient.getProxy() else {
            throw NSError(domain: "XPCToolchainService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to connect to XPC service"
            ])
        }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.removeTarget(targetTriple: targetTriple, toolchainName: toolchainName) { data in
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
