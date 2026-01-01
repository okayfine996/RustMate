//
//  MainContentView.swift
//  RustMate
//
//  Main application content after setup
//

import SwiftUI

struct MainContentView: View {
    @State private var selectedTab: Tab = .toolchains

    // Keep ViewModels alive across tab switches
    @StateObject private var toolchainViewModel = ToolchainViewModel()
    @StateObject private var tasksViewModel = TasksViewModel()

    init() {
        // Ensure bookmark is sent to XPC service when main view appears
        XPCClient.shared.sendCargoBookmark()
    }

    enum Tab: String, CaseIterable {
        case toolchains = "Toolchains"
        case components = "Components"
        case targets = "Targets"
        case projects = "Projects"
        case tasks = "Tasks"

        var icon: String {
            switch self {
            case .toolchains: return "hammer.fill"
            case .components: return "puzzlepiece.fill"
            case .targets: return "target"
            case .projects: return "folder.fill"
            case .tasks: return "list.bullet"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(Tab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            // Content
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
                }
            }
        }
        .navigationTitle(selectedTab.rawValue)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    // Refresh action
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")

                Button {
                    // Settings action
                    NotificationCenter.default.post(name: NSNotification.Name("ShowSettings"), object: nil)
                } label: {
                    Image(systemName: "gear")
                }
                .help("Settings")
            }
        }
    }

    @ViewBuilder
    private func placeholderView(title: String, icon: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title.bold())

            Text("Coming soon in Phase 4")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Previews

#Preview {
    MainContentView()
}
