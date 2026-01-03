//
//  SegmentedChipsView.swift
//  RustMate
//
//  Created by Speckit on 2026-01-02.
//  Feature: 004-glass-ui-refresh
//

import SwiftUI

/// Segmented chip filter for categorizing content
/// Provides pill-shaped filter options for toolchains, components, etc.
struct SegmentedChipsView<T: Hashable>: View {
    let options: [T]
    let displayName: (T) -> String
    @Binding var selection: T

    var body: some View {
        HStack(spacing: GlassTokens.Spacing.sm) {
            ForEach(options, id: \.self) { option in
                ChipButton(
                    title: displayName(option),
                    isSelected: selection == option,
                    action: { selection = option }
                )
            }
        }
    }
}

private struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: GlassTokens.Typography.calloutSize, weight: .medium))
                .padding(.horizontal, GlassTokens.Spacing.md)
                .padding(.vertical, GlassTokens.Spacing.sm)
        }
        .buttonStyle(ChipButtonStyle(isSelected: isSelected, reduceMotion: reduceMotion))
        .focusEffectDisabled()
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct ChipButtonStyle: ButtonStyle {
    let isSelected: Bool
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                isSelected
                    ? GlassTokens.Colors.accent
                    : GlassTokens.Colors.cardBackground
            )
            .foregroundColor(
                isSelected
                    ? .white
                    : GlassTokens.Colors.textPrimary
            )
            .cornerRadius(GlassTokens.Radius.pill)
            .overlay(
                RoundedRectangle(cornerRadius: GlassTokens.Radius.pill)
                    .stroke(
                        isSelected ? Color.clear : GlassTokens.Colors.divider,
                        lineWidth: GlassTokens.Stroke.thin
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(reduceMotion ? nil : GlassTokens.Animation.fast, value: configuration.isPressed)
            .animation(reduceMotion ? nil : GlassTokens.Animation.fast, value: isSelected)
    }
}

// MARK: - Previews

enum FilterOption: String, CaseIterable {
    case all = "All"
    case stable = "Stable"
    case beta = "Beta"
    case nightly = "Nightly"
}

#Preview("Segmented Chips") {
    @Previewable @State var selection: FilterOption = .all

    VStack(spacing: GlassTokens.Spacing.xl) {
        SegmentedChipsView(
            options: FilterOption.allCases,
            displayName: { $0.rawValue },
            selection: $selection
        )

        Text("Selected: \(selection.rawValue)")
            .font(.system(size: GlassTokens.Typography.bodySize))
            .foregroundColor(GlassTokens.Colors.textSecondary)
    }
    .padding(GlassTokens.Spacing.xl)
}

#Preview("Segmented Chips - Dark") {
    @Previewable @State var selection: FilterOption = .stable

    VStack(spacing: GlassTokens.Spacing.xl) {
        SegmentedChipsView(
            options: FilterOption.allCases,
            displayName: { $0.rawValue },
            selection: $selection
        )

        Text("Selected: \(selection.rawValue)")
            .font(.system(size: GlassTokens.Typography.bodySize))
            .foregroundColor(GlassTokens.Colors.textSecondary)
    }
    .padding(GlassTokens.Spacing.xl)
    .preferredColorScheme(.dark)
}
