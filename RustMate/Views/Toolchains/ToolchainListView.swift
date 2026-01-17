//
//  ToolchainListView.swift
//  RustMate
//
//  Main toolchain management view
//

import SwiftUI

struct ToolchainListView: View {
    @ObservedObject var viewModel: ToolchainViewModel
    @State private var showInstallSheet = false
    @State private var showDeleteConfirmation = false
    @State private var toolchainToDelete: ToolchainInfo?
    @State private var searchText = ""
    @State private var filterSelection: ToolchainFilter = .all
    @State private var currentPage = 0

    private let itemsPerPage = 10

    enum ToolchainFilter: String, CaseIterable {
        case all = "All"
        case stable = "Stable"
        case beta = "Beta"
        case nightly = "Nightly"
    }

    init(viewModel: ToolchainViewModel) {
        self.viewModel = viewModel
    }

    // Convenience init for previews
    init(service: RustToolchainServiceProtocol = LocalRustupToolchainService()) {
        self.viewModel = ToolchainViewModel(service: service)
    }

    private var filteredToolchains: [ToolchainInfo] {
        var filtered = viewModel.toolchains

        // Apply channel filter
        switch filterSelection {
        case .all:
            break
        case .stable:
            filtered = filtered.filter { channelName(for: $0) == "Stable" }
        case .beta:
            filtered = filtered.filter { channelName(for: $0) == "Beta" }
        case .nightly:
            filtered = filtered.filter { channelName(for: $0) == "Nightly" }
        }

        // Apply search text filter
        if !searchText.isEmpty {
            filtered = filtered.filter { toolchain in
                toolchain.name.localizedCaseInsensitiveContains(searchText) ||
                (toolchain.version?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                channelName(for: toolchain).localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    private var paginatedToolchains: [ToolchainInfo] {
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, filteredToolchains.count)
        guard startIndex < filteredToolchains.count else { return [] }
        return Array(filteredToolchains[startIndex..<endIndex])
    }

    private var totalPages: Int {
        max(1, (filteredToolchains.count + itemsPerPage - 1) / itemsPerPage)
    }

    private func channelName(for toolchain: ToolchainInfo) -> String {
        // Check if toolchain name starts with a version number (e.g., "1.91-aarch64-apple-darwin")
        // These are specific stable release versions
        if let firstChar = toolchain.name.first, firstChar.isNumber {
            return "Stable"
        }

        if toolchain.name.contains("stable") {
            return "Stable"
        } else if toolchain.name.contains("nightly") {
            return "Nightly"
        } else if toolchain.name.contains("beta") {
            return "Beta"
        } else {
            return "Custom"
        }
    }

    private func channelColor(for channel: String) -> Color {
        switch channel {
        case "Stable": return GlassTokens.Colors.success
        case "Nightly": return Color.purple
        case "Beta": return Color.blue
        default: return GlassTokens.Colors.textSecondary
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.toolchains.isEmpty {
                LoadingView(message: "Loading toolchains...")
            } else if let error = viewModel.error, viewModel.toolchains.isEmpty {
                // T044: Show authorization-specific UI when needed
                if viewModel.requiresAuthorization {
                    authorizationRequiredView
                } else {
                    standardErrorView(error)
                }
            } else if viewModel.toolchains.isEmpty {
                emptyState
            } else {
                toolchainsContentView
            }
        }
        .task {
            await viewModel.loadToolchains()
        }
        .sheet(isPresented: $showInstallSheet) {
            InstallToolchainSheet(viewModel: viewModel)
        }
        .confirmationDialog(
            "Uninstall \(toolchainToDelete?.name ?? "")?",
            isPresented: $showDeleteConfirmation,
            presenting: toolchainToDelete
        ) { toolchain in
            Button("Uninstall", role: .destructive) {
                Task {
                    await viewModel.uninstallToolchain(toolchain)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { toolchain in
            Text("This will remove the \(toolchain.name) toolchain from your system.")
        }
    }

    // MARK: - Main Content View

    @ViewBuilder
    private var toolchainsContentView: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding(GlassTokens.Spacing.md)

            Divider()

            // Search and disk usage bar
            searchAndDiskUsageBar
//                .padding(GlassTokens.Spacing.md)

            Divider()

            // Table
            toolchainTable

            // Pagination
            paginationBar
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .top, spacing: GlassTokens.Spacing.xl) {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                Text("Toolchains")
                    .font(.system(size: GlassTokens.Typography.displaySize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text("Manage your installed Rust toolchains, overrides, and components. Keep your development environment up to date.")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                showInstallSheet = true
            } label: {
                HStack(spacing: GlassTokens.Spacing.xs) {
                    Image(systemName: "plus")
                    Text("Install New Toolchain")
                }
                .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                .padding(.horizontal, GlassTokens.Spacing.lg)
                .padding(.vertical, GlassTokens.Spacing.md)
            }
            .primaryGlassButtonStyle()
        }
    }

    // MARK: - Search and Filter Bar

    @ViewBuilder
    private var searchAndDiskUsageBar: some View {
        HStack(spacing: GlassTokens.Spacing.lg) {
            // Search field
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)

                TextField("Filter by name, channel (stable, nightly), or version...", text: $searchText)
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
            .background(GlassTokens.Colors.cardBackground.opacity(0.5))
            .cornerRadius(GlassTokens.Radius.md)

            // Filter chips
            SegmentedChipsView(
                options: ToolchainFilter.allCases,
                displayName: { $0.rawValue },
                selection: $filterSelection
            )

            Spacer()
        }
    }

    // MARK: - Toolchain Table

    @ViewBuilder
    private var toolchainTable: some View {
        VStack(spacing: 0) {
            // Table header
            HStack(spacing: GlassTokens.Spacing.md) {
                Text("TOOLCHAIN NAME")
                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .frame(width: 300, alignment: .leading)

                Text("CHANNEL")
                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .frame(width: 120, alignment: .leading)

                Text("VERSION")
                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .frame(width: 200, alignment: .leading)

                Text("STATUS")
                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .frame(width: 150, alignment: .leading)

                Spacer()

                Text("ACTIONS")
                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .frame(width: 120, alignment: .trailing)
            }
            .padding(.horizontal, GlassTokens.Spacing.lg)
            .padding(.vertical, GlassTokens.Spacing.md)
            .background(GlassTokens.Colors.cardBackground.opacity(0.3))

            Divider()

            // Table rows
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(paginatedToolchains.enumerated()), id: \.element.id) { index, toolchain in
                        toolchainRow(toolchain)

                        if index < paginatedToolchains.count - 1 {
                            Divider()
                                .padding(.leading, GlassTokens.Spacing.lg)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func toolchainRow(_ toolchain: ToolchainInfo) -> some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // Toolchain name
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text(toolchain.name)
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium, design: .monospaced))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                if let date = toolchain.installDate {
                    Text("Last used: \(formatRelativeDate(date))")
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
            }
            .frame(width: 300, alignment: .leading)

            // Channel badge
            Text(channelName(for: toolchain))
                .font(.system(size: GlassTokens.Typography.calloutSize, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, GlassTokens.Spacing.sm)
                .padding(.vertical, 4)
                .background(channelColor(for: channelName(for: toolchain)))
                .cornerRadius(GlassTokens.Radius.sm)
                .frame(width: 120, alignment: .leading)

            // Version
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                let displayVersion = toolchain.version ?? extractVersionFromName(toolchain.name)
                if !displayVersion.isEmpty {
                    Text(displayVersion)
                        .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                } else {
                    Text("—")
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
            }
            .frame(width: 200, alignment: .leading)

            // Status
            HStack(spacing: GlassTokens.Spacing.xs) {
                if toolchain.isDefault {
                    Text("Default")
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                } else {
                    Text("Installed")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
            }
            .frame(width: 150, alignment: .leading)

            Spacer()

            // Actions - inline buttons
            HStack(spacing: GlassTokens.Spacing.xs) {
                // Update button - only show for channel-based toolchains (stable, beta, nightly)
                // Fixed version toolchains (e.g., 1.75.0-aarch64-apple-darwin) cannot be updated
                if canUpdateToolchain(toolchain) {
                    Button {
                        Task {
                            await viewModel.updateToolchain(toolchain)
                        }
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: GlassTokens.Typography.calloutSize))
                            .foregroundColor(GlassTokens.Colors.accent)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .help("Update toolchain")
                }

                if !toolchain.isDefault {
                    // Set Default button
                    Button {
                        Task {
                            await viewModel.setDefaultToolchain(toolchain)
                        }
                    } label: {
                        Image(systemName: "pin.circle.fill")
                            .font(.system(size: GlassTokens.Typography.calloutSize))
                            .foregroundColor(GlassTokens.Colors.accent)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .help("Set as default toolchain")

                    // Uninstall button
                    Button {
                        toolchainToDelete = toolchain
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: GlassTokens.Typography.calloutSize))
                            .foregroundColor(GlassTokens.Colors.error)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .help("Uninstall toolchain")
                }
            }
            .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, GlassTokens.Spacing.lg)
        .padding(.vertical, GlassTokens.Spacing.md)
        .contentShape(Rectangle())
    }

    // MARK: - Pagination Bar

    @ViewBuilder
    private var paginationBar: some View {
        HStack {
            Text("Showing \(filteredToolchains.isEmpty ? 0 : currentPage * itemsPerPage + 1) to \(min((currentPage + 1) * itemsPerPage, filteredToolchains.count)) of \(filteredToolchains.count) toolchains")
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textSecondary)

            Spacer()

            HStack(spacing: GlassTokens.Spacing.sm) {
                Button {
                    if currentPage > 0 {
                        currentPage -= 1
                    }
                } label: {
                    Text("Previous")
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                        .foregroundColor(currentPage > 0 ? GlassTokens.Colors.textPrimary : GlassTokens.Colors.textSecondary)
                        .padding(.horizontal, GlassTokens.Spacing.md)
                        .padding(.vertical, GlassTokens.Spacing.sm)
                }
                .buttonStyle(.plain)
                .disabled(currentPage == 0)

                Button {
                    if currentPage < totalPages - 1 {
                        currentPage += 1
                    }
                } label: {
                    Text("Next")
                        .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                        .foregroundColor(currentPage < totalPages - 1 ? GlassTokens.Colors.textPrimary : GlassTokens.Colors.textSecondary)
                        .padding(.horizontal, GlassTokens.Spacing.md)
                        .padding(.vertical, GlassTokens.Spacing.sm)
                }
                .buttonStyle(.plain)
                .disabled(currentPage >= totalPages - 1)
            }
        }
        .padding(GlassTokens.Spacing.lg)
        .background(GlassTokens.Colors.cardBackground.opacity(0.3))
    }

    private func formatRelativeDate(_ date: Date) -> String {
        DateFormatters.formatRelativeDate(date)
    }

    private func extractVersionFromName(_ name: String) -> String {
        // Extract version from toolchain name
        // Examples:
        // "1.91-aarch64-apple-darwin" -> "1.91"
        // "stable-aarch64-apple-darwin" -> "stable"
        // "nightly-2024-01-01-aarch64-apple-darwin" -> "nightly-2024-01-01"

        let components = name.split(separator: "-")
        guard !components.isEmpty else { return "" }

        // Check if first component is a version number (starts with digit)
        let firstComponent = String(components[0])
        if firstComponent.first?.isNumber == true {
            // It's a version like "1.91", return it
            return firstComponent
        }

        // For named channels (stable, beta, nightly), try to find version
        // If it's nightly with date: "nightly-2024-01-01-..."
        if components.count >= 2 && firstComponent == "nightly" {
            let secondComponent = String(components[1])
            // Check if second component is a date (starts with digit)
            if secondComponent.first?.isNumber == true {
                return "\(firstComponent)-\(secondComponent)"
            }
        }

        // Return the channel name as version
        return firstComponent
    }
    
    /// Check if a toolchain can be updated
    /// Fixed version toolchains (e.g., 1.75.0-aarch64-apple-darwin) cannot be updated
    /// Only channel-based toolchains (stable, beta, nightly) can be updated
    private func canUpdateToolchain(_ toolchain: ToolchainInfo) -> Bool {
        let name = toolchain.name
        let components = name.split(separator: "-")
        guard !components.isEmpty else { return false }
        
        let firstComponent = String(components[0])
        
        // If the first component starts with a digit, it's a fixed version toolchain
        // Fixed version toolchains cannot be updated
        if firstComponent.first?.isNumber == true {
            return false
        }
        
        // Channel-based toolchains (stable, beta, nightly) can be updated
        return firstComponent == "stable" || firstComponent == "beta" || firstComponent == "nightly"
    }

    // MARK: - Authorization Required View (T044)

    @ViewBuilder
    private var authorizationRequiredView: some View {
        if let presentation = viewModel.errorPresentation {
            AuthorizationRequiredView(
                title: presentation.title,
                message: presentation.message,
                missingPurposes: extractMissingPurposes(from: viewModel.error),
                onAuthorize: {
                    // Post authorization request notification
                    let purposes = extractMissingPurposes(from: viewModel.error)
                    AuthorizationCoordinator.requestAuthorization(for: purposes)
                },
                onOpenSettings: {
                    // Open Settings window
                    EventBus.shared.publishWithLegacy(.openSettings, notification: Constants.Notifications.openSettings)
                }
            )
        }
    }

    @ViewBuilder
    private func standardErrorView(_ error: Error) -> some View {
        if let presentation = viewModel.errorPresentation {
            ErrorView(
                title: presentation.title,
                message: presentation.message,
                hints: presentation.suggestedFix.map { [$0] } ?? [
                    "Ensure all required directories are authorized in Settings",
                    "Verify rustup is installed and accessible",
                    "Check that ~/.cargo/bin, ~/.cargo, and ~/.rustup are authorized"
                ],
                actionTitle: "Retry",
                action: {
                    Task {
                        await viewModel.loadToolchains()
                    }
                }
            )
        } else {
            ErrorView(
                message: error.localizedDescription,
                hints: [
                    "Ensure all required directories are authorized in Settings",
                    "Verify rustup is installed and accessible"
                ],
                actionTitle: "Retry",
                action: {
                    Task {
                        await viewModel.loadToolchains()
                    }
                }
            )
        }
    }

    private func extractMissingPurposes(from error: Error?) -> [AuthorizedDirectory.DirectoryPurpose] {
        AuthorizationHelpers.extractMissingPurposes(from: error)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        EmptyStateView(
            icon: "hammer",
            title: "No Toolchains",
            description: "You haven't installed any Rust toolchains yet. Get started by installing your first toolchain.",
            actionTitle: "Install Toolchain",
            action: {
                showInstallSheet = true
            }
        )
    }
}

// MARK: - Previews

#Preview("With Toolchains") {
    NavigationStack {
        ToolchainListView(service: MockToolchainService())
    }
}

#Preview("Empty State") {
    let service = MockToolchainService()
    // Mock empty response
    return NavigationStack {
        ToolchainListView(service: service)
    }
}

#Preview("Install Sheet") {
    InstallToolchainSheet(viewModel: ToolchainViewModel(service: MockToolchainService()))
}
