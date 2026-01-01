//
//  MockBookmarkService.swift
//  RustMate
//
//  Mock implementation for previews and tests
//

import Foundation

class MockBookmarkService: BookmarkServiceProtocol {
    private var bookmarks: [String: Data] = [:]

    func createBookmark(for url: URL) throws -> Data {
        let bookmarkData = url.path.data(using: .utf8) ?? Data()
        bookmarks[url.path] = bookmarkData
        return bookmarkData
    }

    func resolveBookmark(for path: String) throws -> URL {
        guard bookmarks[path] != nil else {
            throw NSError(domain: "MockBookmarkService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No bookmark found for path: \(path)"
            ])
        }
        return URL(fileURLWithPath: path)
    }

    func hasBookmark(for path: String) -> Bool {
        return bookmarks[path] != nil
    }

    func deleteBookmark(for path: String) throws {
        bookmarks.removeValue(forKey: path)
    }

    // Test helper
    func reset() {
        bookmarks.removeAll()
    }
}
