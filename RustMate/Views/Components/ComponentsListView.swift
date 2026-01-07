//
//  ComponentsListView.swift
//  RustMate
//
//  View for displaying and managing components for a toolchain
//  Feature: 004-glass-ui-refresh - Table layout redesign
//

import SwiftUI

struct ComponentsListView: View {
    @StateObject private var viewModel = ComponentsViewModel()
    @Binding var selectedToolchain: ToolchainInfo?
    @State private var availableToolchains: [ToolchainInfo] = []
    @State private var isLoadingToolchains = false
    @State private var hasInitialized = false

    // Filter and search state
    @State private var filterSelection: ComponentFilter = .all
    @State private var searchText = ""

    // Pagination state
    @State private var currentPage = 0
    private let itemsPerPage = 20

    enum ComponentFilter: String, CaseIterable, Hashable {
        case all = "All"
        case installed = "Installed"
        case available = "Available"
    }

    var body: some View {
        HSplitView {
            // Left sidebar: Toolchain list
            toolchainSidebar
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)

            // Right content: Components view
            VStack(spacing: 0) {
                if viewModel.selectedToolchain == nil {
                    selectToolchainPrompt
                } else if viewModel.isLoading {
                    loadingView
                } else if viewModel.components.isEmpty {
                    emptyState
                } else {
                    componentsTableView
                }
            }
        }
        .navigationTitle("Components")
        .onChange(of: selectedToolchain) { _, newToolchain in
            viewModel.selectedToolchain = newToolchain
            Task {
                await viewModel.loadComponents()
            }
        }
        .onChange(of: filterSelection) { _, _ in
            currentPage = 0 // Reset to first page when filter changes
        }
        .onChange(of: searchText) { _, _ in
            currentPage = 0 // Reset to first page when search changes
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

    // MARK: - Filtering and Pagination

    private var filteredComponents: [ComponentInfo] {
        var filtered = viewModel.components

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
            filtered = filtered.filter { component in
                component.displayName.localizedCaseInsensitiveContains(searchText) ||
                component.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    private var paginatedComponents: [ComponentInfo] {
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, filteredComponents.count)

        guard startIndex < filteredComponents.count else { return [] }

        return Array(filteredComponents[startIndex..<endIndex])
    }

    private var totalPages: Int {
        max(1, Int(ceil(Double(filteredComponents.count) / Double(itemsPerPage))))
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
                await viewModel.loadComponents()
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
            return !name.contains("1.") && !name.contains("2.")
        }
    }

    private var previousVersions: [ToolchainInfo] {
        availableToolchains.filter { toolchain in
            let name = toolchain.name.lowercased()
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
            Text("Components")
                .font(.system(size: GlassTokens.Typography.displaySize, weight: .bold))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            // Description
            if let toolchain = viewModel.selectedToolchain {
                let channelName = toolchain.name.components(separatedBy: "-").first ?? "stable"
                Text("Manage components for the \(channelName) channel. Add tools like rustfmt, clippy, and rust-src.")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, GlassTokens.Spacing.lg)
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

                TextField("Search components...", text: $searchText)
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
                options: ComponentFilter.allCases,
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

    // MARK: - Components Table View

    @ViewBuilder
    private var componentsTableView: some View {
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
            if filteredComponents.isEmpty {
                emptySearchState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(paginatedComponents) { component in
                            ComponentTableRow(
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
                            Divider()
                        }
                    }
                }

                // Pagination controls
                paginationControls
            }
        }
    }

    // MARK: - Table Header

    @ViewBuilder
    private var tableHeader: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // NAME column (flexible width)
            Text("NAME")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // TYPE column (fixed width)
            Text("TYPE")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(width: 120, alignment: .leading)

            // STATUS column (fixed width)
            Text("STATUS")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(width: 120, alignment: .leading)

            // ACTION column (fixed width)
            Text("ACTION")
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(width: 100, alignment: .trailing)
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
            Text("\(filteredComponents.count) total items")
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
        .padding(.horizontal, GlassTokens.Spacing.lg)
        .padding(.vertical, GlassTokens.Spacing.md)
        .background(GlassTokens.Colors.cardBackground.opacity(0.3))
    }

    // MARK: - Empty & Loading States

    @ViewBuilder
    private var selectToolchainPrompt: some View {
        EmptyStateView(
            icon: "arrow.left",
            title: "Select a Toolchain",
            description: "Choose a toolchain from the Toolchains view to see its components."
        )
    }

    @ViewBuilder
    private var loadingView: some View {
        LoadingView(message: "Loading components...")
    }

    @ViewBuilder
    private var emptyState: some View {
        EmptyStateView(
            icon: "puzzlepiece.extension",
            title: "No Components",
            description: "No components found for this toolchain."
        )
    }

    @ViewBuilder
    private var emptySearchState: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            description: "No components match your search or filter criteria.",
            actionTitle: "Clear Search",
            action: {
                searchText = ""
                filterSelection = .all
            }
        )
    }
}

// MARK: - Component Table Row

struct ComponentTableRow: View {
    let component: ComponentInfo
    let onInstall: () -> Void
    let onUninstall: () -> Void

    var body: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // NAME column (flexible width)
            HStack(spacing: GlassTokens.Spacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            StatusSemantics.componentColor(isInstalled: component.isInstalled)
                                .opacity(0.15)
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "puzzlepiece.extension.fill")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(StatusSemantics.componentColor(isInstalled: component.isInstalled))
                }

                // Name and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(component.displayName)
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                        .foregroundColor(GlassTokens.Colors.textPrimary)

                    if let description = component.description {
                        Text(description)
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // TYPE column (fixed width)
            Text("Component")
                .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .frame(width: 120, alignment: .leading)

            // STATUS column (fixed width)
            HStack(spacing: GlassTokens.Spacing.xs) {
                let badge = StatusSemantics.componentBadge(isInstalled: component.isInstalled)
                StatusBadgeView(status: badge.status, text: badge.text)
            }
            .frame(width: 120, alignment: .leading)

            // ACTION column (fixed width)
            HStack {
                Spacer()
                if component.isInstalled {
                    Button {
                        onUninstall()
                    } label: {
                        Text("Uninstall")
                            .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                    }
                    .secondaryGlassButtonStyle()
                    .controlSize(.small)
                } else {
                    Button {
                        onInstall()
                    } label: {
                        Text("Install")
                            .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                    }
                    .primaryGlassButtonStyle()
                    .controlSize(.small)
                }
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, GlassTokens.Spacing.lg)
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
        ComponentsListView(selectedToolchain: .constant(toolchain))
    }
}
