//
//  AddTargetView.swift
//  RustMate
//
//  Modal view for selecting compilation targets
//

import SwiftUI

struct AddTargetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTargets: Set<String>
    
    @State private var allTargets: [TargetInfo] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var error: Error?
    @State private var localSelectedTargets: Set<String>
    
    let currentToolchain: String
    let existingTargets: Set<String>
    let onAdd: (Set<String>) -> Void
    
    init(
        selectedTargets: Binding<Set<String>>,
        currentToolchain: String = "stable",
        existingTargets: Set<String> = [],
        onAdd: @escaping (Set<String>) -> Void = { _ in }
    ) {
        self._selectedTargets = selectedTargets
        self.currentToolchain = currentToolchain
        self.existingTargets = existingTargets
        self.onAdd = onAdd
        self._localSelectedTargets = State(initialValue: selectedTargets.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Search bar
            searchBar
            
            Divider()
            
            // Content
            if isLoading {
                loadingView
            } else if let error = error {
                errorView(error)
            } else {
                targetList
            }
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 700, height: 600)
        .background(GlassTokens.Colors.backgroundPrimary)
        .task {
            await loadTargets()
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            Text("Add Compilation Targets")
                .font(.system(size: GlassTokens.Typography.titleSize, weight: .bold))
                .foregroundColor(GlassTokens.Colors.textPrimary)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: GlassTokens.Typography.headlineSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(GlassTokens.Spacing.lg)
    }
    
    // MARK: - Search Bar
    
    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: GlassTokens.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(GlassTokens.Colors.textSecondary)
            
            TextField("Search targets (e.g. wasm32, msvc)...", text: $searchText)
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
            
            // Keyboard shortcut hint
            Text("⌘K")
                .font(.system(size: GlassTokens.Typography.captionSize, design: .monospaced))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .padding(.horizontal, GlassTokens.Spacing.xs)
                .padding(.vertical, 2)
                .background(GlassTokens.Colors.backgroundSecondary)
                .cornerRadius(GlassTokens.Radius.sm)
        }
        .padding(GlassTokens.Spacing.md)
        .background(GlassTokens.Colors.backgroundSecondary)
        .cornerRadius(GlassTokens.Radius.sm)
        .padding(.horizontal, GlassTokens.Spacing.lg)
        .padding(.vertical, GlassTokens.Spacing.md)
    }
    
    // MARK: - Target List
    
    @ViewBuilder
    private var targetList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
                ForEach(groupedTargets.keys.sorted(), id: \.self) { category in
                    if let targets = groupedTargets[category], !targets.isEmpty {
                        targetCategorySection(category: category, targets: targets)
                    }
                }
            }
            .padding(GlassTokens.Spacing.lg)
        }
    }
    
    @ViewBuilder
    private func targetCategorySection(category: String, targets: [TargetInfo]) -> some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Category header
            HStack(spacing: GlassTokens.Spacing.sm) {
                Image(systemName: categoryIcon(category))
                    .font(.system(size: GlassTokens.Typography.headlineSize))
                    .foregroundColor(GlassTokens.Colors.accent)
                
                Text(category.uppercased())
                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }
            .padding(.bottom, GlassTokens.Spacing.xs)
            
            // Target items
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                ForEach(targets) { target in
                    targetRow(target)
                }
            }
        }
    }
    
    @ViewBuilder
    private func targetRow(_ target: TargetInfo) -> some View {
        let isSelected = localSelectedTargets.contains(target.triple)
        let tier = targetTier(target.triple)
        
        Button {
            if isSelected {
                localSelectedTargets.remove(target.triple)
            } else {
                localSelectedTargets.insert(target.triple)
            }
        } label: {
            HStack(spacing: GlassTokens.Spacing.md) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(isSelected ? GlassTokens.Colors.accent : GlassTokens.Colors.textTertiary)
                    .frame(width: 24)
                
                // Target info
                VStack(alignment: .leading, spacing: 2) {
                    Text(target.triple)
                        .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                    
                    if let description = target.description {
                        Text(description)
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Status badges
                HStack(spacing: GlassTokens.Spacing.sm) {
                    if target.isInstalled {
                        Text("✓ Installed")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                    
                    if let tier = tier {
                        tierBadge(tier)
                    }
                }
            }
            .padding(GlassTokens.Spacing.md)
            .background(
                isSelected
                    ? GlassTokens.Colors.accent.opacity(0.1)
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
    
    @ViewBuilder
    private func tierBadge(_ tier: String) -> some View {
        let isTier1 = tier == "Tier 1"
        Text(tier)
            .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
            .foregroundColor(isTier1 ? .white : GlassTokens.Colors.textPrimary)
            .padding(.horizontal, GlassTokens.Spacing.xs)
            .padding(.vertical, 2)
            .background(
                isTier1
                    ? Color.green
                    : GlassTokens.Colors.backgroundSecondary
            )
            .cornerRadius(GlassTokens.Radius.sm)
    }
    
    // MARK: - Footer
    
    @ViewBuilder
    private var footerView: some View {
        HStack {
            Text("\(localSelectedTargets.count) target\(localSelectedTargets.count == 1 ? "" : "s") selected")
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
            
            Spacer()
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
            
            Button("Add Targets") {
                // Only add new targets (not already existing)
                let newTargets = localSelectedTargets.subtracting(existingTargets)
                onAdd(newTargets)
                selectedTargets = localSelectedTargets
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(localSelectedTargets.isEmpty)
        }
        .padding(GlassTokens.Spacing.lg)
    }
    
    // MARK: - Loading & Error
    
    @ViewBuilder
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Loading targets...")
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .padding(.top, GlassTokens.Spacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: GlassTokens.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: GlassTokens.Typography.titleSize))
                .foregroundColor(GlassTokens.Colors.error)
            
            Text("Failed to load targets")
                .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textPrimary)
            
            Text(error.localizedDescription)
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(GlassTokens.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Functions
    
    private var filteredTargets: [TargetInfo] {
        if searchText.isEmpty {
            return allTargets
        }
        
        let lowerSearch = searchText.lowercased()
        return allTargets.filter { target in
            target.triple.lowercased().contains(lowerSearch) ||
            target.description?.lowercased().contains(lowerSearch) == true
        }
    }
    
    private var groupedTargets: [String: [TargetInfo]] {
        var groups: [String: [TargetInfo]] = [:]
        
        for target in filteredTargets {
            let category = targetCategory(target.triple)
            if groups[category] == nil {
                groups[category] = []
            }
            groups[category]?.append(target)
        }
        
        // Sort targets within each category
        for key in groups.keys {
            groups[key]?.sort { $0.triple < $1.triple }
        }
        
        return groups
    }
    
    private func targetCategory(_ triple: String) -> String {
        let lower = triple.lowercased()
        
        if lower.contains("wasm32") {
            return "WebAssembly"
        } else if lower.contains("apple") || lower.contains("darwin") || lower.contains("ios") {
            return "Apple Darwin"
        } else if lower.contains("windows") || lower.contains("msvc") || lower.contains("gnu") && lower.contains("pc-windows") {
            return "Windows"
        } else if lower.contains("linux") {
            return "Linux"
        } else if lower.contains("android") {
            return "Android"
        } else if lower.contains("freebsd") || lower.contains("netbsd") || lower.contains("openbsd") {
            return "BSD"
        } else {
            return "Other"
        }
    }
    
    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "WebAssembly":
            return "globe"
        case "Apple Darwin":
            return "apple.logo"
        case "Windows":
            return "square.grid.2x2"
        case "Linux":
            return "terminal"
        case "Android":
            return "phone"
        case "BSD":
            return "server.rack"
        default:
            return "cpu"
        }
    }
    
    private func targetTier(_ triple: String) -> String? {
        let lower = triple.lowercased()
        
        // Tier 1 targets (fully supported)
        let tier1Targets = [
            "x86_64-apple-darwin",
            "x86_64-pc-windows-msvc",
            "x86_64-unknown-linux-gnu",
            "aarch64-apple-darwin",
            "aarch64-unknown-linux-gnu",
            "i686-pc-windows-msvc",
            "i686-unknown-linux-gnu"
        ]
        
        if tier1Targets.contains(where: { lower.contains($0) }) {
            return "Tier 1"
        }
        
        // Tier 2 targets (guaranteed to build)
        return "Tier 2"
    }
    
    private func loadTargets() async {
        isLoading = true
        error = nil
        
        do {
            let service = LocalRustupToolchainService()
            let targets = try await service.listTargets(toolchainName: currentToolchain)
            
            // Filter out already existing targets
            allTargets = targets.filter { !existingTargets.contains($0.triple) }
        } catch {
            self.error = error
            allTargets = []
        }
        
        isLoading = false
    }
}
