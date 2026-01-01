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
        // Legacy purpose (kept for backward compatibility)
        case rustupAccess           // Legacy: Access to ~/.cargo/bin for rustup/cargo

        // Refined purposes for sandboxed execution
        case rustupExecutableDir    // Directory containing rustup executable (e.g., ~/.cargo/bin)
        case cargoHome             // .cargo directory
        case rustupHome            // .rustup directory

        // Project-level access
        case projectAccess          // Access to project directory

        // Custom paths
        case customToolchainPath    // Custom rustup installation path

        var displayText: String {
            switch self {
            case .rustupAccess: return "Rustup Executables (Legacy)"
            case .rustupExecutableDir: return "Rustup Executable Directory"
            case .cargoHome: return "Cargo Home (~/.cargo)"
            case .rustupHome: return "Rustup Home (~/.rustup)"
            case .projectAccess: return "Project Directory"
            case .customToolchainPath: return "Custom Rustup Path"
            }
        }

        /// Returns the typical default path for this purpose (if applicable)
        var defaultPath: String? {
            let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
            switch self {
            case .rustupExecutableDir:
                return "\(homeDir)/.cargo/bin"
            case .cargoHome:
                return "\(homeDir)/.cargo"
            case .rustupHome:
                return "\(homeDir)/.rustup"
            case .rustupAccess:
                return "\(homeDir)/.cargo/bin" // Legacy fallback
            case .projectAccess, .customToolchainPath:
                return nil // User-specific, no default
            }
        }
    }

    /// Migration helper: Maps legacy rustupAccess entries to the refined purposes
    /// Returns the refined purpose that best matches this authorization, or nil if already refined
    func migratedPurpose() -> DirectoryPurpose? {
        switch purpose {
        case .rustupAccess:
            // Legacy rustupAccess should be treated as rustupExecutableDir
            return .rustupExecutableDir
        case .rustupExecutableDir, .cargoHome, .rustupHome, .projectAccess, .customToolchainPath:
            return nil // Already refined, no migration needed
        }
    }

    /// Returns true if this is a legacy authorization that should be migrated
    var isLegacy: Bool {
        return migratedPurpose() != nil
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
