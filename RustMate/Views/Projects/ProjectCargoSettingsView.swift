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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
                // Error display
                if let error = viewModel.error {
                    errorBanner(error)
                }
                // Breadcrumb
                HStack(spacing: GlassTokens.Spacing.xs) {
                    Text("Settings")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                    Text("Cargo")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
                
                // Page Title
                Text("Cargo Configuration")
                    .font(.system(size: GlassTokens.Typography.displaySize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                // Page Description
                Text("Optimize your build experience with registry mirrors, aliases, linker options, and proxy settings.")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .padding(.bottom, GlassTokens.Spacing.md)
                
                // Registry Mirror
                registryMirrorSection
                
                // Aliases
                aliasesSection
                
                // Linker
                linkerSection
                
                // Rustflags
                rustflagsSection
                
                // Proxy Settings
                proxySection
                
                // Save Button
                saveButton
            }
            .padding(GlassTokens.Spacing.xxl)
        }
        .task {
            await viewModel.loadConfig(projectPath: projectPath)
        }
    }
    
    // MARK: - Registry Mirror Section
    
    @ViewBuilder
    private var registryMirrorSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: GlassTokens.Typography.headlineSize))
                    .foregroundColor(GlassTokens.Colors.accent)
                Text("Registry Mirror")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            }
            
            Text("Switch to a faster mirror for downloading crates")
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
            
            Picker("Mirror", selection: Binding(
                get: { viewModel.config?.registryMirror ?? .cratesIo },
                set: { viewModel.updateRegistryMirror($0 == .cratesIo ? nil : $0) }
            )) {
                ForEach([
                    ProjectCargoConfig.RegistryMirror.cratesIo,
                    .tsinghua,
                    .ustc,
                    .byteDance
                ], id: \.self) { mirror in
                    Text(mirror.displayText).tag(mirror)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    // MARK: - Aliases Section
    
    @ViewBuilder
    private var aliasesSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack {
                Text("Aliases")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                Spacer()
                
                Button("ADD ALIAS") {
                    // TODO: Open alias editor
                }
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                .foregroundColor(GlassTokens.Colors.accent)
            }
            
            if let aliases = viewModel.config?.aliases, !aliases.isEmpty {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    ForEach(Array(aliases.keys.sorted()), id: \.self) { alias in
                        HStack {
                            Text(alias)
                                .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                                .foregroundColor(GlassTokens.Colors.textPrimary)
                            
                            Text("→")
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                            
                            Text(aliases[alias] ?? "")
                                .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                            
                            Spacer()
                            
                            Button {
                                viewModel.removeAlias(alias)
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
                Text("No aliases configured")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .padding(GlassTokens.Spacing.md)
            }
        }
    }
    
    // MARK: - Linker Section
    
    @ViewBuilder
    private var linkerSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: GlassTokens.Typography.headlineSize))
                    .foregroundColor(GlassTokens.Colors.accent)
                Text("Linker")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            }
            
            Text("Use a faster linker to speed up builds")
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
            
            Picker("Linker", selection: Binding(
                get: { viewModel.config?.linker ?? .none },
                set: { viewModel.updateLinker($0 == .none ? nil : $0) }
            )) {
                Text("None (Default)").tag(ProjectCargoConfig.LinkerOption.none)
                Text("mold").tag(ProjectCargoConfig.LinkerOption.mold)
                Text("zld").tag(ProjectCargoConfig.LinkerOption.zld)
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Rustflags Section
    
    @ViewBuilder
    private var rustflagsSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: GlassTokens.Typography.headlineSize))
                    .foregroundColor(GlassTokens.Colors.accent)
                Text("Rustflags")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            }
            
            TextEditor(text: Binding(
                get: { viewModel.config?.rustflags ?? "" },
                set: { viewModel.updateRustflags($0.isEmpty ? nil : $0) }
            ))
            .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
            .frame(height: 100)
            .padding(GlassTokens.Spacing.sm)
            .background(GlassTokens.Colors.backgroundSecondary)
            .cornerRadius(GlassTokens.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: GlassTokens.Radius.sm)
                    .stroke(GlassTokens.Colors.divider, lineWidth: GlassTokens.Stroke.thin)
            )
        }
    }
    
    // MARK: - Proxy Section
    
    @ViewBuilder
    private var proxySection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "network")
                    .font(.system(size: GlassTokens.Typography.headlineSize))
                    .foregroundColor(GlassTokens.Colors.accent)
                Text("Proxy Settings")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                Text("HTTP Proxy")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                
                TextField("http://proxy.example.com:8080", text: Binding(
                    get: { viewModel.config?.proxySettings?.httpProxy ?? "" },
                    set: { value in
                        var proxy = viewModel.config?.proxySettings ?? ProjectCargoConfig.ProxySettings()
                        proxy.httpProxy = value.isEmpty ? nil : value
                        viewModel.updateProxySettings(proxy)
                    }
                ))
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
                Text("HTTPS Proxy")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                
                TextField("https://proxy.example.com:8080", text: Binding(
                    get: { viewModel.config?.proxySettings?.httpsProxy ?? "" },
                    set: { value in
                        var proxy = viewModel.config?.proxySettings ?? ProjectCargoConfig.ProxySettings()
                        proxy.httpsProxy = value.isEmpty ? nil : value
                        viewModel.updateProxySettings(proxy)
                    }
                ))
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
}
