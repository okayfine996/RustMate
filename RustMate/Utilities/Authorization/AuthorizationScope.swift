//
//  AuthorizationScope.swift
//  RustMate
//
//  Defines which authorization purposes are required for each operation family
//

import Foundation

/// Defines authorization requirements for different operation families
enum AuthorizationScope {
    case toolchainOperations    // list/install/uninstall/update toolchains
    case componentOperations    // list/add/remove components
    case targetOperations       // list/add/remove targets
    case projectContext         // detect/set/clear project overrides
    case environmentValidation  // validate rustup installation

    /// Returns the directory purposes required for this operation family
    var requiredPurposes: [AuthorizedDirectory.DirectoryPurpose] {
        switch self {
        case .toolchainOperations, .componentOperations, .targetOperations, .environmentValidation:
            // All rustup operations require access to:
            // - rustup executable directory
            // - cargo home (for toolchain storage)
            // - rustup home (for toolchain metadata)
            return [.rustupExecutableDir, .cargoHome, .rustupHome]

        case .projectContext:
            // Project context requires rustup access
            // Note: Project directory access is handled separately via ProjectBookmark
            // in ProjectsViewModel, so we don't need to check .projectAccess here
            return [.rustupExecutableDir, .cargoHome, .rustupHome]
        }
    }

    /// Returns a user-facing description of what this scope is used for
    var displayDescription: String {
        switch self {
        case .toolchainOperations:
            return "Managing Rust toolchains (install, uninstall, update)"
        case .componentOperations:
            return "Managing Rust components (clippy, rustfmt, etc.)"
        case .targetOperations:
            return "Managing compilation targets (wasm32, aarch64, etc.)"
        case .projectContext:
            return "Managing project-specific toolchain overrides"
        case .environmentValidation:
            return "Validating Rust environment setup"
        }
    }

    /// Returns a user-facing list of required directories for this scope
    var requiredDirectoriesDescription: String {
        let descriptions = requiredPurposes.map { $0.displayText }
        return descriptions.joined(separator: ", ")
    }
}
