//
//  ProjectCargoSettingsView.swift
//  RustMate
//
//  View for configuring Cargo build settings (.cargo/config.toml)
//

import SwiftUI

struct ProjectCargoSettingsView: View {
    @StateObject private var viewModel: ProjectCargoViewModel
    let projectPath: String
    
    init(projectPath: String) {
        self.projectPath = projectPath
        _viewModel = StateObject(wrappedValue: ProjectCargoViewModel())
    }
    
    @State private var originalConfig: ProjectCargoConfig?
    @State private var showingAddAlias = false
    @State private var newAliasName = ""
    @State private var newAliasCommand = ""
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
                    // Error display
                    if let error = viewModel.error {
                        errorBanner(error)
                    }
                    
                    // Page Title
                    HStack {
                        Text("Cargo Configuration")
                            .font(.system(size: GlassTokens.Typography.displaySize, weight: .bold))
                            .foregroundColor(GlassTokens.Colors.textPrimary)
                        
                        Spacer()
                        
                        // File indicator
                        Text(".cargo/config.toml")
                            .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, GlassTokens.Spacing.sm)
                            .padding(.vertical, GlassTokens.Spacing.xs)
                            .background(GlassTokens.Colors.accent)
                            .cornerRadius(GlassTokens.Radius.sm)
                    }
                    
                    // Registry Mirror Section
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        Text("Registry Mirror")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                            .foregroundColor(GlassTokens.Colors.textPrimary)
                        
                        registryMirrorSection
                    }
                    
                    // Cargo Aliases Section
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        HStack {
                            Text("Cargo Aliases")
                                .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                                .foregroundColor(GlassTokens.Colors.textPrimary)
                            
                            Spacer()
                            
                            Button("+ Add Alias") {
                                showingAddAlias = true
                            }
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                            .foregroundColor(GlassTokens.Colors.accent)
                            .buttonStyle(.plain)
                        }
                        
                        aliasesSection
                    }
                    
                    // Build & Linker Settings Section
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        Text("Build & Linker Settings")
                            .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                            .foregroundColor(GlassTokens.Colors.textPrimary)
                        
                        buildLinkerSection
                    }
                    
                    // Rustflags Section
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                        HStack(spacing: GlassTokens.Spacing.sm) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: GlassTokens.Typography.headlineSize))
                                .foregroundColor(GlassTokens.Colors.accent)
                            Text("Rustflags")
                                .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                                .foregroundColor(GlassTokens.Colors.textPrimary)
                        }
                        
                        rustflagsSection
                    }
                    
                    // Bottom padding to account for fixed status bar
                    Spacer()
                        .frame(height: 100)
                }
                .padding(GlassTokens.Spacing.xxl)
            }
            
            // Fixed status bar at bottom
            VStack {
                Spacer()
                statusBar
                    .padding(.horizontal, GlassTokens.Spacing.xxl)
                    .padding(.bottom, GlassTokens.Spacing.lg)
            }
        }
        .task {
            await viewModel.loadConfig(projectPath: projectPath)
            originalConfig = viewModel.config
        }
        .onChange(of: viewModel.config) { _, newConfig in
            if originalConfig == nil && newConfig != nil {
                originalConfig = newConfig
            }
        }
        .sheet(isPresented: $showingAddAlias) {
            addAliasSheet
        }
    }
    
    // MARK: - Registry Mirror Section
    
    @ViewBuilder
    private var registryMirrorSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            Text("Select the crate source registry to optimize download speeds.")
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
            
            HStack(spacing: GlassTokens.Spacing.md) {
                ForEach([
                    ProjectCargoConfig.RegistryMirror.cratesIo,
                    .tsinghua,
                    .ustc,
                    .byteDance
                ], id: \.self) { mirror in
                    registryMirrorButton(mirror: mirror)
                }
            }
        }
        .padding(GlassTokens.Spacing.lg)
        .background(GlassTokens.Colors.cardBackground)
        .cornerRadius(GlassTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.lg)
                .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
        )
    }
    
    @ViewBuilder
    private func registryMirrorButton(mirror: ProjectCargoConfig.RegistryMirror) -> some View {
        let isSelected = viewModel.config?.registryMirror == mirror || 
                        (mirror == .cratesIo && viewModel.config?.registryMirror == nil)
        
        Button {
            viewModel.updateRegistryMirror(mirror == .cratesIo ? nil : mirror)
        } label: {
            VStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: mirror.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : GlassTokens.Colors.textPrimary)
                
                Text(mirror.displayText)
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    .foregroundColor(isSelected ? .white : GlassTokens.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(GlassTokens.Spacing.md)
            .background(isSelected ? GlassTokens.Colors.accent : GlassTokens.Colors.backgroundSecondary)
            .cornerRadius(GlassTokens.Radius.md)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Cargo Aliases Section
    
    @ViewBuilder
    private var aliasesSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            if let aliases = viewModel.config?.aliases, !aliases.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    // Table headers
                    HStack(spacing: GlassTokens.Spacing.md) {
                        Text("ALIAS")
                            .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                            .frame(width: 100, alignment: .leading)
                        
                        Text("COMMAND")
                            .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, GlassTokens.Spacing.md)
                    .padding(.vertical, GlassTokens.Spacing.sm)
                    .background(GlassTokens.Colors.backgroundSecondary)
                    
                    // Table rows
                    ForEach(Array(aliases.keys.sorted()), id: \.self) { alias in
                        HStack(spacing: GlassTokens.Spacing.md) {
                            Text(alias)
                                .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                                .foregroundColor(GlassTokens.Colors.accent)
                                .frame(width: 100, alignment: .leading)
                            
                            Text(aliases[alias] ?? "")
                                .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                                .foregroundColor(GlassTokens.Colors.textPrimary)
                            
                            Spacer()
                            
                            Button {
                                viewModel.removeAlias(alias)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(GlassTokens.Colors.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, GlassTokens.Spacing.md)
                        .padding(.vertical, GlassTokens.Spacing.sm)
                        .background(GlassTokens.Colors.cardBackground)
                    }
                }
                .cornerRadius(GlassTokens.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                        .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
                )
            } else {
                Text("No aliases configured")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .padding(GlassTokens.Spacing.md)
            }
        }
        .padding(GlassTokens.Spacing.lg)
        .background(GlassTokens.Colors.cardBackground)
        .cornerRadius(GlassTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.lg)
                .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
        )
    }
    
    // MARK: - Build & Linker Settings Section
    
    @ViewBuilder
    private var buildLinkerSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Use Mold Linker
            buildSettingCard(
                icon: "checkmark.square.fill",
                iconColor: GlassTokens.Colors.accent,
                title: "Use Mold Linker",
                description: "Enable the high-performance mold linker on Linux systems. Significantly reduces linking time.",
                isEnabled: viewModel.config?.linker == .mold,
                onToggle: { enabled in
                    viewModel.updateLinker(enabled ? .mold : nil)
                }
            )
            
            // Strip Symbols
            buildSettingCard(
                icon: "scissors",
                iconColor: .brown,
                title: "Strip Symbols",
                description: "Remove debug symbols from release builds to reduce binary size.",
                isEnabled: viewModel.config?.stripSymbols == true,
                onToggle: { enabled in
                    viewModel.updateStripSymbols(enabled ? true : nil)
                }
            )
        }
        .padding(GlassTokens.Spacing.lg)
        .background(GlassTokens.Colors.cardBackground)
        .cornerRadius(GlassTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.lg)
                .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
        )
    }
    
    @ViewBuilder
    private func buildSettingCard(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        isEnabled: Bool,
        onToggle: @escaping (Bool) -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: GlassTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text(title)
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                Text(description)
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: onToggle
            ))
            .toggleStyle(.switch)
            .tint(GlassTokens.Colors.accent)
        }
        .padding(GlassTokens.Spacing.md)
        .background(GlassTokens.Colors.backgroundSecondary)
        .cornerRadius(GlassTokens.Radius.md)
    }
    
    // MARK: - Rustflags Section
    
    @ViewBuilder
    private var rustflagsSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            Text("Custom compiler flags passed to rustc. Separate multiple flags with spaces.")
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
            
            TextEditor(text: Binding(
                get: { viewModel.config?.rustflags ?? "" },
                set: { viewModel.updateRustflags($0.isEmpty ? nil : $0) }
            ))
            .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
            .frame(height: 120)
            .padding(GlassTokens.Spacing.sm)
            .background(GlassTokens.Colors.backgroundSecondary)
            .cornerRadius(GlassTokens.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                    .stroke(GlassTokens.Colors.divider, lineWidth: GlassTokens.Stroke.thin)
            )
        }
        .padding(GlassTokens.Spacing.lg)
        .background(GlassTokens.Colors.cardBackground)
        .cornerRadius(GlassTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.lg)
                .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
        )
    }
    
    // MARK: - Add Alias Sheet
    
    @ViewBuilder
    private var addAliasSheet: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
            Text("Add Cargo Alias")
                .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                Text("Alias Name")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                TextField("e.g., b", text: $newAliasName)
                    .textFieldStyle(.plain)
                    .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                    .padding(GlassTokens.Spacing.sm)
                    .background(GlassTokens.Colors.backgroundSecondary)
                    .cornerRadius(GlassTokens.Radius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: GlassTokens.Radius.sm)
                            .stroke(GlassTokens.Colors.divider, lineWidth: GlassTokens.Stroke.thin)
                    )
            }
            
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                Text("Command")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                TextField("e.g., build", text: $newAliasCommand)
                    .textFieldStyle(.plain)
                    .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                    .padding(GlassTokens.Spacing.sm)
                    .background(GlassTokens.Colors.backgroundSecondary)
                    .cornerRadius(GlassTokens.Radius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: GlassTokens.Radius.sm)
                            .stroke(GlassTokens.Colors.divider, lineWidth: GlassTokens.Stroke.thin)
                    )
            }
            
            Spacer()
            
            HStack(spacing: GlassTokens.Spacing.md) {
                Button("Cancel") {
                    showingAddAlias = false
                    newAliasName = ""
                    newAliasCommand = ""
                }
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Add") {
                    if !newAliasName.isEmpty && !newAliasCommand.isEmpty {
                        viewModel.addAlias(name: newAliasName, command: newAliasCommand)
                        showingAddAlias = false
                        newAliasName = ""
                        newAliasCommand = ""
                    }
                }
                .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, GlassTokens.Spacing.lg)
                .padding(.vertical, GlassTokens.Spacing.md)
                .background(GlassTokens.Colors.accent)
                .cornerRadius(GlassTokens.Radius.md)
                .buttonStyle(.plain)
                .disabled(newAliasName.isEmpty || newAliasCommand.isEmpty)
            }
        }
        .padding(GlassTokens.Spacing.xxl)
        .frame(width: 500, height: 300)
    }
    
    // MARK: - Status Bar
    
    @ViewBuilder
    private var statusBar: some View {
        SettingsStatusBar(
            hasChanges: hasUnsavedChanges(),
            changeCount: countChanges(),
            statusMessage: hasUnsavedChanges() ? nil : "All systems operational!",
            isLoading: viewModel.isLoading,
            onDiscard: {
                discardChanges()
            },
            onSave: {
                Task {
                    do {
                        try await viewModel.saveConfig()
                        originalConfig = viewModel.config
                    } catch {
                        // Error is handled by viewModel.error
                    }
                }
            }
        )
    }
    
    // MARK: - Change Tracking
    
    private func hasUnsavedChanges() -> Bool {
        guard let current = viewModel.config, let original = originalConfig else {
            return false
        }
        return current != original
    }
    
    private func countChanges() -> Int {
        guard let current = viewModel.config, let original = originalConfig else {
            return 0
        }
        
        var count = 0
        
        if current.registryMirror != original.registryMirror {
            count += 1
        }
        if current.aliases != original.aliases {
            count += 1
        }
        if current.linker != original.linker {
            count += 1
        }
        if current.stripSymbols != original.stripSymbols {
            count += 1
        }
        if current.rustflags != original.rustflags {
            count += 1
        }
        
        return count
    }
    
    private func discardChanges() {
        viewModel.config = originalConfig
    }
    
    // MARK: - Error Banner
    
    @ViewBuilder
    private func errorBanner(_ error: Error) -> some View {
        HStack(spacing: GlassTokens.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(GlassTokens.Colors.error)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Error")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                Text(error.localizedDescription)
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            
            Spacer()
            
            Button {
                viewModel.error = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(GlassTokens.Spacing.md)
        .background(GlassTokens.Colors.errorSubtle)
        .cornerRadius(GlassTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                .stroke(GlassTokens.Colors.error.opacity(0.3), lineWidth: GlassTokens.Stroke.thin)
        )
    }
}

// MARK: - Preview

#Preview {
    ProjectCargoSettingsView(projectPath: "/Users/example/project")
        .frame(width: 800, height: 1000)
}
