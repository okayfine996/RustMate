//
//  ProjectDiagnosticsViewModel.swift
//  RustMate
//
//  ViewModel for project diagnostics
//

import Foundation
import Combine

@MainActor
class ProjectDiagnosticsViewModel: ObservableObject {
    private let service: DiagnosticsService
    private var currentProjectPath: String?
    
    @Published var diagnostics: ProjectDiagnostics?
    @Published var isLoading = false
    @Published var error: Error?
    
    init(service: DiagnosticsService = ProjectDiagnosticsService()) {
        self.service = service
    }
    
    // MARK: - Diagnostics Loading
    
    func loadDiagnostics(projectPath: String) async {
        currentProjectPath = projectPath
        isLoading = true
        error = nil
        
        do {
            diagnostics = try await service.computeDiagnostics(projectPath: projectPath)
        } catch {
            self.error = error
            diagnostics = nil
        }
        
        isLoading = false
    }
    
    // MARK: - Conflict Resolution
    
    func fixMismatch() async throws {
        guard let projectPath = currentProjectPath else {
            throw NSError(domain: "RustMate", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No project selected"
            ])
        }
        
        isLoading = true
        error = nil
        
        do {
            try await service.clearOverride(projectPath: projectPath)
            // Reload diagnostics after clearing override
            await loadDiagnostics(projectPath: projectPath)
        } catch {
            self.error = error
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    var hasIssues: Bool {
        guard let diagnostics = diagnostics else { return false }
        return diagnostics.hasMismatch || 
               diagnostics.msrvViolation?.isViolation == true ||
               !diagnostics.conflictDetails.isEmpty
    }
    
    var issueCount: Int {
        guard let diagnostics = diagnostics else { return 0 }
        var count = 0
        if diagnostics.hasMismatch { count += 1 }
        if diagnostics.msrvViolation?.isViolation == true { count += 1 }
        count += diagnostics.conflictDetails.count
        return count
    }
}
