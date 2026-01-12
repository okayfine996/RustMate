//
//  ProjectCargoViewModel.swift
//  RustMate
//
//  ViewModel for Cargo build configuration
//

import Foundation
import Combine

@MainActor
class ProjectCargoViewModel: ObservableObject {
    private let service: CargoConfigService
    private var currentProjectPath: String?
    
    @Published var config: ProjectCargoConfig?
    @Published var isLoading = false
    @Published var error: Error?
    
    init(service: CargoConfigService = LocalCargoConfigService()) {
        self.service = service
    }
    
    // MARK: - Configuration Loading
    
    func loadConfig(projectPath: String) async {
        currentProjectPath = projectPath
        isLoading = true
        error = nil
        
        do {
            config = try await service.readCargoConfig(projectPath: projectPath)
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
            try await service.writeCargoConfig(projectPath: projectPath, config: config)
        } catch {
            self.error = error
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Configuration Updates
    
    func updateRegistryMirror(_ mirror: ProjectCargoConfig.RegistryMirror?) {
        if config == nil {
            config = ProjectCargoConfig()
        }
        config?.registryMirror = mirror
    }
    
    func addAlias(name: String, command: String) {
        if config == nil {
            config = ProjectCargoConfig()
        }
        guard var currentConfig = config else { return }
        currentConfig.aliases[name] = command
        config = currentConfig
    }
    
    func removeAlias(_ name: String) {
        guard var currentConfig = config else { return }
        currentConfig.aliases.removeValue(forKey: name)
        config = currentConfig
    }
    
    func updateLinker(_ linker: ProjectCargoConfig.LinkerOption?) {
        if config == nil {
            config = ProjectCargoConfig()
        }
        config?.linker = linker
    }
    
    func updateRustflags(_ rustflags: String?) {
        if config == nil {
            config = ProjectCargoConfig()
        }
        config?.rustflags = rustflags?.isEmpty == true ? nil : rustflags
    }
    
    func updateProxySettings(_ proxy: ProjectCargoConfig.ProxySettings?) {
        if config == nil {
            config = ProjectCargoConfig()
        }
        config?.proxySettings = proxy
    }
    
    func updateStripSymbols(_ enabled: Bool?) {
        if config == nil {
            config = ProjectCargoConfig()
        }
        config?.stripSymbols = enabled
    }
    
    // MARK: - Validation
    
    func validateAlias(_ alias: String) -> Bool {
        return service.validateAlias(alias)
    }
}
