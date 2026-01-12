//
//  SelectionCardView.swift
//  RustMate
//
//  Reusable card component for Components and Targets selection
//

import SwiftUI

// MARK: - Selection Item Model

struct SelectionItem: Identifiable {
    let id: String
    let name: String
    let description: String?
    let isSelected: Bool
    let onToggle: () -> Void
    var badge: String? = nil
    var nameFont: Font? = nil
}

// MARK: - Selection Card View

struct SelectionCardView: View {
    let title: String
    let actionButtonTitle: String
    let showOnColumn: Bool
    let emptyMessage: String
    let items: [SelectionItem]
    let onAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
            // Header (outside card)
            HStack {
                Text(title)
                    .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
                
                Spacer()
                
                Button(actionButtonTitle) {
                    onAction()
                }
                .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                .foregroundColor(GlassTokens.Colors.accent)
                .buttonStyle(.plain)
            }
            
            // Card content
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.md) {
                // Column headers
                HStack(spacing: GlassTokens.Spacing.md) {
                    if showOnColumn {
                        Text("ON")
                            .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                            .frame(width: 40, alignment: .leading)
                    }
                    
                    Text("NAME")
                        .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal, GlassTokens.Spacing.sm)
                
                // Content
                if items.isEmpty {
                    Text(emptyMessage)
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                        .padding(GlassTokens.Spacing.md)
                } else {
                    VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                        ForEach(items) { item in
                            selectionRow(item)
                        }
                    }
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
    }
    
    @ViewBuilder
    private func selectionRow(_ item: SelectionItem) -> some View {
        HStack(alignment: .top, spacing: GlassTokens.Spacing.md) {
            // Checkbox column (if showOnColumn is true)
            if showOnColumn {
                Button {
                    item.onToggle()
                } label: {
                    Image(systemName: item.isSelected ? "checkmark.square.fill" : "square")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(item.isSelected ? GlassTokens.Colors.accent : GlassTokens.Colors.textTertiary)
                }
                .buttonStyle(.plain)
                .frame(width: 40, alignment: .leading)
            }
            
            // Name, badge, and description
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Text(item.name)
                        .font(item.nameFont ?? .system(size: GlassTokens.Typography.bodySize, weight: .medium))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                    
                    if let badge = item.badge {
                        Text(badge)
                            .font(.system(size: GlassTokens.Typography.captionSize, weight: .medium))
                            .foregroundColor(GlassTokens.Colors.textSecondary)
                            .padding(.horizontal, GlassTokens.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(GlassTokens.Colors.backgroundSecondary)
                            .cornerRadius(GlassTokens.Radius.sm)
                    }
                }
                
                if let description = item.description {
                    Text(description)
                        .font(.system(size: GlassTokens.Typography.captionSize))
                        .foregroundColor(GlassTokens.Colors.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, GlassTokens.Spacing.xs)
        .padding(.horizontal, GlassTokens.Spacing.sm)
    }
}

// MARK: - Preview

#Preview("With Items") {
    SelectionCardView(
        title: "Components",
        actionButtonTitle: "ADD COMPONENT",
        showOnColumn: true,
        emptyMessage: "No components configured",
        items: [
            SelectionItem(
                id: "rustfmt",
                name: "rustfmt",
                description: "Code formatter for Rust",
                isSelected: true,
                onToggle: {},
                badge: "Installed"
            ),
            SelectionItem(
                id: "clippy",
                name: "clippy",
                description: "Linting tool for Rust",
                isSelected: true,
                onToggle: {},
                badge: "Installed"
            ),
            SelectionItem(
                id: "rust-analyzer",
                name: "rust-analyzer",
                description: "Language server for Rust",
                isSelected: false,
                onToggle: {}
            )
        ],
        onAction: {}
    )
    .padding()
    .frame(width: 600, height: 400)
    .background(GlassTokens.Colors.backgroundPrimary)
}

#Preview("Empty State") {
    SelectionCardView(
        title: "Targets",
        actionButtonTitle: "ADD TARGET",
        showOnColumn: false,
        emptyMessage: "No targets configured",
        items: [],
        onAction: {}
    )
    .padding()
    .frame(width: 600, height: 300)
    .background(GlassTokens.Colors.backgroundPrimary)
}

#Preview("Without ON Column") {
    SelectionCardView(
        title: "Targets",
        actionButtonTitle: "ADD TARGET",
        showOnColumn: false,
        emptyMessage: "No targets configured",
        items: [
            SelectionItem(
                id: "x86_64-apple-darwin",
                name: "x86_64-apple-darwin",
                description: "macOS on Intel",
                isSelected: true,
                onToggle: {},
                badge: "Tier 1"
            ),
            SelectionItem(
                id: "aarch64-apple-darwin",
                name: "aarch64-apple-darwin",
                description: "macOS on Apple Silicon",
                isSelected: true,
                onToggle: {},
                badge: "Tier 1"
            )
        ],
        onAction: {}
    )
    .padding()
    .frame(width: 600, height: 300)
    .background(GlassTokens.Colors.backgroundPrimary)
}
