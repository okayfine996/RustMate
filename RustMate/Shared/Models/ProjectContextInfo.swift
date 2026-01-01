import Foundation

/// Represents a project directory and its active toolchain configuration
struct ProjectContextInfo: Codable, Identifiable, Sendable {
    let id: UUID
    let projectPath: String
    let activeToolchain: String
    let reason: ToolchainReason
    let sourcePath: String?
    let lastAccessed: Date

    init(
        id: UUID = UUID(),
        projectPath: String,
        activeToolchain: String,
        reason: ToolchainReason,
        sourcePath: String? = nil,
        lastAccessed: Date = Date()
    ) {
        self.id = id
        self.projectPath = projectPath
        self.activeToolchain = activeToolchain
        self.reason = reason
        self.sourcePath = sourcePath
        self.lastAccessed = lastAccessed
    }

    /// Why a specific toolchain is active for a project
    enum ToolchainReason: String, Codable, Sendable {
        case environment           // RUSTUP_TOOLCHAIN env var
        case toolchainFile         // rust-toolchain.toml or rust-toolchain
        case override              // rustup override set
        case `default`             // Default toolchain
        case unknown               // Could not determine

        var displayText: String {
            switch self {
            case .environment: return "Environment Variable (RUSTUP_TOOLCHAIN)"
            case .toolchainFile: return "Toolchain File (rust-toolchain.toml)"
            case .override: return "Directory Override (rustup override)"
            case .default: return "Default Toolchain"
            case .unknown: return "Unknown"
            }
        }

        var priority: Int {
            switch self {
            case .environment: return 1
            case .toolchainFile: return 2
            case .override: return 3
            case .default: return 4
            case .unknown: return 5
            }
        }
    }
}
