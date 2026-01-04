//
//  TargetsListView.swift
//  RustMate
//
//  View for displaying and managing compilation targets for a toolchain
//  Feature: 004-glass-ui-refresh - Table layout redesign
//

import SwiftUI

struct TargetsListView: View {
    @StateObject private var viewModel = TargetsViewModel()
    @Binding var selectedToolchain: ToolchainInfo?
    @State private var availableToolchains: [ToolchainInfo] = []
    @State private var isLoadingToolchains = false
    @State private var hasInitialized = false

    // Filter and search state
    @State private var filterSelection: TargetFilter = .all
    @State private var searchText = ""

    // Pagination state
    @State private var currentPage = 0
    private let itemsPerPage = 20

    enum TargetFilter: String, CaseIterable, Hashable {
        case all = "All"
        case installed = "Installed"
        case available = "Available"
    }

    var body: some View {
        HSplitView {
            // Left sidebar: Toolchain list
            toolchainSidebar
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)

            // Right content: Targets view
            VStack(spacing: 0) {
                if viewModel.selectedToolchain == nil {
                    selectToolchainPrompt
                } else if viewModel.isLoading {
                    loadingView
                } else if viewModel.targets.isEmpty {
                    emptyState
                } else {
                    targetsContentView
                }
            }
        }
        .navigationTitle("Targets")
        .onChange(of: selectedToolchain) { _, newToolchain in
            viewModel.selectedToolchain = newToolchain
            Task {
                await viewModel.loadTargets()
            }
        }
        .onChange(of: filterSelection) { _, _ in
            currentPage = 0
        }
        .onChange(of: searchText) { _, _ in
            currentPage = 0
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

    // MARK: - Toolchain Sidebar

    @ViewBuilder
    private var toolchainSidebar: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text("Toolchains")
                    .font(.system(size: GlassTokens.Typography.titleSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text("Select active environment")
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            .padding(.horizontal, GlassTokens.Spacing.lg)
            .padding(.top, GlassTokens.Spacing.xl)
            .padding(.bottom, GlassTokens.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Toolchain list
            ScrollView {
                VStack(spacing: GlassTokens.Spacing.xs) {
                    ForEach(currentToolchains) { toolchain in
                        toolchainItem(toolchain)
                    }

                    if !previousVersions.isEmpty {
                        // Other versions section
                        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                            Text("OTHER VERSIONS")
                                .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                                .foregroundColor(GlassTokens.Colors.textSecondary)
                                .tracking(0.5)
                                .padding(.horizontal, GlassTokens.Spacing.lg)
                                .padding(.top, GlassTokens.Spacing.lg)
                                .padding(.bottom, GlassTokens.Spacing.xs)

                            ForEach(previousVersions) { toolchain in
                                toolchainItem(toolchain)
                            }
                        }
                    }
                }
                .padding(.vertical, GlassTokens.Spacing.md)
            }
        }
        .background(GlassTokens.Colors.cardBackground.opacity(0.5))
    }

    @ViewBuilder
    private func toolchainItem(_ toolchain: ToolchainInfo) -> some View {
        Button {
            viewModel.selectedToolchain = toolchain
            Task {
                await viewModel.loadTargets()
            }
        } label: {
            HStack(spacing: GlassTokens.Spacing.md) {
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(toolchain.name)
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    if toolchain.isDefault {
                        Text("Default • Updated recently")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                }

                Spacer()

                // Checkmark for selected
                if viewModel.selectedToolchain?.id == toolchain.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.accent)
                }
            }
            .padding(.horizontal, GlassTokens.Spacing.lg)
            .padding(.vertical, GlassTokens.Spacing.sm)
            .background(viewModel.selectedToolchain?.id == toolchain.id ? GlassTokens.Colors.accentSubtle.opacity(0.3) : Color.clear)
            .cornerRadius(GlassTokens.Radius.md)
        }
        .buttonStyle(.plain)
    }

    private var currentToolchains: [ToolchainInfo] {
        availableToolchains.filter { toolchain in
            let name = toolchain.name.lowercased()
            // Filter out previous versions (those with specific version numbers in the middle)
            return !name.contains("1.") && !name.contains("2.")
        }
    }

    private var previousVersions: [ToolchainInfo] {
        availableToolchains.filter { toolchain in
            let name = toolchain.name.lowercased()
            // Include only previous versions
            return name.contains("1.") || name.contains("2.")
        }
    }

    private func channelIcon(for toolchain: ToolchainInfo) -> String {
        let name = toolchain.name.lowercased()
        if name.contains("stable") {
            return "checkmark.circle.fill"
        } else if name.contains("nightly") {
            return "moon.fill"
        } else if name.contains("beta") {
            return "hourglass"
        } else {
            return "clock.arrow.circlepath"
        }
    }

    // MARK: - Filtering and Pagination

    private var filteredTargets: [TargetInfo] {
        var filtered = viewModel.targets

        // Apply filter
        switch filterSelection {
        case .all:
            break
        case .installed:
            filtered = filtered.filter { $0.isInstalled }
        case .available:
            filtered = filtered.filter { !$0.isInstalled }
        }

        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter { target in
                target.triple.localizedCaseInsensitiveContains(searchText) ||
                (target.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return filtered
    }

    private var paginatedTargets: [TargetInfo] {
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, filteredTargets.count)

        guard startIndex < filteredTargets.count else { return [] }

        return Array(filteredTargets[startIndex..<endIndex])
    }

    private var totalPages: Int {
        max(1, Int(ceil(Double(filteredTargets.count) / Double(itemsPerPage))))
    }

    // MARK: - Targets Content View

    @ViewBuilder
    private var targetsContentView: some View {
        VStack(spacing: 0) {
            // Header with breadcrumb and description
            headerSection

            Divider()

            // Search and filter bar
            searchAndFilterBar

            Divider()

            // Table header
            tableHeader

            Divider()

            // Table content
            if filteredTargets.isEmpty {
                emptySearchState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(paginatedTargets) { target in
                            TargetTableRow(
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
                            Divider()
                        }
                    }
                }

                // Pagination controls
                paginationControls
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Breadcrumb
            HStack(spacing: GlassTokens.Spacing.xs) {
                Text("Toolchains")
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: GlassTokens.Typography.captionSize - 2))
                    .foregroundColor(GlassTokens.Colors.textSecondary)

                if let toolchain = viewModel.selectedToolchain {
                    Text(toolchain.name)
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
            }

            // Title
            Text("Targets")
                .font(.system(size: GlassTokens.Typography.displaySize, weight: .bold))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            // Description
            if let toolchain = viewModel.selectedToolchain {
                let channelName = toolchain.name.components(separatedBy: "-").first ?? "stable"
                Text("Manage compilation targets for the \(channelName) channel. Add standard library support for cross-compilation.")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
        }
        .padding(.horizontal, GlassTokens.Spacing.md)
        .padding(.vertical, GlassTokens.Spacing.xl)
    }

    // MARK: - Search and Filter Bar

    @ViewBuilder
    private var searchAndFilterBar: some View {
        HStack(spacing: GlassTokens.Spacing.lg) {
            // Search field
            HStack(spacing: GlassTokens.Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .font(.system(size: GlassTokens.Typography.bodySize))

                TextField("Search targets (e.g., wasm32, android)...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: GlassTokens.Typography.bodySize))

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, GlassTokens.Spacing.md)
            .padding(.vertical, GlassTokens.Spacing.sm)
            .background(GlassTokens.Colors.cardBackground)
            .cornerRadius(GlassTokens.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: GlassTokens.Radius.md)
                    .stroke(GlassTokens.Colors.divider, lineWidth: GlassTokens.Stroke.thin)
            )
            .frame(maxWidth: 400)

            Spacer()

            // Filter chips
            SegmentedChipsView(
                options: TargetFilter.allCases,
                displayName: { filter in
                    switch filter {
                    case .all:
                        return "All"
                    case .installed:
                        return "Installed"
                    case .available:
                        return "Available"
                    }
                },
                selection: $filterSelection
            )
        }
        .padding(.horizontal, GlassTokens.Spacing.md)
        .padding(.vertical, GlassTokens.Spacing.md)
    }

    // MARK: - Table Header

    @ViewBuilder
    private var tableHeader: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // TARGET NAME column
            Text("TARGET NAME")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // STATUS column
            Text("STATUS")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(width: 150, alignment: .leading)

            // ACTION column
            Text("ACTION")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, GlassTokens.Spacing.md)
        .padding(.vertical, GlassTokens.Spacing.sm)
        .background(GlassTokens.Colors.cardBackground.opacity(0.3))
    }

    // MARK: - Pagination Controls

    @ViewBuilder
    private var paginationControls: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // Page info
            Text("Page \(currentPage + 1) of \(totalPages)")
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textSecondary)

            Spacer()

            // Items info
            Text("\(filteredTargets.count) total items")
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textSecondary)

            // Navigation buttons
            HStack(spacing: GlassTokens.Spacing.xs) {
                Button {
                    if currentPage > 0 {
                        currentPage -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                }
                .disabled(currentPage == 0)

                Button {
                    if currentPage < totalPages - 1 {
                        currentPage += 1
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                }
                .disabled(currentPage >= totalPages - 1)
            }
        }
        .padding(.horizontal, GlassTokens.Spacing.md)
        .padding(.vertical, GlassTokens.Spacing.md)
        .background(GlassTokens.Colors.cardBackground.opacity(0.3))
    }

    // MARK: - Empty & Loading States

    @ViewBuilder
    private var selectToolchainPrompt: some View {
        EmptyStateView(
            icon: "arrow.left",
            title: "Select a Toolchain",
            description: "Choose a toolchain from the Toolchains view to see its compilation targets."
        )
    }

    @ViewBuilder
    private var loadingView: some View {
        LoadingView(message: "Loading targets...")
    }

    @ViewBuilder
    private var emptyState: some View {
        EmptyStateView(
            icon: "target",
            title: "No Targets",
            description: "No compilation targets found for this toolchain."
        )
    }

    @ViewBuilder
    private var emptySearchState: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            description: "No targets match your search or filter criteria.",
            actionTitle: "Clear Search",
            action: {
                searchText = ""
                filterSelection = .all
            }
        )
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
}

