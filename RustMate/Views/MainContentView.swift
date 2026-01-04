//
//  MainContentView.swift
//  RustMate
//
//  Main application content after setup
//  Feature: 004-glass-ui-refresh - Top navigation bar redesign
//

import SwiftUI

struct MainContentView: View {
    @State private var selectedTab: Tab = .toolchains

    // Keep ViewModels alive across tab switches
    @StateObject private var toolchainViewModel = ToolchainViewModel()
    @StateObject private var tasksViewModel = TasksViewModel()

    enum Tab: String, CaseIterable {
        case toolchains = "Toolchains"
        case components = "Components"
        case targets = "Targets"
        case projects = "Projects"
        case tasks = "Tasks"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .toolchains: return "hammer.fill"
            case .components: return "puzzlepiece.fill"
            case .targets: return "target"
            case .projects: return "folder.fill"
            case .tasks: return "list.bullet"
            case .settings: return "gear"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top navigation bar
            topNavigationBar

            Divider()

            // Content area
            Group {
                switch selectedTab {
                case .toolchains:
                    ToolchainListView(viewModel: toolchainViewModel)
                case .components:
                    ComponentsListView(selectedToolchain: $toolchainViewModel.selectedToolchain)
                case .targets:
                    TargetsListView(selectedToolchain: $toolchainViewModel.selectedToolchain)
                case .projects:
                    ProjectsListView()
                case .tasks:
                    NavigationStack {
                        TasksListView()
                            .environmentObject(tasksViewModel)
                    }
                case .settings:
                    SettingsContentView()
                }
            }
        }
    }

    // MARK: - Top Navigation Bar

    @ViewBuilder
    private var topNavigationBar: some View {
        HStack(spacing: GlassTokens.Spacing.xl) {
            // Left: App logo and name
            HStack(spacing: GlassTokens.Spacing.md) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: GlassTokens.Typography.titleSize))
                    .foregroundColor(GlassTokens.Colors.accent)

                Text("RustMate")
                    .font(.system(size: GlassTokens.Typography.titleSize, weight: .bold))
                    .foregroundColor(GlassTokens.Colors.textPrimary)
            }

            Spacer()

            // Right: Tab navigation
            HStack(spacing: GlassTokens.Spacing.xs) {
                ForEach([Tab.toolchains, Tab.components, Tab.targets, Tab.projects, Tab.tasks, Tab.settings], id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: GlassTokens.Typography.bodySize, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? GlassTokens.Colors.accent : GlassTokens.Colors.textSecondary)
                            .padding(.horizontal, GlassTokens.Spacing.md)
                            .padding(.vertical, GlassTokens.Spacing.sm)
                            .background(
                                selectedTab == tab ?
                                    GlassTokens.Colors.accentSubtle.opacity(0.3) :
                                    Color.clear
                            )
                            .cornerRadius(GlassTokens.Radius.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, GlassTokens.Spacing.lg)
        .padding(.vertical, GlassTokens.Spacing.sm)
        .background(GlassTokens.Colors.cardBackground.opacity(0.8))
    }

    @ViewBuilder
    private func placeholderView(title: String, icon: String) -> some View {
        EmptyStateView(
            icon: icon,
            title: title,
            description: "Coming soon"
        )
    }
}

// MARK: - Settings Content View

struct SettingsContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        SettingsView(settings: appState.settings)
    }
}

// MARK: - Previews

#Preview {
    MainContentView()
}
