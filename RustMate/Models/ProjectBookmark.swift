//
//  ProjectBookmark.swift
//  RustMate
//
//  Model for persisted project bookmarks with security-scoped access
//

import Foundation

struct ProjectBookmark: Identifiable, Codable, Hashable {
    let id: UUID
    let path: String
    let displayName: String
    var bookmarkData: Data
    let addedDate: Date
    var isFavorite: Bool

    // Health status (computed, not persisted)
    // Note: This is not included in Codable encoding/decoding
    var healthStatus: ProjectHealthStatus?

    // Equatable/Hashable conformance based on id
    static func == (lhs: ProjectBookmark, rhs: ProjectBookmark) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
