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
            // Header
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
