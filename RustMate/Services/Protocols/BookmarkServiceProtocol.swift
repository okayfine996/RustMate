//
//  BookmarkServiceProtocol.swift
//  RustMate
//
//  Protocol for bookmark management service
//

import Foundation

protocol BookmarkServiceProtocol: Sendable {
    func createBookmark(for url: URL) throws -> Data
    func resolveBookmark(for path: String) throws -> URL
    func hasBookmark(for path: String) -> Bool
    func deleteBookmark(for path: String) throws
}
