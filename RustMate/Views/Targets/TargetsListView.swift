//
//  TargetsListView.swift
//  RustMate
//
//  View for displaying and managing compilation targets for a toolchain
//

import SwiftUI

struct TargetsListView: View {
    @StateObject private var viewModel = TargetsViewModel()
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
            } else if viewModel.targets.isEmpty {
                emptyState
            } else {
                targetsList
            }
        }
        .navigationTitle("Targets")
        .onChange(of: selectedToolchain) { _, newToolchain in
            viewModel.selectedToolchain = newToolchain
            Task {
                await viewModel.loadTargets()
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

            // Load targets if toolchain is selected
            if viewModel.selectedToolchain != nil {
                await viewModel.loadTargets()
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
                                await viewModel.loadTargets()
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

            if !viewModel.targets.isEmpty {
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
                    await viewModel.refreshTargets()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(selectedToolchain == nil || viewModel.isLoading)
            .help("Refresh targets")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Targets List

    @ViewBuilder
    private var targetsList: some View {
        VStack(spacing: 0) {
            // Suggestions section
            if viewModel.hasSuggestions {
                suggestionsSection
                Divider()
            }

            // All targets
            List(viewModel.targets, selection: $viewModel.selectedTarget) { target in
                TargetRowView(
                    target: target,
                    onInstall: {
                        Task {
                            await viewModel.installTarget(target)
                        }
                    },
                    onUninstall: {
                        Task {
                            await viewModel.uninstallTarget(target)
                        }
                    }
                )
                .tag(target)
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
                Text("Suggested Targets")
                    .font(.headline)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.suggestedTargets) { target in
                        TargetSuggestionCard(
                            target: target,
                            onInstall: {
                                Task {
                                    await viewModel.installTarget(target)
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

            Text("Choose a toolchain from the Toolchains view to see its compilation targets.")
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

            Text("Loading targets...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Targets")
                .font(.title.bold())

            Text("No compilation targets found for this toolchain.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Methods

    private func loadAvailableToolchains() async {
        isLoadingToolchains = true
        do {
            let service = XPCToolchainService()
            availableToolchains = try await service.listToolchains()
        } catch {
            print("Failed to load toolchains: \(error)")
            availableToolchains = []
        }
        isLoadingToolchains = false
    }
}

// MARK: - Target Row View

struct TargetRowView: View {
    let target: TargetInfo
    let onInstall: () -> Void
    let onUninstall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Target icon
            ZStack {
                Circle()
                    .fill(target.isInstalled ? Color.green.opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: platformIcon(for: target))
                    .font(.title3)
                    .foregroundStyle(target.isInstalled ? .green : .secondary)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(target.triple)
                    .font(.body.bold())
                    .fontDesign(.monospaced)

                if let description = target.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else if let arch = target.arch {
                    HStack(spacing: 8) {
                        if let vendor = target.vendor {
                            Label(vendor, systemImage: "building.2")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if let os = target.os {
                            Label(os, systemImage: "folder")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Install/Uninstall button
            if target.isInstalled {
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

    private func platformIcon(for target: TargetInfo) -> String {
        let triple = target.triple.lowercased()

        if triple.contains("wasm") {
            return "globe"
        } else if triple.contains("apple") || triple.contains("darwin") || triple.contains("ios") {
            return "apple.logo"
        } else if triple.contains("linux") {
            return "server.rack"
        } else if triple.contains("windows") {
            return "pc"
        } else if triple.contains("android") {
            return "smartphone"
        } else if triple.contains("thumb") || triple.contains("riscv") {
            return "cpu"
        } else {
            return "target"
        }
    }
}

// MARK: - Target Suggestion Card

struct TargetSuggestionCard: View {
    let target: TargetInfo
    let onInstall: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: platformIcon(for: target))
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

            Text(target.triple)
                .font(.subheadline.bold())
                .fontDesign(.monospaced)

            if let description = target.description {
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .frame(width: 180)
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private func platformIcon(for target: TargetInfo) -> String {
        let triple = target.triple.lowercased()

        if triple.contains("wasm") {
            return "globe"
        } else if triple.contains("apple") || triple.contains("darwin") || triple.contains("ios") {
            return "apple.logo"
        } else if triple.contains("linux") {
            return "server.rack"
        } else if triple.contains("windows") {
            return "pc"
        } else if triple.contains("android") {
            return "smartphone"
        } else if triple.contains("thumb") || triple.contains("riscv") {
            return "cpu"
        } else {
            return "target"
        }
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
        TargetsListView(selectedToolchain: .constant(toolchain))
    }
}
