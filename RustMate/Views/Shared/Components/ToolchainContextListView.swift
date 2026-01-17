//
//  ToolchainContextListView.swift
//  RustMate
//
//  Generic view for displaying toolchain-context dependent lists (Components, Targets)
//  Feature: Refactoring - Extract common list view pattern
//

import SwiftUI

// MARK: - Protocols

/// Protocol for items that can be displayed in a toolchain context list
protocol ToolchainContextItem: Identifiable {
    var isInstalled: Bool { get }
}

/// Protocol for filters used in toolchain context lists
protocol ToolchainContextFilter: CaseIterable, Hashable, RawRepresentable where RawValue == String {
    static var all: Self { get }
    static var installed: Self { get }
    static var available: Self { get }
}

/// Protocol for view models that manage toolchain context data
protocol ToolchainContextViewModel: ObservableObject {
    associatedtype Item: ToolchainContextItem

    var selectedToolchain: ToolchainInfo? { get set }
    var items: [Item] { get }
    var isLoading: Bool { get }
    var error: Error? { get set }

    func loadItems() async
}

// MARK: - Configuration

/// Configuration for customizing the toolchain context list view
struct ToolchainContextListConfiguration<Filter: ToolchainContextFilter> {
    let title: String
    let icon: String
    let emptyStateIcon: String
    let emptyStateTitle: String
    let emptyStateDescription: String
    let searchPlaceholder: String
    let loadingMessage: String

    let filterDisplayName: (Filter) -> String
    let contentDescription: (ToolchainInfo) -> String

    init(
        title: String,
        icon: String,
        emptyStateIcon: String,
        emptyStateTitle: String,
        emptyStateDescription: String,
        searchPlaceholder: String,
        loadingMessage: String,
        filterDisplayName: @escaping (Filter) -> String,
        contentDescription: @escaping (ToolchainInfo) -> String
    ) {
        self.title = title
        self.icon = icon
        self.emptyStateIcon = emptyStateIcon
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateDescription = emptyStateDescription
        self.searchPlaceholder = searchPlaceholder
        self.loadingMessage = loadingMessage
        self.filterDisplayName = filterDisplayName
        self.contentDescription = contentDescription
    }
}

// MARK: - Main View

struct ToolchainContextListView<
    Item: ToolchainContextItem,
    Filter: ToolchainContextFilter,
    ViewModel: ToolchainContextViewModel,
    RowContent: View
>: View where ViewModel.Item == Item {

    @ObservedObject var viewModel: ViewModel
    @Binding var selectedToolchain: ToolchainInfo?

    let configuration: ToolchainContextListConfiguration<Filter>
    let rowBuilder: (Item, @escaping () -> Void, @escaping () -> Void) -> RowContent
    let searchFilter: (Item, String) -> Bool
    let onInstall: (Item) async -> Void
    let onUninstall: (Item) async -> Void
    let tableHeaderBuilder: () -> AnyView

    @State private var availableToolchains: [ToolchainInfo] = []
    @State private var isLoadingToolchains = false
    @State private var hasInitialized = false

    // Filter and search state
    @State private var filterSelection: Filter = .all
    @State private var searchText = ""

    // Pagination state
    @State private var currentPage = 0
    private let itemsPerPage = 20

    var body: some View {
        HSplitView {
            // Left sidebar: Toolchain list
            toolchainSidebar
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)

            // Right content: Items view
            VStack(spacing: 0) {
                if viewModel.selectedToolchain == nil {
                    selectToolchainPrompt
                } else if viewModel.isLoading {
                    loadingView
                } else if viewModel.items.isEmpty {
                    emptyState
                } else {
                    contentView
                }
            }
        }
        .navigationTitle(configuration.title)
        .onChange(of: selectedToolchain) { _, newToolchain in
            viewModel.selectedToolchain = newToolchain
            Task {
                await viewModel.loadItems()
            }
        }
        .onChange(of: filterSelection) { _, _ in
            currentPage = 0
        }
        .onChange(of: searchText) { _, _ in
            currentPage = 0
        }
        .task {
            guard !hasInitialized else { return }
            hasInitialized = true

            await loadAvailableToolchains()

            if let defaultToolchain = availableToolchains.first(where: { $0.isDefault }) {
                viewModel.selectedToolchain = defaultToolchain
            } else if let firstToolchain = availableToolchains.first {
                viewModel.selectedToolchain = firstToolchain
            } else if let bound = selectedToolchain {
                viewModel.selectedToolchain = bound
            }

            if viewModel.selectedToolchain != nil {
                await viewModel.loadItems()
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

            ScrollView {
                VStack(spacing: GlassTokens.Spacing.xs) {
                    ForEach(currentToolchains) { toolchain in
                        toolchainItem(toolchain)
                    }

                    if !previousVersions.isEmpty {
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
                await viewModel.loadItems()
            }
        } label: {
            HStack(spacing: GlassTokens.Spacing.md) {
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

    // MARK: - Filtering and Pagination

    private var filteredItems: [Item] {
        var filtered = viewModel.items

        switch filterSelection {
        case .all:
            break
        case .installed:
            filtered = filtered.filter { $0.isInstalled }
        case .available:
            filtered = filtered.filter { !$0.isInstalled }
        default:
            break
        }

        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                searchFilter(item, searchText)
            }
        }

        return filtered
    }

    private var paginatedItems: [Item] {
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, filteredItems.count)

        guard startIndex < filteredItems.count else { return [] }

        return Array(filteredItems[startIndex..<endIndex])
    }

    private var totalPages: Int {
        max(1, Int(ceil(Double(filteredItems.count) / Double(itemsPerPage))))
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            searchAndFilterBar
            Divider()
            tableHeaderBuilder()
            Divider()

            if filteredItems.isEmpty {
                emptySearchState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(paginatedItems) { item in
                            rowBuilder(
                                item,
                                { Task { await onInstall(item) } },
                                { Task { await onUninstall(item) } }
                            )
                            Divider()
                        }
                    }
                }

                paginationControls
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
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

            Text(configuration.title)
                .font(.system(size: GlassTokens.Typography.displaySize, weight: .bold))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            if let toolchain = viewModel.selectedToolchain {
                Text(configuration.contentDescription(toolchain))
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
            HStack(spacing: GlassTokens.Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .font(.system(size: GlassTokens.Typography.bodySize))

                TextField(configuration.searchPlaceholder, text: $searchText)
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

            SegmentedChipsView(
                options: Array(Filter.allCases),
                displayName: configuration.filterDisplayName,
                selection: $filterSelection
            )
        }
        .padding(.horizontal, GlassTokens.Spacing.md)
        .padding(.vertical, GlassTokens.Spacing.md)
    }

    // MARK: - Pagination Controls

    @ViewBuilder
    private var paginationControls: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            Text("Page \(currentPage + 1) of \(totalPages)")
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textSecondary)

            Spacer()

            Text("\(filteredItems.count) total items")
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textSecondary)

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
            description: "Choose a toolchain from the Toolchains view to see its \(configuration.title.lowercased())."
        )
    }

    @ViewBuilder
    private var loadingView: some View {
        LoadingView(message: configuration.loadingMessage)
    }

    @ViewBuilder
    private var emptyState: some View {
        EmptyStateView(
            icon: configuration.emptyStateIcon,
            title: configuration.emptyStateTitle,
            description: configuration.emptyStateDescription
        )
    }

    @ViewBuilder
    private var emptySearchState: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            description: "No \(configuration.title.lowercased()) match your search or filter criteria.",
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
