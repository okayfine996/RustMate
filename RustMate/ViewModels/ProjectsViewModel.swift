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
    private let service = XPCProjectContextService()
    private let taskManager = TaskManager.shared

    // State
    @Published var projects: [ProjectBookmark] = []
    @Published var selectedProject: ProjectBookmark?
    @Published var projectContext: ProjectContextInfo?
    @Published var isLoading = false
    @Published var error: Error?

    // Override mode setting (from UserDefaults)
    var overrideMode: String {
        get {
            UserDefaults.standard.string(forKey: "overrideMode") ?? "toolchainFile"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "overrideMode")
        }
    }

    init() {
        loadBookmarks()
    }

    // MARK: - Bookmark Management

    func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: "projectBookmarks"),
           let decoded = try? JSONDecoder().decode([ProjectBookmark].self, from: data) {
            projects = decoded
        }
    }

    func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: "projectBookmarks")
        }
    }

    func addBookmark(url: URL) {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            error = NSError(domain: "RustMate", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to access security-scoped resource"
            ])
            return
        }

        // Create bookmark data
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            let bookmark = ProjectBookmark(
                id: UUID(),
                path: url.path,
                displayName: url.lastPathComponent,
                bookmarkData: bookmarkData,
                addedDate: Date()
            )

            projects.append(bookmark)
            saveBookmarks()

            url.stopAccessingSecurityScopedResource()
        } catch {
            self.error = error
            url.stopAccessingSecurityScopedResource()
        }
    }

    func removeBookmark(_ bookmark: ProjectBookmark) {
        projects.removeAll { $0.id == bookmark.id }
        saveBookmarks()

        if selectedProject?.id == bookmark.id {
            selectedProject = nil
            projectContext = nil
        }
    }

    // MARK: - Project Context Operations

    func loadProjectContext() async {
        guard let project = selectedProject else { return }

        isLoading = true
        error = nil

        do {
            // Resolve bookmark and access resource
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: project.bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "RustMate", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to access project directory"
                ])
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            // Get project context
            let context = try await service.getProjectContext(projectPath: url.path)
            projectContext = context

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
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: project.bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "RustMate", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to access project directory"
                ])
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

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
        } catch {
            self.error = error
        }
    }

    func clearOverride() async {
        guard let project = selectedProject else { return }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: project.bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "RustMate", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to access project directory"
                ])
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

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
        } catch {
            self.error = error
        }
    }

    // MARK: - Helper Methods

    private func updateBookmark(_ bookmark: ProjectBookmark, with url: URL) {
        do {
            let newBookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            if let index = projects.firstIndex(where: { $0.id == bookmark.id }) {
                projects[index].bookmarkData = newBookmarkData
                saveBookmarks()
            }
        } catch {
            print("Failed to update bookmark: \(error)")
        }
    }
}
