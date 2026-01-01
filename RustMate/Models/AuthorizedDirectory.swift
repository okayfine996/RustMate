import Foundation

/// Represents a user-authorized directory with Security-Scoped Bookmark
struct AuthorizedDirectory: Codable, Identifiable, Sendable {
    let id: UUID
    let path: String
    let bookmarkData: Data
    let purpose: DirectoryPurpose
    let authorizedDate: Date
    let lastValidated: Date?

    init(
        id: UUID = UUID(),
        path: String,
        bookmarkData: Data,
        purpose: DirectoryPurpose,
        authorizedDate: Date = Date(),
        lastValidated: Date? = nil
    ) {
        self.id = id
        self.path = path
        self.bookmarkData = bookmarkData
        self.purpose = purpose
        self.authorizedDate = authorizedDate
        self.lastValidated = lastValidated
    }

    enum DirectoryPurpose: String, Codable, Sendable {
        case rustupAccess           // Access to ~/.cargo/bin for rustup/cargo
        case projectAccess          // Access to project directory
        case customToolchainPath    // Custom rustup installation path

        var displayText: String {
            switch self {
            case .rustupAccess: return "Rustup Executables"
            case .projectAccess: return "Project Directory"
            case .customToolchainPath: return "Custom Rustup Path"
            }
        }
    }

    /// Display name derived from path
    var displayName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    /// Check if bookmark is stale and needs refresh
    func isBookmarkStale() throws -> Bool {
        var isStale = false
        _ = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return isStale
    }
}
