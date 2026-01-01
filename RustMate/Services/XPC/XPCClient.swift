//
//  XPCClient.swift
//  RustMate
//
//  Manages NSXPCConnection to RustMateXPC service
//
//  ⚠️ LEGACY: This implementation is deprecated as of 002-process-rustup.
//  RustMate now uses LocalRustupToolchainService and LocalProjectContextService
//  for in-app sandboxed execution via ProcessRunner.
//  This file is kept for reference only.
//

import Foundation

@available(*, deprecated, message: "Use LocalRustupToolchainService or LocalProjectContextService instead")
class XPCClient {
    static let shared = XPCClient()

    private var connection: NSXPCConnection?
    private let queue = DispatchQueue(label: "com.finefine.RustMate.XPCClient")
    private let bookmarkManager = BookmarkManager()

    private init() {
        setupConnection()
    }

    private func setupConnection() {
        let connection = NSXPCConnection(serviceName: "com.finefine.RustMateXPC")

        // Configure the remote object interface
        let interface = NSXPCInterface(with: RustMateXPCProtocol.self)

        // Configure allowed classes for NSSecureCoding
        // For methods that return Data? (encoded models)
        let allowedClasses = NSSet(array: [
            NSData.self,
            NSError.self,
            NSString.self,
            NSNumber.self,
            NSArray.self,
            NSDictionary.self
        ]) as Set

        // Set allowed classes for reply blocks that return Data
        interface.setClasses(allowedClasses, for: #selector(RustMateXPCProtocol.listToolchains(reply:)), argumentIndex: 0, ofReply: true)
        interface.setClasses(allowedClasses, for: #selector(RustMateXPCProtocol.listComponents(toolchainName:reply:)), argumentIndex: 0, ofReply: true)
        interface.setClasses(allowedClasses, for: #selector(RustMateXPCProtocol.listTargets(toolchainName:reply:)), argumentIndex: 0, ofReply: true)
        interface.setClasses(allowedClasses, for: #selector(RustMateXPCProtocol.validateEnvironment(rustupPath:reply:)), argumentIndex: 0, ofReply: true)
        interface.setClasses(allowedClasses, for: #selector(RustMateXPCProtocol.getProjectContext(projectPath:reply:)), argumentIndex: 0, ofReply: true)

        connection.remoteObjectInterface = interface

        connection.invalidationHandler = { [weak self] in
            print("⚠️ XPCClient: Connection invalidated, reconnecting...")
            self?.setupConnection()
        }

        connection.interruptionHandler = { [weak self] in
            print("⚠️ XPCClient: Connection interrupted, reconnecting...")
            self?.setupConnection()
        }

        connection.resume()
        self.connection = connection

        print("✅ XPCClient: Connection established")

        // Send bookmark after connection is established
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.sendCargoBookmark()
        }
    }

    func getProxy() -> RustMateXPCProtocol? {
        return connection?.remoteObjectProxyWithErrorHandler { error in
            print("XPC proxy error: \(error)")
        } as? RustMateXPCProtocol
    }

    /// Send cargo bookmark to XPC service for security-scoped resource access
    func sendCargoBookmark() {
        let cargoPath = NSString(string: "~/.cargo/bin").expandingTildeInPath

        // Check if bookmark exists
        guard bookmarkManager.hasBookmark(for: cargoPath) else {
            print("⚠️ XPCClient: No cargo bookmark found, XPC service will try direct access (will likely fail in sandbox)")
            return
        }

        print("🔍 XPCClient: Found cargo bookmark for \(cargoPath)")

        // Try to resolve bookmark to get the bookmark data
        guard let url = try? bookmarkManager.resolveBookmark(for: cargoPath) else {
            print("❌ XPCClient: Failed to resolve cargo bookmark")
            return
        }

        print("🔍 XPCClient: Resolved bookmark to URL: \(url.path)")

        // Create fresh bookmark data from the URL
        guard let bookmarkData = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else {
            print("❌ XPCClient: Failed to create bookmark data")
            return
        }

        print("🔍 XPCClient: Created bookmark data (\(bookmarkData.count) bytes)")

        // Send bookmark to XPC service
        guard let proxy = getProxy() else {
            print("❌ XPCClient: No XPC proxy available")
            return
        }

        print("🔍 XPCClient: Sending bookmark to XPC service...")
        proxy.setCargoBookmark(bookmarkData) { success in
            if success {
                print("✅ XPCClient: Successfully sent cargo bookmark to XPC service")
            } else {
                print("❌ XPCClient: Failed to send cargo bookmark to XPC service")
            }
        }
    }

    /// Update cargo bookmark (call this when bookmark is created/updated)
    func updateCargoBookmark() {
        sendCargoBookmark()
    }

    deinit {
        connection?.invalidate()
    }
}
