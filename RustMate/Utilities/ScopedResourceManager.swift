//
//  ScopedResourceManager.swift
//  RustMate
//
//  RAII-style security-scoped resource management
//  Automatically manages startAccessingSecurityScopedResource/stopAccessingSecurityScopedResource
//

import Foundation

/// RAII-style security-scoped resource manager
/// Automatically releases resources when going out of scope
final class ScopedResource {
    let url: URL

    /// Initialize and begin accessing the security-scoped resource
    /// - Parameter url: The security-scoped URL to access
    /// - Throws: If unable to access the resource
    init(url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(
                domain: "ScopedResource",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to access security-scoped resource at \(url.path)"]
            )
        }
        self.url = url
    }

    /// Automatically release the resource when deinitializing
    deinit {
        url.stopAccessingSecurityScopedResource()
    }

    /// Execute work that requires access to the resource
    /// Resource is automatically released after the closure completes
    /// - Parameters:
    ///   - url: The security-scoped URL to access
    ///   - work: Closure to execute with access to the URL
    /// - Returns: Result of the work closure
    /// - Throws: If unable to access resource or if work throws
    static func withAccess<T>(
        to url: URL,
        work: (URL) throws -> T
    ) throws -> T {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(
                domain: "ScopedResource",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to access security-scoped resource at \(url.path)"]
            )
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        return try work(url)
    }

    /// Async version: Execute async work that requires access to the resource
    /// Resource is automatically released after the async closure completes
    /// - Parameters:
    ///   - url: The security-scoped URL to access
    ///   - work: Async closure to execute with access to the URL
    /// - Returns: Result of the async work closure
    /// - Throws: If unable to access resource or if work throws
    static func withAccess<T>(
        to url: URL,
        work: (URL) async throws -> T
    ) async throws -> T {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(
                domain: "ScopedResource",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to access security-scoped resource at \(url.path)"]
            )
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        return try await work(url)
    }
}

/// Helper extension for resolving and accessing bookmarks
extension ScopedResource {

    /// Resolve a security-scoped bookmark and execute work with access to it
    /// - Parameters:
    ///   - bookmarkData: The bookmark data to resolve
    ///   - work: Closure to execute with the resolved URL
    /// - Returns: Tuple of (result, isStale) where result is the work output and isStale indicates if bookmark needs updating
    /// - Throws: If unable to resolve bookmark, access resource, or if work throws
    static func withBookmark<T>(
        _ bookmarkData: Data,
        work: (URL) throws -> T
    ) throws -> (result: T, isStale: Bool) {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        let result = try withAccess(to: url, work: work)
        return (result, isStale)
    }

    /// Async version: Resolve a security-scoped bookmark and execute async work with access to it
    /// - Parameters:
    ///   - bookmarkData: The bookmark data to resolve
    ///   - work: Async closure to execute with the resolved URL
    /// - Returns: Tuple of (result, isStale) where result is the work output and isStale indicates if bookmark needs updating
    /// - Throws: If unable to resolve bookmark, access resource, or if work throws
    static func withBookmark<T>(
        _ bookmarkData: Data,
        work: (URL) async throws -> T
    ) async throws -> (result: T, isStale: Bool) {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        let result = try await withAccess(to: url, work: work)
        return (result, isStale)
    }
}
