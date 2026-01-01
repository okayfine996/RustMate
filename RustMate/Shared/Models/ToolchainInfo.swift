import Foundation

/// Represents an installed Rust toolchain (stable, beta, nightly, or custom)
struct ToolchainInfo: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let name: String
    let version: String?
    let isDefault: Bool
    let installDate: Date?
    let host: String?

    init(
        id: UUID = UUID(),
        name: String,
        version: String? = nil,
        isDefault: Bool = false,
        installDate: Date? = nil,
        host: String? = nil
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.isDefault = isDefault
        self.installDate = installDate
        self.host = host
    }

    /// Validates toolchain name against allowed pattern
    static func validateName(_ name: String) -> Bool {
        let pattern = "^[A-Za-z0-9._-]{1,128}$"
        return name.range(of: pattern, options: .regularExpression) != nil
    }
}
