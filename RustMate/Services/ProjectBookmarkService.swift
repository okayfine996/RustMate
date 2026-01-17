//
//  ProjectBookmarkService.swift
//  RustMate
//
//  Service for managing project bookmark persistence and validation
//  Extracted from ProjectsViewModel for single responsibility
//

import Foundation

/// Service for managing project bookmarks
/// Handles CRUD operations and persistence for project bookmarks
@MainActor
class ProjectBookmarkService {

    // MARK: - Persistence

    /// Load all project bookmarks from persistent storage
    /// - Returns: Array of project bookmarks
    func loadBookmarks() -> [ProjectBookmark] {
        return AppUserDefaults.shared.projectBookmarks
    }

    /// Save project bookmarks to persistent storage
    /// - Parameter bookmarks: Array of bookmarks to save
    func saveBookmarks(_ bookmarks: [ProjectBookmark]) {
        AppUserDefaults.shared.projectBookmarks = bookmarks
    }

    // MARK: - Creation

    /// Create a new project bookmark for the given URL
    /// - Parameter url: The project directory URL
    /// - Returns: The created bookmark
    /// - Throws: If unable to create bookmark or access resource
    func createBookmark(for url: URL) throws -> ProjectBookmark {
        // Validate directory exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AppError.projectNotFound(path: url.path)
        }

        // Create bookmark with automatic resource management
        return try ScopedResource.withAccess(to: url) { url in
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            return ProjectBookmark(
                id: UUID(),
                path: url.path,
                displayName: url.lastPathComponent,
                bookmarkData: bookmarkData,
                addedDate: Date(),
                isFavorite: false
            )
        }
    }

    // MARK: - Validation

    /// Check if a project at the given path already exists in the bookmark list
    /// - Parameters:
    ///   - path: The project path to check
    ///   - bookmarks: The current list of bookmarks
    /// - Returns: True if a bookmark for this path already exists
    func isDuplicatePath(_ path: String, in bookmarks: [ProjectBookmark]) -> Bool {
        return bookmarks.contains { $0.path == path }
    }

    // MARK: - Update

    /// Update a bookmark with fresh bookmark data
    /// - Parameters:
    ///   - bookmark: The bookmark to update
    ///   - url: The URL with fresh access
    ///   - bookmarks: The current list of bookmarks
    /// - Returns: Updated list of bookmarks
    func updateBookmark(_ bookmark: ProjectBookmark, with url: URL, in bookmarks: [ProjectBookmark]) throws -> [ProjectBookmark] {
        let newBookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        var updatedBookmarks = bookmarks
        if let index = updatedBookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            updatedBookmarks[index].bookmarkData = newBookmarkData
        }

        return updatedBookmarks
    }

    // MARK: - Deletion

    /// Remove a bookmark from the list
    /// - Parameters:
    ///   - bookmark: The bookmark to remove
    ///   - bookmarks: The current list of bookmarks
    /// - Returns: Updated list of bookmarks
    func removeBookmark(_ bookmark: ProjectBookmark, from bookmarks: [ProjectBookmark]) -> [ProjectBookmark] {
        return bookmarks.filter { $0.id != bookmark.id }
    }

    // MARK: - Modification

    /// Toggle the favorite status of a bookmark
    /// - Parameters:
    ///   - bookmark: The bookmark to toggle
    ///   - bookmarks: The current list of bookmarks
    /// - Returns: Updated list of bookmarks
    func toggleFavorite(for bookmark: ProjectBookmark, in bookmarks: [ProjectBookmark]) -> [ProjectBookmark] {
        var updatedBookmarks = bookmarks
        if let index = updatedBookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            updatedBookmarks[index].isFavorite.toggle()
        }
        return updatedBookmarks
    }
}
