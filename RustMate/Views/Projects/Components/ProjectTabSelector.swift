//
//  ProjectTabSelector.swift
//  RustMate
//
//  Tab selector for project views (Toolchain, Cargo, Diagnostics)
//

import SwiftUI

struct ProjectTabSelector: View {
    @Binding var selectedTab: ProjectTab
    let issueCount: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProjectTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(GlassTokens.Animation.fast) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: GlassTokens.Spacing.xs) {
                        Image(systemName: tab.icon)
                            .font(.system(size: GlassTokens.Typography.bodySize))
                            .foregroundColor(selectedTab == tab ? GlassTokens.Colors.accent : GlassTokens.Colors.textSecondary)

                        Text(tab.rawValue)
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                            .foregroundColor(selectedTab == tab ? GlassTokens.Colors.accent : GlassTokens.Colors.textPrimary)

                        // Badge for Diagnostics tab
                        if tab == .info && issueCount > 0 {
                            Text("\(issueCount)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.brown.opacity(0.8))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, GlassTokens.Spacing.lg)
                    .padding(.vertical, GlassTokens.Spacing.md)
                    .overlay(
                        Rectangle()
                            .frame(height: selectedTab == tab ? 2 : 0)
                            .foregroundColor(GlassTokens.Colors.accent),
                        alignment: .bottom
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(GlassTokens.Colors.divider),
            alignment: .bottom
        )
    }
}

// MARK: - ProjectTab Enum

enum ProjectTab: String, CaseIterable {
    case toolchain = "Toolchain Version"
    case cargo = "Cargo & Build"
    case info = "Diagnostics"

    var icon: String {
        switch self {
        case .toolchain: return "wrench.and.screwdriver"
        case .cargo: return "doc.text"
        case .info: return "exclamationmark.triangle"
        }
    }
}
