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
        print("🔍 BookmarkManager: Creating bookmark - path: \(url.path)")

        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        // Save to Keychain
        try saveToKeychain(bookmarkData, for: url.path)

        print("✅ BookmarkManager: Bookmark created successfully - path: \(url.path), size: \(bookmarkData.count) bytes")
        return bookmarkData
    }

    // MARK: - Bookmark Resolution

    /// Resolves a bookmark for the given path
    func resolveBookmark(for path: String) throws -> URL {
        print("🔍 BookmarkManager: Resolving bookmark - path: \(path)")

        let bookmarkData = try loadFromKeychain(for: path)

        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        if isStale {
            print("⚠️ BookmarkManager: Bookmark is stale, refreshing - path: \(path)")
            // Refresh the bookmark
            let newBookmarkData = try createBookmark(for: url)
            try saveToKeychain(newBookmarkData, for: path)
            print("✅ BookmarkManager: Stale bookmark refreshed - path: \(path)")
        } else {
            print("✅ BookmarkManager: Bookmark resolved successfully - path: \(path)")
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
        print("🔍 BookmarkManager: Deleting bookmark - path: \(path)")

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: path,
            kSecAttrService as String: "com.finefine.RustMate.bookmarks"
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            print("❌ BookmarkManager: Failed to delete bookmark - path: \(path), status: \(status)")
            throw BookmarkError.keychainError(status: status)
        }

        if status == errSecItemNotFound {
            print("🔍 BookmarkManager: Bookmark already deleted or doesn't exist - path: \(path)")
        } else {
            print("✅ BookmarkManager: Bookmark deleted successfully - path: \(path)")
        }
    }

    // MARK: - Keychain Operations

    private func saveToKeychain(_ data: Data, for path: String) throws {
        // Delete existing item first (ignore error if item doesn't exist)
        do {
            try deleteBookmark(for: path)
            print("🔍 BookmarkManager: Removed existing bookmark before save - path: \(path)")
        } catch let BookmarkError.keychainError(status) where status == errSecItemNotFound {
            // Item doesn't exist yet, this is expected
            print("🔍 BookmarkManager: No existing bookmark to remove (expected) - path: \(path)")
        } catch {
            // Log other deletion errors but continue with save
            let errorType = type(of: error)
            print("⚠️ BookmarkManager: Failed to delete existing bookmark during save, continuing anyway - path: \(path), error: \(errorType) - \(error.localizedDescription)")
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: path,
            kSecAttrService as String: "com.finefine.RustMate.bookmarks",
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("❌ BookmarkManager: Failed to save bookmark to keychain - path: \(path), status: \(status)")
            throw BookmarkError.keychainError(status: status)
        }

        print("✅ BookmarkManager: Successfully saved bookmark to keychain - path: \(path)")
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
