//
//  BookmarkManager.swift
//  RustMate
//
//  Manages Security-Scoped Bookmarks with Keychain persistence
//

import Foundation
import Security

class BookmarkManager: BookmarkServiceProtocol {

    // MARK: - Errors

    enum BookmarkError: LocalizedError {
        case creationFailed
        case resolutionFailed
        case accessDenied
        case keychainError(status: OSStatus)

        var errorDescription: String? {
            switch self {
            case .creationFailed:
                return "Failed to create security-scoped bookmark"
            case .resolutionFailed:
                return "Failed to resolve bookmark"
            case .accessDenied:
                return "Access to resource denied"
            case .keychainError(let status):
                return "Keychain error: \(status)"
            }
        }
    }

    // MARK: - Bookmark Creation

    /// Creates a security-scoped bookmark for the given URL
    func createBookmark(for url: URL) throws -> Data {
        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        // Save to Keychain
        try saveToKeychain(bookmarkData, for: url.path)

        return bookmarkData
    }

    // MARK: - Bookmark Resolution

    /// Resolves a bookmark for the given path
    func resolveBookmark(for path: String) throws -> URL {
        let bookmarkData = try loadFromKeychain(for: path)

        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        if isStale {
            // Refresh the bookmark
            let newBookmarkData = try createBookmark(for: url)
            try saveToKeychain(newBookmarkData, for: path)
        }

        return url
    }

    /// Check if a bookmark exists for the given path
    func hasBookmark(for path: String) -> Bool {
        do {
            _ = try loadFromKeychain(for: path)
            return true
        } catch {
            return false
        }
    }

    /// Delete bookmark for the given path
    func deleteBookmark(for path: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: path,
            kSecAttrService as String: "com.finefine.RustMate.bookmarks"
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw BookmarkError.keychainError(status: status)
        }
    }

    // MARK: - Keychain Operations

    private func saveToKeychain(_ data: Data, for path: String) throws {
        // Delete existing item first
        try? deleteBookmark(for: path)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: path,
            kSecAttrService as String: "com.finefine.RustMate.bookmarks",
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BookmarkError.keychainError(status: status)
        }
    }

    private func loadFromKeychain(for path: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: path,
            kSecAttrService as String: "com.finefine.RustMate.bookmarks",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            throw BookmarkError.keychainError(status: status)
        }

        return data
    }
}
