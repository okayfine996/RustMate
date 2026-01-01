import Foundation

/// Result of environment validation (rustup detection)
struct ValidationResult: Codable, Sendable {
    let hasRustup: Bool
    let rustupPath: String?
    let version: String?
    let hints: [String]

    init(
        hasRustup: Bool,
        rustupPath: String? = nil,
        version: String? = nil,
        hints: [String] = []
    ) {
        self.hasRustup = hasRustup
        self.rustupPath = rustupPath
        self.version = version
        self.hints = hints
    }
}
