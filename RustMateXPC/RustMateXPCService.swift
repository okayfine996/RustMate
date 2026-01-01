//
//  RustMateXPCService.swift
//  RustMateXPC
//
//  Main XPC Service implementation - handles all rustup operations
//

import Foundation

class RustMateXPCService: NSObject, RustMateXPCProtocol {

    // MARK: - Properties

    private let executor: RustupExecutor
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    override init() {
        self.executor = RustupExecutor()
        super.init()
    }

    // MARK: - Environment & Validation

    func ping(reply: @escaping (Bool) -> Void) {
        reply(true)
    }

    func setCargoBookmark(_ bookmarkData: Data?, reply: @escaping (Bool) -> Void) {
        Task {
            await executor.setCargoBookmark(bookmarkData)
            reply(true)
        }
    }

    func validateEnvironment(rustupPath: String?, reply: @escaping (Data?, Error?) -> Void) {
        Task {
            do {
                let result = try await executor.validateEnvironment(rustupPath: rustupPath)
                let data = try encoder.encode(result)
                reply(data, nil)
            } catch {
                reply(nil, error)
            }
        }
    }

    // MARK: - Toolchain Operations

    func listToolchains(reply: @escaping (Data?, Error?) -> Void) {
        Task {
            do {
                let toolchains = try await executor.listToolchains()
                let data = try encoder.encode(toolchains)
                reply(data, nil)
            } catch {
                reply(nil, error)
            }
        }
    }

    func installToolchain(name: String, reply: @escaping (Data) -> Void) {
        Task {
            let result = await executor.installToolchain(name: name)
            if let data = try? encoder.encode(result) {
                reply(data)
            }
        }
    }

    func uninstallToolchain(name: String, reply: @escaping (Data) -> Void) {
        Task {
            let result = await executor.uninstallToolchain(name: name)
            if let data = try? encoder.encode(result) {
                reply(data)
            }
        }
    }

    func setDefaultToolchain(name: String, reply: @escaping (Data) -> Void) {
        Task {
            let result = await executor.setDefaultToolchain(name: name)
            if let data = try? encoder.encode(result) {
                reply(data)
            }
        }
    }

    func updateAllToolchains(reply: @escaping (Data) -> Void) {
        Task {
            let result = await executor.updateAllToolchains()
            if let data = try? encoder.encode(result) {
                reply(data)
            }
        }
    }

    func updateToolchain(name: String, reply: @escaping (Data) -> Void) {
        Task {
            let result = await executor.updateToolchain(name: name)
            if let data = try? encoder.encode(result) {
                reply(data)
            }
        }
    }

    // MARK: - Component Operations

    func listComponents(toolchainName: String, reply: @escaping (Data?, Error?) -> Void) {
        Task {
            do {
                let components = try await executor.listComponents(toolchainName: toolchainName)
                let data = try encoder.encode(components)
                reply(data, nil)
            } catch {
                reply(nil, error)
            }
        }
    }

    func addComponent(componentName: String, toolchainName: String, reply: @escaping (Data) -> Void) {
        Task {
            let result = await executor.addComponent(componentName: componentName, toolchainName: toolchainName)
            if let data = try? encoder.encode(result) {
                reply(data)
            }
        }
    }

    func removeComponent(componentName: String, toolchainName: String, reply: @escaping (Data) -> Void) {
        Task {
            let result = await executor.removeComponent(componentName: componentName, toolchainName: toolchainName)
            if let data = try? encoder.encode(result) {
                reply(data)
            }
        }
    }

    // MARK: - Target Operations

    func listTargets(toolchainName: String, reply: @escaping (Data?, Error?) -> Void) {
        Task {
            do {
                let targets = try await executor.listTargets(toolchainName: toolchainName)
                let data = try encoder.encode(targets)
                reply(data, nil)
            } catch {
                reply(nil, error)
            }
        }
    }

    func addTarget(targetTriple: String, toolchainName: String, reply: @escaping (Data) -> Void) {
        Task {
            let result = await executor.addTarget(targetTriple: targetTriple, toolchainName: toolchainName)
            if let data = try? encoder.encode(result) {
                reply(data)
            }
        }
    }

    func removeTarget(targetTriple: String, toolchainName: String, reply: @escaping (Data) -> Void) {
        Task {
            let result = await executor.removeTarget(targetTriple: targetTriple, toolchainName: toolchainName)
            if let data = try? encoder.encode(result) {
                reply(data)
            }
        }
    }

    // MARK: - Project Context Operations

    func getProjectContext(projectPath: String, reply: @escaping (Data?, Error?) -> Void) {
        Task {
            do {
                let context = try await executor.getProjectContext(projectPath: projectPath)
                let data = try encoder.encode(context)
                reply(data, nil)
            } catch {
                reply(nil, error)
            }
        }
    }

    func setProjectOverride(projectPath: String, toolchainName: String, mode: String, reply: @escaping (Data) -> Void) {
        Task {
            let result = await executor.setProjectOverride(projectPath: projectPath, toolchainName: toolchainName, mode: mode)
            if let data = try? encoder.encode(result) {
                reply(data)
            }
        }
    }

    func clearProjectOverride(projectPath: String, mode: String, reply: @escaping (Data) -> Void) {
        Task {
            let result = await executor.clearProjectOverride(projectPath: projectPath, mode: mode)
            if let data = try? encoder.encode(result) {
                reply(data)
            }
        }
    }

    // MARK: - Task Management

    func cancelTask(taskID: String, reply: @escaping (Bool) -> Void) {
        Task {
            if let uuid = UUID(uuidString: taskID) {
                await executor.cancelTask(taskId: uuid)
            }
            reply(true)
        }
    }
}

// MARK: - NSXPCListenerDelegate

extension RustMateXPCService: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // Validate code signature of connecting process
        guard validateConnection(newConnection) else {
            print("❌ RustMateXPCService: Rejected connection from untrusted process")
            return false
        }

        // Configure the connection
        newConnection.exportedInterface = NSXPCInterface(with: RustMateXPCProtocol.self)
        newConnection.exportedObject = self

        newConnection.resume()
        return true
    }

    /// Validate that the connecting process is authorized
    /// For now, this is a simple validation that accepts connections in DEBUG mode
    /// In production, you should implement stricter code signature validation
    private func validateConnection(_ connection: NSXPCConnection) -> Bool {
        #if DEBUG
        // In DEBUG builds, accept all connections for development
        print("✅ RustMateXPCService: DEBUG mode - accepting connection")
        return true
        #else
        // In RELEASE builds, perform basic validation
        // Check if the process has a valid code signature
        let pid = connection.processIdentifier

        var code: SecCode?
        var attributes = [kSecGuestAttributePid: pid] as CFDictionary
        let status = SecCodeCopyGuestWithAttributes(nil, attributes, [], &code)

        guard status == errSecSuccess, let clientCode = code else {
            print("❌ RustMateXPCService: Failed to get code object for connection")
            return false
        }

        // Check if code is valid and signed
        let validationStatus = SecCodeCheckValidity(clientCode, [], nil)
        if validationStatus == errSecSuccess {
            print("✅ RustMateXPCService: Connection validated successfully")
            return true
        } else {
            print("❌ RustMateXPCService: Code signature validation failed with status: \(validationStatus)")
            return false
        }
        #endif
    }
}
