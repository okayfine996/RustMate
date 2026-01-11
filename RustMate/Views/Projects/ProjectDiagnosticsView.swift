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
    
    init(projectPath: String) {
        self.projectPath = projectPath
        _viewModel = StateObject(wrappedValue: ProjectDiagnosticsViewModel())
    }
    
    var body: some View {
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
                }
                // Breadcrumb
                HStack(spacing: GlassTokens.Spacing.xs) {
                    Text("Settings")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                    Text("Info")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
                
                // Page Title
                Text("Project Diagnostics")
                    .font(.system(size: GlassTokens.Typography.displaySize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                // Page Description
                Text("View detailed information about your project's toolchain configuration, version status, and potential issues.")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .padding(.bottom, GlassTokens.Spacing.md)
                
                // Status Overview
                statusOverviewSection
                
                // Version Information
                versionSection
                
                // Conflicts
                conflictsSection
                
                // MSRV Check
                msrvSection
                
                // Actions
                actionsSection
            }
            .padding(GlassTokens.Spacing.xxl)
        }
        .task {
            await viewModel.loadDiagnostics(projectPath: projectPath)
        }
    }
    
    // MARK: - Status Overview
    
    @ViewBuilder
    private var statusOverviewSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: GlassTokens.Typography.headlineSize))
                    .foregroundColor(GlassTokens.Colors.accent)
                Text("Status Overview")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            }
            
            if let diagnostics = viewModel.diagnostics {
                HStack(spacing: GlassTokens.Spacing.md) {
                    Circle()
                        .fill(statusColor(for: diagnostics))
                        .frame(width: 16, height: 16)
                    
                    Text(statusText(for: diagnostics))
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                    
                    Spacer()
                    
                    if viewModel.hasIssues {
                        Text("\(viewModel.issueCount) issue(s)")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                }
                .padding(GlassTokens.Spacing.md)
                .background(GlassTokens.Colors.cardBackground)
                .cornerRadius(GlassTokens.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                        .stroke(GlassTokens.Colors.divider, lineWidth: GlassTokens.Stroke.thin)
                )
            } else {
                Text("Loading diagnostics...")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Version Section
    
    @ViewBuilder
    private var versionSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "number")
                    .font(.system(size: GlassTokens.Typography.headlineSize))
                    .foregroundColor(GlassTokens.Colors.accent)
                Text("Version Information")
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            }
            
            if let diagnostics = viewModel.diagnostics {
                VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                    versionRow("Actual Version", diagnostics.actualToolchainVersion)
                    versionRow("Configured Version", diagnostics.configuredVersion)
                    versionRow("Override Version", diagnostics.overrideVersion)
                    versionRow("Source", diagnostics.toolchainSource.displayText)
                }
            }
        }
    }
    
    @ViewBuilder
    private func versionRow(_ label: String, _ value: String?) -> some View {
        HStack {
            Text(label)
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
            
            Spacer()
            
            Text(value ?? "Not set")
                .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                .foregroundColor(value != nil ? GlassTokens.Colors.textPrimary : GlassTokens.Colors.textSecondary)
        }
                        .padding(GlassTokens.Spacing.sm)
                        .background(GlassTokens.Colors.backgroundSecondary)
                        .cornerRadius(GlassTokens.Radius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: GlassTokens.Radius.sm)
                                .stroke(GlassTokens.Colors.divider, lineWidth: GlassTokens.Stroke.thin)
                        )
    }
    
    // MARK: - Conflicts Section
    
    @ViewBuilder
    private var conflictsSection: some View {
        if let diagnostics = viewModel.diagnostics, !diagnostics.conflictDetails.isEmpty {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: GlassTokens.Typography.headlineSize))
                        .foregroundColor(GlassTokens.Colors.warning)
                    Text("Conflicts")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                }
                
                ForEach(Array(diagnostics.conflictDetails.enumerated()), id: \.offset) { _, conflict in
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            
                            Text(conflict.message)
                                .font(.system(size: GlassTokens.Typography.bodySize))
                                .foregroundColor(GlassTokens.Colors.textPrimary)
                        }
                        
                        if let fix = conflict.suggestedFix {
                            Text(fix)
                                .font(.system(size: GlassTokens.Typography.captionSize))
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                        }
                    }
                    .padding(GlassTokens.Spacing.md)
                    .background(GlassTokens.Colors.cardBackground)
                    .cornerRadius(GlassTokens.Radius.sm)
                }
            }
        }
    }
    
    // MARK: - MSRV Section
    
    @ViewBuilder
    private var msrvSection: some View {
        if let diagnostics = viewModel.diagnostics, let msrv = diagnostics.msrvViolation {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: GlassTokens.Typography.headlineSize))
                        .foregroundColor(GlassTokens.Colors.accent)
                    Text("MSRV Check")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                }
                
                HStack {
                    Image(systemName: msrv.isViolation ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(msrv.isViolation ? .red : .green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(msrv.message)
                            .font(.system(size: GlassTokens.Typography.bodySize))
                            .foregroundColor(GlassTokens.Colors.textPrimary)
                        
                        Text("Required: \(msrv.requiredVersion) | Configured: \(msrv.configuredVersion)")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                }
                .padding(GlassTokens.Spacing.md)
                .background(GlassTokens.Colors.cardBackground)
                .cornerRadius(GlassTokens.Radius.sm)
            }
        }
    }
    
    // MARK: - Actions Section
    
    @ViewBuilder
    private var actionsSection: some View {
        if let diagnostics = viewModel.diagnostics, diagnostics.hasMismatch {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: GlassTokens.Typography.headlineSize))
                        .foregroundColor(GlassTokens.Colors.accent)
                    Text("Actions")
                        .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                }
                
                Button {
                    Task {
                        try? await viewModel.fixMismatch()
                    }
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Override")
                    }
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(GlassTokens.Spacing.md)
                }
                .secondaryGlassButtonStyle()
                .disabled(viewModel.isLoading)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func statusColor(for diagnostics: ProjectDiagnostics) -> Color {
        if diagnostics.hasMismatch || diagnostics.msrvViolation?.isViolation == true {
            return .red
        } else if !diagnostics.conflictDetails.isEmpty {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func statusText(for diagnostics: ProjectDiagnostics) -> String {
        if diagnostics.hasMismatch || diagnostics.msrvViolation?.isViolation == true {
            return "Issues Detected"
        } else if !diagnostics.conflictDetails.isEmpty {
            return "Warnings"
        } else {
            return "All Good"
        }
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
