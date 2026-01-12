//
//  ProjectToolchainSettingsView.swift
//  RustMate
//
//  View for configuring project toolchain settings (rust-toolchain.toml)
//

import SwiftUI

struct ProjectToolchainSettingsView: View {
    @StateObject private var viewModel: ProjectToolchainViewModel
    let projectPath: String
    
    init(projectPath: String) {
        self.projectPath = projectPath
        _viewModel = StateObject(wrappedValue: ProjectToolchainViewModel())
    }
    
    @StateObject private var diagnosticsViewModel = ProjectDiagnosticsViewModel()
    @State private var showingAddTarget = false
    @State private var selectedTargets: Set<String> = []
    @State private var showingAddComponent = false
    @State private var selectedComponents: Set<String> = []
    @State private var originalConfig: ProjectToolchainConfig?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
                    // Error display
                    if let error = viewModel.error {
                        errorBanner(error)
                    }
                    
                    // Version mismatch warning banner
                    if let diagnostics = diagnosticsViewModel.diagnostics, diagnostics.hasMismatch {
                        versionMismatchBanner(diagnostics: diagnostics)
                    }
                    
                    // Channel Selection
                    channelSection
                    
                    // Version Input
                    versionSection
                    
                    // Components and Targets (side by side)
                    HStack(alignment: .top, spacing: GlassTokens.Spacing.xl) {
                        componentsSection
                            .frame(maxWidth: .infinity)
                        
                        targetsSection
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Profile
                    profileSection
                    
                    // Bottom padding to account for fixed status bar
                    Spacer()
                        .frame(height: 100)
                }
                .padding(GlassTokens.Spacing.xxl)
            }
            
            // Fixed status bar at bottom
            VStack {
                Spacer()
                saveButton
                    .padding(.horizontal, GlassTokens.Spacing.xxl)
                    .padding(.bottom, GlassTokens.Spacing.lg)
            }
        }
        .task {
            await viewModel.loadConfig(projectPath: projectPath)
            originalConfig = viewModel.config
            await diagnosticsViewModel.loadDiagnostics(projectPath: projectPath)
            // Load available targets after config is loaded
            await viewModel.loadAvailableTargets()
        }
        .onChange(of: viewModel.config) { _, newConfig in
            // Track changes - initialize originalConfig if not set
            if originalConfig == nil && newConfig != nil {
                originalConfig = newConfig
            }
        }
        .onChange(of: viewModel.config?.channel) { _, _ in
            // Reload targets when channel changes
            Task {
                await viewModel.loadAvailableTargets()
            }
        }
        .sheet(isPresented: $showingAddTarget) {
            AddTargetView(
                selectedTargets: $selectedTargets,
                currentToolchain: viewModel.config?.channel?.rawValue ?? "stable",
                existingTargets: Set(viewModel.config?.targets ?? []),
                onAdd: { newTargets in
                    for target in newTargets {
                        viewModel.addTarget(target)
                    }
                }
            )
        }
        .sheet(isPresented: $showingAddComponent) {
            AddComponentView(
                selectedComponents: $selectedComponents,
                currentToolchain: viewModel.config?.channel?.rawValue ?? "stable",
                existingComponents: Set(viewModel.config?.components ?? []),
                onAdd: { newComponents in
                    for component in newComponents {
                        viewModel.toggleComponent(component)
                    }
                }
            )
        }
    }
    
    // MARK: - Channel Section
    
    @ViewBuilder
    private var channelSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack {
                Text("Channel")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                Spacer()
                
                Button {
                    // View distribution history
                } label: {
                    Text("View distribution history")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.accent)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: GlassTokens.Spacing.md) {
                channelCard(
                    channel: .stable,
                    title: "Stable",
                    description: "Recommended for production",
                    icon: "checkmark.circle.fill"
                )
                
                channelCard(
                    channel: .beta,
                    title: "Beta",
                    description: "Preview upcoming features",
                    icon: "flask.fill"
                )
                
                channelCard(
                    channel: .nightly,
                    title: "Nightly",
                    description: "Experimental daily builds",
                    icon: "moon.fill"
                )
            }
        }
    }
    
    @ViewBuilder
    private func channelCard(
        channel: ProjectToolchainConfig.ToolchainChannel,
        title: String,
        description: String,
        icon: String
    ) -> some View {
        let isSelected = viewModel.config?.channel == channel
        
        Button {
            viewModel.updateChannel(channel)
        } label: {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                // Top right checkmark for selected state
                HStack {
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: GlassTokens.Typography.headlineSize))
                            .foregroundColor(GlassTokens.Colors.accent)
                    } else {
                        // Placeholder to maintain consistent spacing
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: GlassTokens.Typography.headlineSize))
                            .foregroundColor(.clear)
                    }
                }
                
                // Icon
                HStack {
                    ZStack {
                        Circle()
                            .fill(isSelected ? GlassTokens.Colors.accent.opacity(0.2) : GlassTokens.Colors.backgroundSecondary)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: icon)
                            .font(.system(size: GlassTokens.Typography.titleSize))
                            .foregroundColor(isSelected ? GlassTokens.Colors.accent : GlassTokens.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // Title
                Text(title)
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                // Description
                Text(description)
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(GlassTokens.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
            .background(
                isSelected
                    ? GlassTokens.Colors.selectionBackground
                    : GlassTokens.Colors.cardBackground
            )
            .cornerRadius(GlassTokens.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                    .stroke(
                        isSelected ? GlassTokens.Colors.accent : GlassTokens.Colors.divider,
                        lineWidth: isSelected ? 2 : GlassTokens.Stroke.thin
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Version Section
    
    @ViewBuilder
    private var versionSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            Text("Specific Version (Optional)")
                .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textPrimary)
            
            Text("The toolchain version to use. Leave empty to use the latest version of the selected channel.")
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
            
            TextField("1.75.0", text: Binding(
                get: { viewModel.config?.version ?? "" },
                set: { newValue in
                    viewModel.updateVersion(newValue.isEmpty ? nil : newValue)
                    // Validate on change - error will be set by viewModel if validation fails
                    if !newValue.isEmpty && !viewModel.validateVersion(newValue) {
                        // Validation error will be handled by viewModel.saveConfig()
                    }
                }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
            .padding(GlassTokens.Spacing.md)
            .background(GlassTokens.Colors.backgroundSecondary)
            .cornerRadius(GlassTokens.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: GlassTokens.Radius.sm)
                    .stroke(
                        viewModel.config?.version != nil && !viewModel.validateVersion(viewModel.config?.version ?? "") 
                            ? GlassTokens.Colors.error 
                            : GlassTokens.Colors.divider,
                        lineWidth: GlassTokens.Stroke.thin
                    )
            )
        }
    }
    
    // MARK: - Components Section
    
    @ViewBuilder
    private var componentsSection: some View {
        let configuredComponents = viewModel.config?.components ?? []
        let componentItems = configuredComponents.sorted().map { component in
            SelectionItem(
                id: component,
                name: component,
                description: componentDescription(component),
                isSelected: viewModel.config?.components.contains(component) ?? false,
                onToggle: { viewModel.toggleComponent(component) }
            )
        }
        
        SelectionCardView(
            title: "Components",
            actionButtonTitle: "ADD COMPONENT",
            showOnColumn: true,
            emptyMessage: "No components configured. Click \"ADD COMPONENT\" to add components.",
            items: componentItems,
            onAction: {
                selectedComponents = Set(viewModel.config?.components ?? [])
                showingAddComponent = true
            }
        )
    }
    
    private func componentDescription(_ component: String) -> String? {
        switch component.lowercased() {
        case "rustfmt":
            return "Automatic code formatter"
        case "clippy":
            return "Linting library to catch common mistakes"
        case "rust-src":
            return "Source code for the standard library"
        case "rust-analyzer":
            return "Language server for IDE support"
        case "llvm-tools-preview":
            return "LLVM tools for advanced debugging"
        case "rust-docs":
            return "Standard library documentation"
        default:
            return nil
        }
    }
    
    // MARK: - Targets Section
    
    @ViewBuilder
    private var targetsSection: some View {
        let configuredTargets = viewModel.config?.targets ?? []
        let targetItems = configuredTargets.sorted().map { target in
            SelectionItem(
                id: target,
                name: target,
                description: targetDescription(target),
                isSelected: viewModel.config?.targets.contains(target) ?? false,
                onToggle: { viewModel.toggleTarget(target) }
            )
        }
        
        SelectionCardView(
            title: "Targets",
            actionButtonTitle: "ADD TARGET",
            showOnColumn: true,
            emptyMessage: "No targets configured. Click \"ADD TARGET\" to add compilation targets.",
            items: targetItems,
            onAction: {
                selectedTargets = Set(viewModel.config?.targets ?? [])
                showingAddTarget = true
            }
        )
    }
    
    // MARK: - Helper Functions
    
    private func isHostTarget(_ target: String) -> Bool {
        #if arch(arm64)
        return target == "aarch64-apple-darwin"
        #elseif arch(x86_64)
        return target == "x86_64-apple-darwin"
        #else
        return false
        #endif
    }
    
    private func targetDescription(_ target: String) -> String? {
        let lower = target.lowercased()
        
        // WebAssembly
        if lower.contains("wasm32-unknown-unknown") {
            return "WebAssembly (Generic)"
        } else if lower.contains("wasm32-wasi") {
            return "WebAssembly System Interface"
        }
        
        // Apple platforms
        else if lower.contains("aarch64-apple-darwin") {
            return "macOS (Apple Silicon)"
        } else if lower.contains("x86_64-apple-darwin") {
            return "macOS (Intel)"
        } else if lower.contains("aarch64-apple-ios") {
            return "iOS on ARM64"
        } else if lower.contains("x86_64-apple-ios") {
            return "iOS Simulator"
        }
        
        // Linux
        else if lower.contains("x86_64-unknown-linux-gnu") {
            return "Linux x86_64 (GNU)"
        } else if lower.contains("aarch64-unknown-linux-gnu") {
            return "Linux ARM64 (GNU)"
        } else if lower.contains("x86_64-unknown-linux-musl") {
            return "Linux x86_64 (musl, static linking)"
        } else if lower.contains("aarch64-unknown-linux-musl") {
            return "Linux ARM64 (musl, static linking)"
        }
        
        // Windows
        else if lower.contains("x86_64-pc-windows-msvc") {
            return "Windows x86_64 (MSVC)"
        } else if lower.contains("x86_64-pc-windows-gnu") {
            return "Windows x86_64 (MinGW)"
        } else if lower.contains("i686-pc-windows-msvc") {
            return "Windows 32-bit (MSVC)"
        }
        
        // Android
        else if lower.contains("aarch64-linux-android") {
            return "Android ARM64"
        } else if lower.contains("armv7-linux-androideabi") {
            return "Android ARMv7"
        } else if lower.contains("x86_64-linux-android") {
            return "Android x86_64"
        }
        
        return nil
    }
    
    // MARK: - Profile Section
    
    @ViewBuilder
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            Text("Profile")
                .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textPrimary)
            
            HStack(spacing: GlassTokens.Spacing.md) {
                profileCard(.minimal)
                profileCard(.default)
                profileCard(.complete)
            }
        }
    }
    
    @ViewBuilder
    private func profileCard(_ profile: ProjectToolchainConfig.ToolchainProfile) -> some View {
        let isSelected = viewModel.config?.profile == profile
        
        Button {
            viewModel.updateProfile(profile)
        } label: {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                // Top row: icon and selection indicator
                HStack {
                    Image(systemName: profile.icon)
                        .font(.system(size: GlassTokens.Typography.titleSize))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                    
                    Spacer()
                    
                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: GlassTokens.Typography.headlineSize))
                            .foregroundColor(GlassTokens.Colors.accent)
                    } else {
                        Circle()
                            .stroke(GlassTokens.Colors.textTertiary, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                    }
                }
                
                // Title
                Text(profile.displayText)
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                // Description
                Text(profile.description)
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(isSelected ? GlassTokens.Colors.accent : GlassTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(GlassTokens.Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(
                isSelected
                    ? GlassTokens.Colors.accent.opacity(0.15)
                    : GlassTokens.Colors.backgroundSecondary
            )
            .cornerRadius(GlassTokens.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                    .stroke(
                        isSelected ? GlassTokens.Colors.accent : GlassTokens.Colors.divider,
                        lineWidth: isSelected ? 2 : GlassTokens.Stroke.thin
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Save Button / Status Bar
    
    @ViewBuilder
    private var saveButton: some View {
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
        
        if current.channel != original.channel {
            count += 1
        }
        if current.version != original.version {
            count += 1
        }
        if current.components != original.components {
            count += 1
        }
        if current.targets != original.targets {
            count += 1
        }
        if current.profile != original.profile {
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
    
    // MARK: - Version Mismatch Banner
    
    @ViewBuilder
    private func versionMismatchBanner(diagnostics: ProjectDiagnostics) -> some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: GlassTokens.Typography.headlineSize))
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Version Mismatch")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                if let configured = diagnostics.configuredVersion,
                   let override = diagnostics.overrideVersion {
                    Text("Project requests \(configured), but local override is set to \(override).")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                } else if let configured = diagnostics.configuredVersion,
                          let actual = diagnostics.actualToolchainVersion {
                    Text("Project requests \(configured), but local override is set to \(actual).")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            Button {
                Task {
                    try? await diagnosticsViewModel.fixMismatch()
                    await diagnosticsViewModel.loadDiagnostics(projectPath: projectPath)
                }
            } label: {
                Text("Fix Mismatch")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, GlassTokens.Spacing.md)
                    .padding(.vertical, GlassTokens.Spacing.sm)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(GlassTokens.Radius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(GlassTokens.Spacing.md)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(GlassTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                .stroke(Color.yellow.opacity(0.3), lineWidth: GlassTokens.Stroke.thin)
        )
    }
}

// MARK: - Preview

#Preview {
    ProjectToolchainSettingsView(projectPath: "/Users/example/project")
        .frame(width: 900, height: 1200)
}
