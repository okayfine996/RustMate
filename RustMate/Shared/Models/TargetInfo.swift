import Foundation

/// Represents a compilation target platform (wasm32, aarch64-linux-gnu, etc.)
struct TargetInfo: Codable, Identifiable, Sendable, Hashable, ToolchainContextItem {
    let id: UUID
    let triple: String
    let arch: String?
    let vendor: String?
    let os: String?
    let env: String?
    let toolchainName: String?
    let isInstalled: Bool
    let description: String?

    init(
        id: UUID = UUID(),
        triple: String,
        arch: String? = nil,
        vendor: String? = nil,
        os: String? = nil,
        env: String? = nil,
        toolchainName: String? = nil,
        isInstalled: Bool,
        description: String? = nil
    ) {
        self.id = id
        self.triple = triple
        self.arch = arch
        self.vendor = vendor
        self.os = os
        self.env = env
        self.toolchainName = toolchainName
        self.isInstalled = isInstalled
        self.description = description
    }

    /// Common targets for UI suggestions
    static let commonTargets = [
        "wasm32-unknown-unknown",
        "aarch64-apple-darwin",
        "x86_64-apple-darwin",
        "aarch64-unknown-linux-gnu",
        "x86_64-unknown-linux-gnu",
        "x86_64-pc-windows-msvc"
    ]

    /// Validates target triple against allowed pattern
    static func validateTriple(_ triple: String) -> Bool {
        let pattern = "^[A-Za-z0-9._-]{1,128}$"
        return triple.range(of: pattern, options: .regularExpression) != nil
    }
}
