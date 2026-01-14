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
    
    // Optional custom button labels and icons
    let discardButtonTitle: String?
    let saveButtonTitle: String?
    let saveButtonIcon: String?
    let isSaveDisabled: Bool
    
    init(
        hasChanges: Bool,
        changeCount: Int = 0,
        statusMessage: String? = nil,
        isLoading: Bool = false,
        discardButtonTitle: String? = nil,
        saveButtonTitle: String? = nil,
        saveButtonIcon: String? = nil,
        isSaveDisabled: Bool = false,
        onDiscard: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        self.hasChanges = hasChanges
        self.changeCount = changeCount
        self.statusMessage = statusMessage
        self.isLoading = isLoading
        self.discardButtonTitle = discardButtonTitle
        self.saveButtonTitle = saveButtonTitle
        self.saveButtonIcon = saveButtonIcon
        self.isSaveDisabled = isSaveDisabled
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
                if hasChanges || discardButtonTitle != nil {
                    Button(discardButtonTitle ?? "Discard Changes") {
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
                        Text(saveButtonTitle ?? "Save & Sync")
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                        
                        if let icon = saveButtonIcon {
                            Image(systemName: icon)
                                .font(.system(size: GlassTokens.Typography.bodySize))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, GlassTokens.Spacing.sm)
                    .padding(.vertical, GlassTokens.Spacing.sm)
                    .background(GlassTokens.Colors.accent)
                    .cornerRadius(GlassTokens.Radius.md)
                }
                .frame(height: 25)
                .padding(.horizontal, GlassTokens.Spacing.md)
                .buttonStyle(.plain)
                .disabled(isLoading || isSaveDisabled)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, GlassTokens.Spacing.lg)
    }
}

// MARK: - Previews

#Preview("With Changes") {
    SettingsStatusBar(
        hasChanges: true,
        changeCount: 3,
        onDiscard: {},
        onSave: {}
    )
    .frame(width: 800)
    .background(GlassTokens.Colors.backgroundPrimary)
}

#Preview("No Changes - Status Message") {
    SettingsStatusBar(
        hasChanges: false,
        statusMessage: "All systems operational!",
        onDiscard: {},
        onSave: {}
    )
    .frame(width: 800)
    .background(GlassTokens.Colors.backgroundPrimary)
}

#Preview("No Changes - Empty") {
    SettingsStatusBar(
        hasChanges: false,
        onDiscard: {},
        onSave: {}
    )
    .frame(width: 800)
    .background(GlassTokens.Colors.backgroundPrimary)
}

#Preview("Loading") {
    SettingsStatusBar(
        hasChanges: true,
        changeCount: 1,
        isLoading: true,
        onDiscard: {},
        onSave: {}
    )
    .frame(width: 800)
    .background(GlassTokens.Colors.backgroundPrimary)
}
