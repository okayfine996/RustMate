//
//  SettingRow.swift
//  RustMate
//
//  Reusable setting row component for consistent settings UI
//

import SwiftUI

struct SettingRow<Content: View>: View {
    let label: String
    let description: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: GlassTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text(label)
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Text(description)
                    .font(.system(size: GlassTokens.Typography.captionSize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
            }

            Spacer()

            content()
        }
    }
}
