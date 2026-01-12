//
//  ProjectToolchainViewModel.swift
//  RustMate
//
//  ViewModel for project toolchain configuration
//

import Foundation
import Combine

@MainActor
class ProjectToolchainViewModel: ObservableObject {
    private let service: ToolchainConfigService
    private var currentProjectPath: String?
    
    @Published var config: ProjectToolchainConfig?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var availableTargets: [TargetInfo] = []
    @Published var isLoadingTargets = false
    
    private let targetService = LocalRustupToolchainService()
    
    init(service: ToolchainConfigService = LocalToolchainConfigService()) {
        self.service = service
    }
    
    // MARK: - Configuration Loading
    
    func loadConfig(projectPath: String) async {
        currentProjectPath = projectPath
        isLoading = true
        error = nil
        
        do {
            config = try await service.readToolchainConfig(projectPath: projectPath)
        } catch {
            self.error = error
            config = nil
        }
        
        isLoading = false
    }
    
    // MARK: - Configuration Saving
    
    func saveConfig() async throws {
        guard let projectPath = currentProjectPath, var config = config else {
            throw NSError(domain: "RustMate", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No project selected or configuration missing"
            ])
        }
        
        // Validate before saving
        let validationErrors = config.validate()
        if !validationErrors.isEmpty {
            throw ConfigError.validationError(validationErrors.joined(separator: "; "))
        }
        
        isLoading = true
        error = nil
        
        do {
            try await service.writeToolchainConfig(projectPath: projectPath, config: config)
        } catch {
            self.error = error
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Configuration Updates
    
    func updateChannel(_ channel: ProjectToolchainConfig.ToolchainChannel?) {
        if config == nil {
            config = ProjectToolchainConfig()
        }
        config?.channel = channel
    }
    
    func updateVersion(_ version: String?) {
        if config == nil {
            config = ProjectToolchainConfig()
        }
        config?.version = version?.isEmpty == true ? nil : version
    }
    
    func toggleComponent(_ component: String) {
        if config == nil {
            config = ProjectToolchainConfig()
        }
        if var components = config?.components {
            if let index = components.firstIndex(of: component) {
                components.remove(at: index)
            } else {
                components.append(component)
            }
            config?.components = components
        } else {
            config?.components = [component]
        }
    }
    
    func addTarget(_ target: String) {
        if config == nil {
            config = ProjectToolchainConfig()
        }
        if var targets = config?.targets {
            if !targets.contains(target) {
                targets.append(target)
            }
            config?.targets = targets
        } else {
            config?.targets = [target]
        }
    }
    
    func removeTarget(_ target: String) {
        if var targets = config?.targets {
            targets.removeAll { $0 == target }
            config?.targets = targets
        }
    }
    
    func toggleTarget(_ target: String) {
        if config == nil {
            config = ProjectToolchainConfig()
        }
        if var targets = config?.targets {
            if let index = targets.firstIndex(of: target) {
                targets.remove(at: index)
            } else {
                targets.append(target)
            }
            config?.targets = targets
        } else {
            config?.targets = [target]
        }
    }
    
    func updateProfile(_ profile: ProjectToolchainConfig.ToolchainProfile?) {
        if config == nil {
            config = ProjectToolchainConfig()
        }
        config?.profile = profile
    }
    
    // MARK: - Target Loading
    
    func loadAvailableTargets() async {
        guard let channel = config?.channel else {
            // If no channel is set, try to use default toolchain
            await loadTargetsForToolchain("stable")
            return
        }
        
        let toolchainName = channel.rawValue
        await loadTargetsForToolchain(toolchainName)
    }
    
    private func loadTargetsForToolchain(_ toolchainName: String) async {
        isLoadingTargets = true
        error = nil
        
        do {
            availableTargets = try await targetService.listTargets(toolchainName: toolchainName)
        } catch {
            // Don't set error here, just log it - target loading is optional
            print("Failed to load targets: \(error)")
            availableTargets = []
        }
        
        isLoadingTargets = false
    }
    
    // MARK: - Validation
    
    func validateVersion(_ version: String) -> Bool {
        return service.validateVersion(version)
    }
}
