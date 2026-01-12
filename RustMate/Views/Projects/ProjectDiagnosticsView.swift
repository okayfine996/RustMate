//
//  ProjectDiagnosticsView.swift
//  RustMate
//
//  View for displaying project diagnostics and health status
//

import SwiftUI

struct ProjectDiagnosticsView: View {
    @StateObject private var viewModel: ProjectDiagnosticsViewModel
    let projectPath: String
    
    @State private var showingConflictAlert = true
    
    init(projectPath: String) {
        self.projectPath = projectPath
        _viewModel = StateObject(wrappedValue: ProjectDiagnosticsViewModel())
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
                    // Error display
                    if let error = viewModel.error {
                        errorBanner(error)
                    }
                    
                    // Loading indicator
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    } else if let diagnostics = viewModel.diagnostics {
                        // Top Alert Banner (if there's a conflict)
                        if diagnostics.hasMismatch && showingConflictAlert {
                            conflictAlertBanner
                        }
                        
                        // Information Cards
                        HStack(alignment: .top, spacing: GlassTokens.Spacing.lg) {
                            projectConfigCard(diagnostics: diagnostics)
                            activeEnvironmentCard(diagnostics: diagnostics)
                        }
                        
                        // Directory Override Alert (if override is active)
                        if diagnostics.toolchainSource == .override {
                            overrideAlertBanner(diagnostics: diagnostics)
                        }
                        
                        // Resolution Path Section
                        resolutionPathSection(diagnostics: diagnostics)
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
            await viewModel.loadDiagnostics(projectPath: projectPath)
        }
    }
    
    // MARK: - Conflict Alert Banner
    
    @ViewBuilder
    private var conflictAlertBanner: some View {
        HStack(alignment: .top, spacing: GlassTokens.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text("Environment Conflict Detected")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                Text("The active toolchain in your environment does not match the project configuration defined in `rust-toolchain.toml`. This may lead to inconsistent build artifacts.")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    showingConflictAlert = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(GlassTokens.Spacing.lg)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(GlassTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                .stroke(Color.yellow.opacity(0.3), lineWidth: GlassTokens.Stroke.thin)
        )
    }
    
    // MARK: - Project Config Card
    
    @ViewBuilder
    private func projectConfigCard(diagnostics: ProjectDiagnostics) -> some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.accent)
                Text("PROJECT CONFIG")
                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .tracking(0.5)
            }
            
            if let version = diagnostics.configuredVersion {
                Text(version)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            } else {
                Text("Not configured")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            
            HStack(spacing: GlassTokens.Spacing.xs) {
                Text("Source:")
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                
                Button {
                    // Open rust-toolchain.toml
                } label: {
                    Text("rust-toolchain.toml")
                        .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                        .foregroundColor(GlassTokens.Colors.accent)
                        .padding(.horizontal, GlassTokens.Spacing.sm)
                        .padding(.vertical, GlassTokens.Spacing.xs)
                        .background(GlassTokens.Colors.accentSubtle)
                        .cornerRadius(GlassTokens.Radius.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlassTokens.Spacing.xl)
        .background(GlassTokens.Colors.cardBackground)
        .cornerRadius(GlassTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.lg)
                .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
        )
        .overlay(
            Image(systemName: "doc.text.fill")
                .font(.system(size: 80))
                .foregroundColor(GlassTokens.Colors.backgroundSecondary)
                .opacity(0.3),
            alignment: .trailing
        )
    }
    
    // MARK: - Active Environment Card
    
    @ViewBuilder
    private func activeEnvironmentCard(diagnostics: ProjectDiagnostics) -> some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(.orange)
                Text("ACTIVE ENVIRONMENT")
                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .tracking(0.5)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: GlassTokens.Spacing.xs) {
                if let version = diagnostics.actualToolchainVersion ?? diagnostics.overrideVersion {
                    Text(version)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                } else {
                    Text("Not set")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
                
                if diagnostics.hasMismatch {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                }
            }
            
            HStack(spacing: GlassTokens.Spacing.xs) {
                Text("Source:")
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                
                Button {
                    // Show source info
                } label: {
                    Text(diagnostics.toolchainSource.displayText)
                        .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                        .foregroundColor(GlassTokens.Colors.accent)
                        .padding(.horizontal, GlassTokens.Spacing.sm)
                        .padding(.vertical, GlassTokens.Spacing.xs)
                        .background(GlassTokens.Colors.accentSubtle)
                        .cornerRadius(GlassTokens.Radius.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlassTokens.Spacing.xl)
        .background(GlassTokens.Colors.cardBackground)
        .cornerRadius(GlassTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.lg)
                .stroke(GlassTokens.Colors.cardStroke, lineWidth: GlassTokens.Stroke.thin)
        )
        .overlay(
            Image(systemName: "terminal.fill")
                .font(.system(size: 80))
                .foregroundColor(GlassTokens.Colors.backgroundSecondary)
                .opacity(0.3),
            alignment: .trailing
        )
    }
    
    // MARK: - Override Alert Banner
    
    @ViewBuilder
    private func overrideAlertBanner(diagnostics: ProjectDiagnostics) -> some View {
        HStack(alignment: .top, spacing: GlassTokens.Spacing.md) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 20))
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text("Directory override active")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                Text("A manual `rustup override` is forcing a nightly toolchain.")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            
            Spacer()
            
            Button {
                Task {
                    try? await viewModel.fixMismatch()
                }
            } label: {
                HStack(spacing: GlassTokens.Spacing.xs) {
                    Image(systemName: "trash")
                    Text("Clear Override")
                }
                .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, GlassTokens.Spacing.md)
                .padding(.vertical, GlassTokens.Spacing.sm)
                .background(Color.red)
                .cornerRadius(GlassTokens.Radius.md)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
        }
        .padding(GlassTokens.Spacing.lg)
        .background(Color.red.opacity(0.1))
        .cornerRadius(GlassTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                .stroke(Color.red.opacity(0.3), lineWidth: GlassTokens.Stroke.thin)
        )
    }
    
    // MARK: - Resolution Path Section
    
    @ViewBuilder
    private func resolutionPathSection(diagnostics: ProjectDiagnostics) -> some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack {
                Text("Resolution Path")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                Spacer()
                
                Button("Priority Order") {
                    // Show priority info
                }
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                .foregroundColor(GlassTokens.Colors.accent)
                .padding(.horizontal, GlassTokens.Spacing.sm)
                .padding(.vertical, GlassTokens.Spacing.xs)
                .background(GlassTokens.Colors.accentSubtle)
                .cornerRadius(GlassTokens.Radius.sm)
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                // Shell Environment
                resolutionPathItem(
                    title: "Shell Environment",
                    value: diagnostics.toolchainSource == .environment ? (diagnostics.actualToolchainVersion ?? "Set") : "Not set",
                    badge: "RUSTUP_TOOLCHAIN",
                    isActive: diagnostics.toolchainSource == .environment,
                    showDivider: true
                )
                
                // Directory Override
                resolutionPathItem(
                    title: "Directory Override",
                    value: diagnostics.toolchainSource == .override ? (diagnostics.overrideVersion ?? diagnostics.actualToolchainVersion ?? "Set") : nil,
                    badge: diagnostics.toolchainSource == .override ? "Winning" : nil,
                    isActive: diagnostics.toolchainSource == .override,
                    showDivider: true,
                    isWinning: diagnostics.toolchainSource == .override
                )
                
                // rust-toolchain.toml
                resolutionPathItem(
                    title: "rust-toolchain.toml",
                    value: diagnostics.configuredVersion != nil ? "\(diagnostics.configuredVersion ?? "")\(diagnostics.toolchainSource == .override ? " (Ignored due to override)" : "")" : nil,
                    badge: "Project Config",
                    isActive: diagnostics.toolchainSource == .toolchainFile,
                    showDivider: true,
                    isIgnored: diagnostics.toolchainSource == .override && diagnostics.configuredVersion != nil
                )
                
                // Global Default
                resolutionPathItem(
                    title: "Global Default",
                    value: diagnostics.toolchainSource == .default ? "stable" : "stable",
                    badge: "rustup default",
                    isActive: diagnostics.toolchainSource == .default,
                    showDivider: false
                )
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
    private func resolutionPathItem(
        title: String,
        value: String?,
        badge: String?,
        isActive: Bool,
        showDivider: Bool,
        isWinning: Bool = false,
        isIgnored: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: GlassTokens.Spacing.md) {
                // Radio button indicator
                ZStack {
                    Circle()
                        .fill(isActive ? GlassTokens.Colors.accent : Color.clear)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(isActive ? GlassTokens.Colors.accent : GlassTokens.Colors.textTertiary, lineWidth: 2)
                        )
                    
                    if isActive {
                        Circle()
                            .fill(.white)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(width: 20)
                
                // Content
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                    HStack {
                        Text(title)
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                            .foregroundColor(isActive ? GlassTokens.Colors.textPrimary : GlassTokens.Colors.textSecondary)
                        
                        Spacer()
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                                .foregroundColor(isWinning ? .white : GlassTokens.Colors.textSecondary)
                                .padding(.horizontal, GlassTokens.Spacing.sm)
                                .padding(.vertical, 2)
                                .background(isWinning ? GlassTokens.Colors.accent : GlassTokens.Colors.backgroundSecondary)
                                .cornerRadius(GlassTokens.Radius.sm)
                        }
                    }
                    
                    if let value = value {
                        Text(value)
                            .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                            .foregroundColor(isIgnored ? GlassTokens.Colors.textSecondary : GlassTokens.Colors.textPrimary)
                    }
                }
            }
            .padding(.vertical, GlassTokens.Spacing.md)
            
            if showDivider {
                Divider()
                    .padding(.leading, 40)
            }
        }
    }
    
    // MARK: - Status Bar
    
    @ViewBuilder
    private var statusBar: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // Left: Status indicator
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("Diagnostics updated just now")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            }
            
            Spacer()
            
            // Right: Action buttons
            HStack(spacing: GlassTokens.Spacing.md) {
                Button("Rescan") {
                    Task {
                        await viewModel.loadDiagnostics(projectPath: projectPath)
                    }
                }
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .buttonStyle(.plain)
                
                Button {
                    // Apply fixes
                    if let diagnostics = viewModel.diagnostics, diagnostics.hasMismatch {
                        Task {
                            try? await viewModel.fixMismatch()
                        }
                    }
                } label: {
                    HStack(spacing: GlassTokens.Spacing.xs) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: GlassTokens.Typography.bodySize))
                        Text("Apply Fixes")
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, GlassTokens.Spacing.lg)
                    .padding(.vertical, GlassTokens.Spacing.md)
                    .background(GlassTokens.Colors.accent)
                    .cornerRadius(GlassTokens.Radius.md)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading || viewModel.diagnostics?.hasMismatch != true)
            }
        }
        .padding(GlassTokens.Spacing.lg)
        .background(GlassTokens.Colors.backgroundTertiary)
        .cornerRadius(GlassTokens.Radius.md)
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
