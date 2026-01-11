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
    
    var body: some View {
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
                
                // Components
                componentsSection
                
                // Targets
                targetsSection
                
                // Profile
                profileSection
                
                // Save Button
                saveButton
            }
            .padding(GlassTokens.Spacing.xxl)
        }
        .task {
            await viewModel.loadConfig(projectPath: projectPath)
            await diagnosticsViewModel.loadDiagnostics(projectPath: projectPath)
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
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack {
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Image(systemName: "puzzlepiece.fill")
                        .font(.system(size: GlassTokens.Typography.headlineSize))
                        .foregroundColor(GlassTokens.Colors.accent)
                    Text("Components")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                }
                
                Spacer()
                
                Button("MANAGE ALL") {
                    // TODO: Open full components management view
                }
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                .foregroundColor(GlassTokens.Colors.accent)
            }
            
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                componentRow("rustfmt", description: "Automatic code formatter")
                componentRow("clippy", description: "Linting library to catch common mistakes")
                componentRow("rust-src", description: "Source code for the standard library")
                componentRow("rust-analyzer", description: "Language server for IDE support")
            }
        }
    }
    
    @ViewBuilder
    private func componentRow(_ component: String, description: String) -> some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            Toggle("", isOn: Binding(
                get: { viewModel.config?.components.contains(component) ?? false },
                set: { _ in viewModel.toggleComponent(component) }
            ))
            .toggleStyle(.checkbox)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(component)
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                Text(description)
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
        }
        .padding(GlassTokens.Spacing.sm)
    }
    
    // MARK: - Targets Section
    
    @ViewBuilder
    private var targetsSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack {
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Image(systemName: "target")
                        .font(.system(size: GlassTokens.Typography.headlineSize))
                        .foregroundColor(GlassTokens.Colors.accent)
                    Text("Targets")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                }
                
                Spacer()
                
                Button("ADD TARGET") {
                    // TODO: Open target picker
                }
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                .foregroundColor(GlassTokens.Colors.accent)
            }
            
            if let targets = viewModel.config?.targets, !targets.isEmpty {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    ForEach(targets, id: \.self) { target in
                        HStack {
                            Text(target)
                                .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                            Spacer()
                            Button {
                                viewModel.removeTarget(target)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(GlassTokens.Spacing.sm)
                        .background(GlassTokens.Colors.backgroundSecondary)
                        .cornerRadius(GlassTokens.Radius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: GlassTokens.Radius.sm)
                                .stroke(GlassTokens.Colors.divider, lineWidth: GlassTokens.Stroke.thin)
                        )
                    }
                }
            } else {
                Text("No targets configured")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .padding(GlassTokens.Spacing.md)
            }
        }
    }
    
    // MARK: - Profile Section
    
    @ViewBuilder
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: GlassTokens.Typography.headlineSize))
                    .foregroundColor(GlassTokens.Colors.accent)
                Text("Profile")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            }
            
            Picker("Profile", selection: Binding(
                get: { viewModel.config?.profile ?? .default },
                set: { viewModel.updateProfile($0) }
            )) {
                Text("Default").tag(ProjectToolchainConfig.ToolchainProfile.default)
                Text("Minimal").tag(ProjectToolchainConfig.ToolchainProfile.minimal)
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Save Button
    
    @ViewBuilder
    private var saveButton: some View {
        Button {
            Task {
                do {
                    try await viewModel.saveConfig()
                } catch {
                    // Error is handled by viewModel.error
                }
            }
        } label: {
            Text("Save Configuration")
                .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(GlassTokens.Spacing.md)
        }
        .primaryGlassButtonStyle()
        .disabled(viewModel.isLoading)
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
