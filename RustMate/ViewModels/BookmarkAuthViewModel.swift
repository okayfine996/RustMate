//
//  BookmarkAuthViewModel.swift
//  RustMate
//
//  ViewModel for BookmarkAuthView
//

import Foundation
import AppKit
import Combine

@MainActor
class BookmarkAuthViewModel: ObservableObject {
    @Published var hasCargoAccess = false
    @Published var authorizedProjects: [AuthorizedDirectory] = []

    private let bookmarkService: any BookmarkServiceProtocol

    var hasRequiredPermissions: Bool {
        hasCargoAccess
    }

    init(bookmarkService: any BookmarkServiceProtocol = BookmarkManager()) {
        self.bookmarkService = bookmarkService
        checkExistingBookmarks()
    }

    // MARK: - Check Existing

    private func checkExistingBookmarks() {
        let cargoPath = NSString(string: "~/.cargo/bin").expandingTildeInPath
        hasCargoAccess = bookmarkService.hasBookmark(for: cargoPath)
    }

    // MARK: - Cargo Access

    func authorizeCargoAccess() {
        let panel = NSOpenPanel()
        panel.message = "Select your .cargo/bin directory"
        panel.prompt = "Authorize"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.directoryURL = URL(fileURLWithPath: NSString(string: "~/.cargo/bin").expandingTildeInPath)

        panel.begin { [weak self] response in
            guard let self = self else { return }

            if response == .OK, let url = panel.url {
                do {
                    _ = try self.bookmarkService.createBookmark(for: url)
                    self.hasCargoAccess = true
                } catch {
                    print("Failed to create cargo bookmark: \(error)")
                }
            }
        }
    }

    // MARK: - Project Access

    func authorizeProjectDirectory() {
        let panel = NSOpenPanel()
        panel.message = "Select a Rust project directory"
        panel.prompt = "Authorize"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        panel.begin { [weak self] response in
            guard let self = self else { return }

            if response == .OK, let url = panel.url {
                do {
                    let bookmarkData = try self.bookmarkService.createBookmark(for: url)
                    let directory = AuthorizedDirectory(
                        id: UUID(),
                        path: url.path,
                        bookmarkData: bookmarkData,
                        purpose: .projectAccess,
                        authorizedDate: Date()
                    )
                    self.authorizedProjects.append(directory)
                } catch {
                    print("Failed to create project bookmark: \(error)")
                }
            }
        }
    }

    func removeProject(path: String) {
        authorizedProjects.removeAll { $0.path == path }

        do {
            try bookmarkService.deleteBookmark(for: path)
        } catch {
            print("Failed to delete bookmark: \(error)")
        }
    }
}
