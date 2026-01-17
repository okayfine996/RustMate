import Foundation

/// Represents a rustup component (clippy, rustfmt, rust-src, etc.) for a specific toolchain
struct ComponentInfo: Codable, Identifiable, Sendable, Hashable, ToolchainContextItem {
    let id: UUID
    let name: String
    let displayName: String
    let toolchainName: String?
    let isInstalled: Bool
    let componentType: ComponentType
    let description: String?

    init(
        id: UUID = UUID(),
        name: String,
        displayName: String? = nil,
        toolchainName: String? = nil,
        isInstalled: Bool,
        componentType: ComponentType = .other,
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName ?? name
        self.toolchainName = toolchainName
        self.isInstalled = isInstalled
        self.componentType = componentType
        self.description = description
    }

    /// Common components for UI suggestions
    static let commonComponents = ["rustfmt", "clippy", "rust-src", "llvm-tools-preview"]

    /// Component type classification
    enum ComponentType: String, Codable, Sendable, Hashable {
        case rustfmt = "rustfmt"
        case clippy = "clippy"
        case rustSrc = "rust-src"
        case llvmTools = "llvm-tools"
        case rustDocs = "rust-docs"
        case rustAnalyzer = "rust-analyzer"
        case other = "other"

        var icon: String {
            switch self {
            case .rustfmt: return "paintbrush"
            case .clippy: return "checkmark.seal"
            case .rustSrc: return "doc.text"
            case .llvmTools: return "wrench.and.screwdriver"
            case .rustDocs: return "book"
            case .rustAnalyzer: return "brain"
            case .other: return "puzzlepiece"
            }
        }
    }
}