// MARK: - Target Table Row

struct TargetTableRow: View {
    let target: TargetInfo
    let onInstall: () -> Void
    let onUninstall: () -> Void

    var body: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // TARGET NAME column
            HStack(spacing: GlassTokens.Spacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            StatusSemantics.componentColor(isInstalled: target.isInstalled)
                                .opacity(0.15)
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "cpu.fill")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(StatusSemantics.componentColor(isInstalled: target.isInstalled))
                }

                // Name and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(target.triple)
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium, design: .monospaced))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    if let description = target.description {
                        Text(description)
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // STATUS column
            HStack(spacing: GlassTokens.Spacing.xs) {
                if target.isInstalled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.success)

                    Text("Installed")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.success)
                } else {
                    Text("Available")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                        .padding(.horizontal, GlassTokens.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(GlassTokens.Colors.cardBackground)
                        .cornerRadius(GlassTokens.Radius.sm)
                }
            }
            .frame(width: 150, alignment: .leading)

            // ACTION column
            HStack {
                Spacer()
                if target.isInstalled {
                    // No button for installed (could add uninstall if needed)
                    EmptyView()
                } else {
                    Button {
                        onInstall()
                    } label: {
                        HStack(spacing: GlassTokens.Spacing.xs) {
                            Image(systemName: "arrow.down.circle")
                            Text("Install")
                        }
                        .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                    }
                    .primaryGlassButtonStyle()
                    .controlSize(.small)
                }
            }
            .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, GlassTokens.Spacing.md)
        .padding(.vertical, GlassTokens.Spacing.md)
        .contentShape(Rectangle())
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
