//
//  ComponentsListView.swift
//  RustMate
//
//  View for displaying and managing components for a toolchain
//

import SwiftUI

struct ComponentsListView: View {
    @StateObject private var viewModel = ComponentsViewModel()
    @Binding var selectedToolchain: ToolchainInfo?
    @State private var availableToolchains: [ToolchainInfo] = []
    @State private var isLoadingToolchains = false
    @State private var hasInitialized = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar/status bar
            statusBar

            Divider()

            if viewModel.selectedToolchain == nil {
                selectToolchainPrompt
            } else if viewModel.isLoading {
                loadingView
            } else if viewModel.components.isEmpty {
                emptyState
            } else {
                componentsList
            }
        }
        .navigationTitle("Components")
        .onChange(of: selectedToolchain) { _, newToolchain in
            viewModel.selectedToolchain = newToolchain
            Task {
                await viewModel.loadComponents()
            }
        }
        .task {
            // Only initialize once
            guard !hasInitialized else { return }
            hasInitialized = true

            // Load available toolchains
            await loadAvailableToolchains()

            // Set initial toolchain (prefer default)
            if let defaultToolchain = availableToolchains.first(where: { $0.isDefault }) {
                viewModel.selectedToolchain = defaultToolchain
            } else if let firstToolchain = availableToolchains.first {
                viewModel.selectedToolchain = firstToolchain
            } else if let bound = selectedToolchain {
                viewModel.selectedToolchain = bound
            }

            // Load components if toolchain is selected
            if viewModel.selectedToolchain != nil {
                await viewModel.loadComponents()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Helper Methods

    private func loadAvailableToolchains() async {
        isLoadingToolchains = true
        do {
            let service = LocalRustupToolchainService()
            availableToolchains = try await service.listToolchains()
        } catch {
            print("Failed to load toolchains: \(error)")
            availableToolchains = []
        }
        isLoadingToolchains = false
    }

    // MARK: - Status Bar

    @ViewBuilder
    private var statusBar: some View {
        HStack(spacing: 12) {
            // Toolchain selector
            if !availableToolchains.isEmpty {
                Menu {
                    ForEach(availableToolchains) { toolchain in
                        Button {
                            viewModel.selectedToolchain = toolchain
                            Task {
                                await viewModel.loadComponents()
                            }
                        } label: {
                            HStack {
                                Text(toolchain.name)
                                if toolchain.isDefault {
                                    Text("(default)")
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if viewModel.selectedToolchain?.id == toolchain.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "hammer.fill")
                        if let toolchain = viewModel.selectedToolchain {
                            Text(toolchain.name)
                                .font(.subheadline.bold())
                        } else {
                            Text("Select Toolchain")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(isLoadingToolchains)
            } else if let toolchain = selectedToolchain {
                Label(toolchain.name, systemImage: "hammer.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !viewModel.components.isEmpty {
                HStack(spacing: 16) {
                    Label("\(viewModel.installedCount) installed", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.green)

                    Label("\(viewModel.availableCount) available", systemImage: "circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                Task {
                    await viewModel.refreshComponents()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(selectedToolchain == nil || viewModel.isLoading)
            .help("Refresh components")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Components List

    @ViewBuilder
    private var componentsList: some View {
        VStack(spacing: 0) {
            // Suggestions section
            if viewModel.hasSuggestions {
                suggestionsSection
                Divider()
            }

            // All components
            List(viewModel.components, selection: $viewModel.selectedComponent) { component in
                ComponentRowView(
                    component: component,
                    onInstall: {
                        Task {
                            await viewModel.installComponent(component)
                        }
                    },
                    onUninstall: {
                        Task {
                            await viewModel.uninstallComponent(component)
                        }
                    }
                )
                .tag(component)
            }
            .listStyle(.inset)
        }
    }

    // MARK: - Suggestions Section

    @ViewBuilder
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.orange)
                Text("Suggested Components")
                    .font(.headline)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.suggestedComponents) { component in
                        SuggestionCard(
                            component: component,
                            onInstall: {
                                Task {
                                    await viewModel.installComponent(component)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .background(Color.orange.opacity(0.05))
    }

    // MARK: - Empty & Loading States

    @ViewBuilder
    private var selectToolchainPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Select a Toolchain")
                .font(.title.bold())

            Text("Choose a toolchain from the Toolchains view to see its components.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading components...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "puzzlepiece")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Components")
                .font(.title.bold())

            Text("No components found for this toolchain.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Component Row View

struct ComponentRowView: View {
    let component: ComponentInfo
    let onInstall: () -> Void
    let onUninstall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Component icon
            ZStack {
                Circle()
                    .fill(component.isInstalled ? Color.green.opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: component.componentType.icon)
                    .font(.title3)
                    .foregroundStyle(component.isInstalled ? .green : .secondary)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(component.displayName)
                    .font(.body.bold())

                if let description = component.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Install/Uninstall button
            if component.isInstalled {
                Button {
                    onUninstall()
                } label: {
                    Text("Uninstall")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Button {
                    onInstall()
                } label: {
                    Text("Install")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let component: ComponentInfo
    let onInstall: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: component.componentType.icon)
                    .font(.title2)
                    .foregroundStyle(.orange)

                Spacer()

                Button {
                    onInstall()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.orange)
            }

            Text(component.displayName)
                .font(.subheadline.bold())

            if let description = component.description {
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .frame(width: 160)
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Previews

#Preview {
    let toolchain = ToolchainInfo(
        name: "stable-aarch64-apple-darwin",
        version: "1.75.0",
        isDefault: true,
        installDate: Date(),
        host: "aarch64-apple-darwin"
    )

    return NavigationStack {
        ComponentsListView(selectedToolchain: .constant(toolchain))
    }
}
