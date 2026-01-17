//
//  SettingsSidebar.swift
//  RustMate
//
//  Settings navigation sidebar
//

import SwiftUI

struct SettingsSidebar: View {
    @Binding var selectedSection: SettingsSection

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()
                .background(GlassTokens.Colors.divider)

            // Navigation items
            ScrollView {
                VStack(spacing: GlassTokens.Spacing.xs) {
                    ForEach(SettingsSection.allCases, id: \.self) { section in
                        navigationItem(section: section)
                    }
                }
                .padding(.vertical, GlassTokens.Spacing.md)
            }

            Spacer()

            // Links section
            linksSection
        }
        .background(GlassTokens.Colors.cardBackground.opacity(0.5))
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
            Text("Settings")
                .font(.system(size: GlassTokens.Typography.titleSize, weight: .bold))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            Text("Manage preferences")
                .font(.system(size: GlassTokens.Typography.captionSize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
        }
        .padding(.horizontal, GlassTokens.Spacing.lg)
        .padding(.top, GlassTokens.Spacing.xl)
        .padding(.bottom, GlassTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Navigation Item

    @ViewBuilder
    private func navigationItem(section: SettingsSection) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = section
            }
        } label: {
            HStack(spacing: GlassTokens.Spacing.md) {
                Image(systemName: section.icon)
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(selectedSection == section ? GlassTokens.Colors.accent : GlassTokens.Colors.textSecondary)
                    .frame(width: 20)

                Text(section.rawValue)
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: selectedSection == section ? .semibold : .regular))
                    .foregroundColor(selectedSection == section ? GlassTokens.Colors.textPrimary : GlassTokens.Colors.textSecondary)

                Spacer()
            }
            .padding(.horizontal, GlassTokens.Spacing.lg)
            .padding(.vertical, GlassTokens.Spacing.sm)
            .background(selectedSection == section ? GlassTokens.Colors.accentSubtle.opacity(0.3) : Color.clear)
            .cornerRadius(GlassTokens.Radius.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Links Section

    @ViewBuilder
    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .background(GlassTokens.Colors.divider)

            VStack(alignment: .leading, spacing: GlassTokens.Spacing.xs) {
                Text("LINKS")
                    .font(.system(size: GlassTokens.Typography.captionSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .tracking(0.5)
                    .padding(.horizontal, GlassTokens.Spacing.lg)
                    .padding(.top, GlassTokens.Spacing.lg)
                    .padding(.bottom, GlassTokens.Spacing.xs)

                VStack(spacing: GlassTokens.Spacing.xs) {
                    linkItem(title: "Documentation", icon: "questionmark.circle", action: {
                        if let url = URL(string: "https://github.com/okayfine996/RustMate") {
                            NSWorkspace.shared.open(url)
                        }
                    })

                    linkItem(title: "Report Issue", icon: "exclamationmark.circle", action: {
                        if let url = URL(string: "https://github.com/okayfine996/RustMate/issues") {
                            NSWorkspace.shared.open(url)
                        }
                    })
                }
            }
            .padding(.bottom, GlassTokens.Spacing.lg)
        }
    }

    @ViewBuilder
    private func linkItem(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: GlassTokens.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textSecondary)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: GlassTokens.Typography.bodySize))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, GlassTokens.Spacing.lg)
            .padding(.vertical, GlassTokens.Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}
