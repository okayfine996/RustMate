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
    private var service: LocalProjectContextService  // T054: Replaced XPC with local execution
    private let taskManager = TaskManager.shared
    private let diagnosticsService = ProjectDiagnosticsService()
    private let toolchainConfigService: ToolchainConfigService = LocalToolchainConfigService()

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
        if let data = UserDefaults.standard.data(forKey: "projectBookmarks"),
           let decoded = try? JSONDecoder().decode([ProjectBookmark].self, from: data) {
            projects = decoded
            // Don't auto-select here - let the view handle it after it's ready
        }
    }

    func autoSelectFirstIfNeeded() {
        if selectedProject == nil && !projects.isEmpty {
            selectedProject = projects.first
        }
    }

    func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: "projectBookmarks")
        }
    }

    func addBookmark(url: URL) {
        // Check if directory exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            error = NSError(domain: "RustMate", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Project directory not found. The directory may have been moved or deleted."
            ])
            return
        }
        
        // Check for duplicates by path
        let newPath = url.path
        for existingProject in projects {
            if existingProject.path == newPath {
                error = NSError(domain: "RustMate", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "This project is already in your list."
                ])
                return
            }
        }
        
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
                addedDate: Date(),
                isFavorite: false
            )

            projects.append(bookmark)
            saveBookmarks()

            // Auto-select if this is the only project
            if projects.count == 1 {
                selectedProject = bookmark
            }

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
            // Auto-select first project after removal if list is not empty
            selectedProject = projects.first
            projectContext = nil
        }
    }

    func toggleFavorite(_ bookmark: ProjectBookmark) {
        if let index = projects.firstIndex(where: { $0.id == bookmark.id }) {
            projects[index].isFavorite.toggle()
            saveBookmarks()
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
            
            // Update health status
            await updateHealthStatus(for: project, projectPath: url.path)
        } catch {
            self.error = error
            projectContext = nil
        }

        isLoading = false
    }
    
    // MARK: - Health Status Management
    
    func updateHealthStatus(for project: ProjectBookmark, projectPath: String) async {
        do {
            // Compute diagnostics
            let diagnostics = try await diagnosticsService.computeDiagnostics(projectPath: projectPath)
            
            // Check if toolchain is installed (simplified - check if actual version exists)
            let toolchainInstalled = diagnostics.actualToolchainVersion != nil
            
            // Check if components are available (simplified - assume true if toolchain is installed)
            // TODO: Implement proper component checking
            let componentsAvailable = toolchainInstalled
            
            // Calculate health status
            let healthStatus = ProjectHealthStatus.calculate(
                from: diagnostics,
                toolchainInstalled: toolchainInstalled,
                componentsAvailable: componentsAvailable
            )
            
            // Update project bookmark with health status
            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                projects[index].healthStatus = healthStatus
                saveBookmarks()
            }
        } catch {
            // If health status calculation fails, set to unknown
            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                projects[index].healthStatus = ProjectHealthStatus(
                    status: .unknown,
                    indicatorColor: .yellow,
                    details: "Failed to compute health status: \(error.localizedDescription)"
                )
            }
        }
    }
    
    func refreshHealthStatuses() async {
        for project in projects {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: project.bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                
                await updateHealthStatus(for: project, projectPath: url.path)
            } catch {
                // Skip projects that can't be accessed
                continue
            }
        }
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
