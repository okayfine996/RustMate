//
//  ProjectsViewModel.swift
//  RustMate
//
//  ViewModel for project context management
//

import Foundation
import Combine

@MainActor
class ProjectsViewModel: ObservableObject {
    private var service: LocalProjectContextService
    private let taskManager = TaskManager.shared
    private let bookmarkService = ProjectBookmarkService()

    // State
    @Published var projects: [ProjectBookmark] = []
    @Published var selectedProject: ProjectBookmark?
    @Published var projectContext: ProjectContextInfo?
    @Published var isLoading = false
    @Published var error: Error?

    // Override mode setting (from UserDefaults)
    var overrideMode: String {
        get {
            AppUserDefaults.shared.overrideMode
        }
        set {
            AppUserDefaults.shared.overrideMode = newValue
        }
    }

    init() {
        self.service = LocalProjectContextService()
        loadBookmarks()
    }

    // MARK: - Settings Management

    /// Refresh the service with latest settings (call after authorization)
    func refreshSettings() {
        self.service = LocalProjectContextService()
        print("🔄 ProjectsViewModel: Refreshed service with latest settings")
    }

    // MARK: - Bookmark Management

    func loadBookmarks() {
        projects = bookmarkService.loadBookmarks()
        // Don't auto-select here - let the view handle it after it's ready
    }

    func autoSelectFirstIfNeeded() {
        if selectedProject == nil && !projects.isEmpty {
            selectedProject = projects.first
        }
    }

    private func saveBookmarks() {
        bookmarkService.saveBookmarks(projects)
    }

    func addBookmark(url: URL) {
        // Check for duplicates
        if bookmarkService.isDuplicatePath(url.path, in: projects) {
            error = AppError.projectAlreadyAdded(path: url.path)
            return
        }

        // Create bookmark using service
        do {
            let bookmark = try bookmarkService.createBookmark(for: url)
            projects.append(bookmark)
            saveBookmarks()

            // Auto-select if this is the only project
            if projects.count == 1 {
                selectedProject = bookmark
            }
        } catch {
            self.error = error
        }
    }

    func removeBookmark(_ bookmark: ProjectBookmark) {
        projects = bookmarkService.removeBookmark(bookmark, from: projects)
        saveBookmarks()

        if selectedProject?.id == bookmark.id {
            // Auto-select first project after removal if list is not empty
            selectedProject = projects.first
            projectContext = nil
        }
    }

    func toggleFavorite(_ bookmark: ProjectBookmark) {
        projects = bookmarkService.toggleFavorite(for: bookmark, in: projects)
        saveBookmarks()
    }

    // MARK: - Project Context Operations

    func loadProjectContext() async {
        guard let project = selectedProject else { return }

        isLoading = true
        error = nil

        do {
            // Resolve bookmark and access resource with automatic management
            let (url, isStale) = try await ScopedResource.withBookmark(project.bookmarkData) { url in
                // Get project context
                let context = try await service.getProjectContext(projectPath: url.path)
                projectContext = context

                return url
            }

            // Update bookmark if stale
            if isStale {
                updateBookmark(project, with: url)
            }
        } catch {
            self.error = error
            projectContext = nil
        }

        isLoading = false
    }

    func refreshProjectContext() async {
        await loadProjectContext()
    }

    func setOverride(toolchainName: String) async {
        guard let project = selectedProject else { return }

        do {
            try await ScopedResource.withBookmark(project.bookmarkData) { url in
                // Execute set override operation
                let taskResult = try await service.setProjectOverride(
                    projectPath: url.path,
                    toolchainName: toolchainName,
                    mode: overrideMode
                )

                // Convert TaskResult to TaskRecord and register
                if let taskRecord = taskResult.taskRecord {
                    taskManager.addTask(taskRecord)
                }

                // Reload context if successful
                if taskResult.status == .success {
                    await loadProjectContext()
                } else {
                    error = NSError(domain: "RustMate", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: taskResult.errorMessage ?? "Failed to set override"
                    ])
                }
            }
        } catch {
            self.error = error
        }
    }

    func clearOverride() async {
        guard let project = selectedProject else { return }

        do {
            try await ScopedResource.withBookmark(project.bookmarkData) { url in
                // Execute clear override operation
                let taskResult = try await service.clearProjectOverride(
                    projectPath: url.path,
                    mode: overrideMode
                )

                // Convert TaskResult to TaskRecord and register
                if let taskRecord = taskResult.taskRecord {
                    taskManager.addTask(taskRecord)
                }

                // Reload context if successful
                if taskResult.status == .success {
                    await loadProjectContext()
                } else {
                    error = NSError(domain: "RustMate", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: taskResult.errorMessage ?? "Failed to clear override"
                    ])
                }
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Helper Methods

    private func updateBookmark(_ bookmark: ProjectBookmark, with url: URL) {
        do {
            projects = try bookmarkService.updateBookmark(bookmark, with: url, in: projects)
            saveBookmarks()
        } catch {
            print("Failed to update bookmark: \(error)")
        }
    }
}
