//
//  AddComponentView.swift
//  RustMate
//
//  Modal view for selecting Rust components
//

import SwiftUI

struct AddComponentView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedComponents: Set<String>
    
    @State private var allComponents: [ComponentInfo] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var error: Error?
    @State private var localSelectedComponents: Set<String>
    
    let currentToolchain: String
    let existingComponents: Set<String>
    let onAdd: (Set<String>) -> Void
    
    init(
        selectedComponents: Binding<Set<String>>,
        currentToolchain: String = "stable",
        existingComponents: Set<String> = [],
        onAdd: @escaping (Set<String>) -> Void = { _ in }
    ) {
        self._selectedComponents = selectedComponents
        self.currentToolchain = currentToolchain
        self.existingComponents = existingComponents
        self.onAdd = onAdd
        self._localSelectedComponents = State(initialValue: selectedComponents.wrappedValue)
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
                componentList
            }
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 700, height: 600)
        .background(GlassTokens.Colors.backgroundPrimary)
        .task {
            await loadComponents()
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            Text("Add Components")
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
            
            TextField("Search components (e.g. rustfmt, clippy)...", text: $searchText)
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
    
    // MARK: - Component List
    
    @ViewBuilder
    private var componentList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: GlassTokens.Spacing.xl) {
                ForEach(groupedComponents.keys.sorted(), id: \.self) { category in
                    if let components = groupedComponents[category], !components.isEmpty {
                        componentCategorySection(category: category, components: components)
                    }
                }
            }
            .padding(GlassTokens.Spacing.lg)
        }
    }
    
    @ViewBuilder
    private func componentCategorySection(category: String, components: [ComponentInfo]) -> some View {
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
            
            // Component items
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                ForEach(components) { component in
                    componentRow(component)
                }
            }
        }
    }
    
    @ViewBuilder
    private func componentRow(_ component: ComponentInfo) -> some View {
        let baseName = extractBaseComponentName(component.name)
        let isSelected = localSelectedComponents.contains(baseName)
        let displayName = component.displayName
        
        Button {
            if isSelected {
                localSelectedComponents.remove(baseName)
            } else {
                localSelectedComponents.insert(baseName)
            }
        } label: {
            HStack(spacing: GlassTokens.Spacing.md) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(isSelected ? GlassTokens.Colors.accent : GlassTokens.Colors.textTertiary)
                    .frame(width: 24)
                
                // Component info
                VStack(alignment: .leading, spacing: 2) {
                    Text(baseName)
                        .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                    
                    if let description = component.description {
                        Text(description)
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Status badges
                HStack(spacing: GlassTokens.Spacing.sm) {
                    if component.isInstalled {
                        Text("✓ Installed")
                            .font(.system(size: GlassTokens.Typography.captionSize))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
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
    
    // MARK: - Footer
    
    @ViewBuilder
    private var footerView: some View {
        HStack {
            Text("\(localSelectedComponents.count) component\(localSelectedComponents.count == 1 ? "" : "s") selected")
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
            
            Spacer()
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
            
            Button("Add Components") {
                // Only add new components (not already existing)
                let newComponents = localSelectedComponents.subtracting(existingComponents)
                onAdd(newComponents)
                selectedComponents = localSelectedComponents
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(localSelectedComponents.isEmpty)
        }
        .padding(GlassTokens.Spacing.lg)
    }
    
    // MARK: - Loading & Error
    
    @ViewBuilder
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Loading components...")
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
            
            Text("Failed to load components")
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
    
    private var filteredComponents: [ComponentInfo] {
        if searchText.isEmpty {
            return allComponents
        }
        
        let lowerSearch = searchText.lowercased()
        return allComponents.filter { component in
            component.name.lowercased().contains(lowerSearch) ||
            component.displayName.lowercased().contains(lowerSearch) ||
            component.description?.lowercased().contains(lowerSearch) == true
        }
    }
    
    private var groupedComponents: [String: [ComponentInfo]] {
        var groups: [String: [ComponentInfo]] = [:]
        
        for component in filteredComponents {
            let category = componentCategory(component)
            if groups[category] == nil {
                groups[category] = []
            }
            groups[category]?.append(component)
        }
        
        // Sort components within each category
        for key in groups.keys {
            groups[key]?.sort { $0.displayName < $1.displayName }
        }
        
        return groups
    }
    
    private func componentCategory(_ component: ComponentInfo) -> String {
        switch component.componentType {
        case .rustfmt:
            return "Code Formatting"
        case .clippy:
            return "Linting"
        case .rustSrc:
            return "Source Code"
        case .llvmTools:
            return "LLVM Tools"
        case .rustDocs:
            return "Documentation"
        case .rustAnalyzer:
            return "Language Server"
        case .other:
            return "Other"
        }
    }
    
    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Code Formatting":
            return "paintbrush"
        case "Linting":
            return "checkmark.seal"
        case "Source Code":
            return "doc.text"
        case "LLVM Tools":
            return "wrench.and.screwdriver"
        case "Documentation":
            return "book"
        case "Language Server":
            return "brain"
        default:
            return "puzzlepiece"
        }
    }
    
    private func loadComponents() async {
        isLoading = true
        error = nil
        
        do {
            let service = LocalRustupToolchainService()
            let components = try await service.listComponents(toolchainName: currentToolchain)
            
            // Filter out already existing components and extract base component names
            // Components like "rustfmt-aarch64-apple-darwin" should be shown as "rustfmt"
            var uniqueComponents: [String: ComponentInfo] = [:]
            
            for component in components {
                // Extract base name (e.g., "rustfmt" from "rustfmt-aarch64-apple-darwin")
                let baseName = extractBaseComponentName(component.name)
                
                // Only keep one instance per base name, prefer installed ones
                if let existing = uniqueComponents[baseName] {
                    if component.isInstalled && !existing.isInstalled {
                        uniqueComponents[baseName] = component
                    }
                } else {
                    uniqueComponents[baseName] = component
                }
            }
            
            // Filter out already existing components and use base names
            allComponents = Array(uniqueComponents.values)
                .filter { 
                    let baseName = extractBaseComponentName($0.name)
                    return !existingComponents.contains(baseName)
                }
        } catch {
            self.error = error
            allComponents = []
        }
        
        isLoading = false
    }
    
    private func extractBaseComponentName(_ fullName: String) -> String {
        // Extract base component name from full name
        // Examples:
        // "rustfmt-aarch64-apple-darwin" -> "rustfmt"
        // "clippy-x86_64-apple-darwin" -> "clippy"
        // "rust-src" -> "rust-src"
        
        // Common patterns: component-name-arch-vendor-os or just component-name
        let parts = fullName.split(separator: "-")
        
        // Special case: rust-src is always just "rust-src"
        if fullName == "rust-src" {
            return "rust-src"
        }
        
        // For others, take the first part (e.g., "rustfmt", "clippy")
        if let firstPart = parts.first {
            return String(firstPart)
        }
        
        return fullName
    }
}
