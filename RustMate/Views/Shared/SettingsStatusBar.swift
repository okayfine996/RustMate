//
//  SettingsStatusBar.swift
//  RustMate
//
//  Shared status bar component for settings views
//

import SwiftUI

struct SettingsStatusBar: View {
    let hasChanges: Bool
    let changeCount: Int
    let statusMessage: String?
    let isLoading: Bool
    let onDiscard: () -> Void
    let onSave: () -> Void
    
    init(
        hasChanges: Bool,
        changeCount: Int = 0,
        statusMessage: String? = nil,
        isLoading: Bool = false,
        onDiscard: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        self.hasChanges = hasChanges
        self.changeCount = changeCount
        self.statusMessage = statusMessage
        self.isLoading = isLoading
        self.onDiscard = onDiscard
        self.onSave = onSave
    }
    
    var body: some View {
        HStack(spacing: GlassTokens.Spacing.md) {
            // Left: Status indicator
            if hasChanges {
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text("\(changeCount) change\(changeCount == 1 ? "" : "s") pending...")
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                }
            } else if let message = statusMessage {
                HStack(spacing: GlassTokens.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text(message)
                        .font(.system(size: GlassTokens.Typography.bodySize))
                        .foregroundColor(GlassTokens.Colors.textPrimary)
                }
            } else {
                Spacer()
            }
            
            Spacer()
            
            // Right: Action buttons
            HStack(spacing: GlassTokens.Spacing.md) {
                if hasChanges {
                    Button("Discard Changes") {
                        onDiscard()
                    }
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .buttonStyle(.plain)
                }
                
                Button {
                    onSave()
                } label: {
                    HStack(spacing: GlassTokens.Spacing.xs) {
                        Text("Save & Sync")
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                        
                        Image(systemName: "cloud.fill")
                            .font(.system(size: GlassTokens.Typography.bodySize))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, GlassTokens.Spacing.lg)
                    .padding(.vertical, GlassTokens.Spacing.md)
                    .background(GlassTokens.Colors.accent)
                    .cornerRadius(GlassTokens.Radius.md)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
        }
        .padding(GlassTokens.Spacing.lg)
        .background(GlassTokens.Colors.backgroundTertiary)
        .cornerRadius(GlassTokens.Radius.md)
    }
}
