import Foundation

/// User-configurable application settings
struct AppSettings: Codable, Sendable {
    var rustupPath: String?
    var cargoPath: String?
    var rustupHome: String?
    var cargoHome: String?
    var overrideStrategy: OverrideStrategy
    var authorizedDirectories: [AuthorizedDirectory]
    var showDetailedTaskOutput: Bool
    var autoRefreshOnActivation: Bool
    var environmentVariables: [String: String]

    init(
        rustupPath: String? = nil,
        cargoPath: String? = nil,
        rustupHome: String? = nil,
        cargoHome: String? = nil,
        overrideStrategy: OverrideStrategy = .toolchainFile,
        authorizedDirectories: [AuthorizedDirectory] = [],
        showDetailedTaskOutput: Bool = false,
        autoRefreshOnActivation: Bool = true,
        environmentVariables: [String: String] = [:]
    ) {
        self.rustupPath = rustupPath
        self.cargoPath = cargoPath
        self.rustupHome = rustupHome
        self.cargoHome = cargoHome
        self.overrideStrategy = overrideStrategy
        self.authorizedDirectories = authorizedDirectories
        self.showDetailedTaskOutput = showDetailedTaskOutput
        self.autoRefreshOnActivation = autoRefreshOnActivation
        self.environmentVariables = environmentVariables
    }

    enum OverrideStrategy: String, Codable, Sendable {
        case toolchainFile      // Write rust-toolchain.toml
        case rustupOverride     // Use rustup override set

        var displayText: String {
            switch self {
            case .toolchainFile: return "Write rust-toolchain.toml (recommended)"
            case .rustupOverride: return "Use rustup override"
            }
        }

        var helpText: String {
            switch self {
            case .toolchainFile:
                return "Creates or updates rust-toolchain.toml in the project. Can be committed to version control."
            case .rustupOverride:
                return "Uses rustup's override database. Does not modify project files."
            }
        }
    }

    /// Default settings
    static let `default` = AppSettings(
        rustupPath: nil,
        cargoPath: nil,
        rustupHome: nil,
        cargoHome: nil,
        overrideStrategy: .toolchainFile,
        authorizedDirectories: []
    )
}
