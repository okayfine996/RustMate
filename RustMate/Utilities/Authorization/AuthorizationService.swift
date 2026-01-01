//
//  AuthorizationService.swift
//  RustMate
//
//  Service for validating and resolving authorized resources
//

import Foundation

/// Represents an authorized resource that has been successfully accessed
struct AuthorizedResource {
    let url: URL
    let purpose: AuthorizedDirectory.DirectoryPurpose
    let originalDirectory: AuthorizedDirectory

    /// Must be called when done using the resource
    func stopAccessing() {
        url.stopAccessingSecurityScopedResource()
    }
}

/// Service for managing authorization validation and resource access
class AuthorizationService {
    private let bookmarkManager: BookmarkManager

    init(bookmarkManager: BookmarkManager = BookmarkManager()) {
        self.bookmarkManager = bookmarkManager
    }

    // MARK: - Validation

    /// Validates that all required authorizations exist for a given scope
    /// Returns empty array if all required authorizations exist, otherwise returns missing purposes
    func validate(
        scope: AuthorizationScope,
        settings: AppSettings
    ) -> [AuthorizedDirectory.DirectoryPurpose] {
        let requiredPurposes = scope.requiredPurposes
        let missingPurposes = requiredPurposes.filter { purpose in
            !settings.hasAuthorization(for: purpose)
        }
        return missingPurposes
    }

    // MARK: - Resolution and Access

    /// Validates and resolves all required authorizations for a scope
    /// Returns AuthorizedResource objects with active security-scoped access
    /// Caller MUST call stopAccessing() on all resources when done (use defer)
    func validateAndResolve(
        scope: AuthorizationScope,
        settings: AppSettings
    ) throws -> [AuthorizedResource] {
        let requiredPurposes = scope.requiredPurposes
        var authorizedResources: [AuthorizedResource] = []

        // Validate all required purposes exist
        for purpose in requiredPurposes {
            guard let directory = settings.authorizedDirectory(for: purpose) else {
                // Clean up any resources we've already accessed
                stopAccessing(authorizedResources)
                throw AuthorizationError.missingScope(purpose: purpose)
            }

            // Resolve the bookmark
            let url: URL
            do {
                url = try resolveBookmark(directory)
            } catch let error as BookmarkManager.BookmarkError {
                // Clean up any resources we've already accessed
                stopAccessing(authorizedResources)
                throw mapBookmarkError(error, directory: directory)
            } catch {
                stopAccessing(authorizedResources)
                throw AuthorizationError.accessDenied(
                    path: directory.path,
                    purpose: directory.purpose
                )
            }

            // Start accessing the resource
            guard url.startAccessingSecurityScopedResource() else {
                // Clean up any resources we've already accessed
                stopAccessing(authorizedResources)
                throw AuthorizationError.accessDenied(
                    path: directory.path,
                    purpose: directory.purpose
                )
            }

            authorizedResources.append(AuthorizedResource(
                url: url,
                purpose: purpose,
                originalDirectory: directory
            ))
        }

        return authorizedResources
    }

    /// Resolves a single authorization purpose
    /// Returns AuthorizedResource with active security-scoped access
    /// Caller MUST call stopAccessing() when done (use defer)
    func resolveAuthorization(
        for purpose: AuthorizedDirectory.DirectoryPurpose,
        settings: AppSettings
    ) throws -> AuthorizedResource {
        guard let directory = settings.authorizedDirectory(for: purpose) else {
            throw AuthorizationError.missingScope(purpose: purpose)
        }

        let url: URL
        do {
            url = try resolveBookmark(directory)
        } catch let error as BookmarkManager.BookmarkError {
            throw mapBookmarkError(error, directory: directory)
        } catch {
            throw AuthorizationError.accessDenied(
                path: directory.path,
                purpose: directory.purpose
            )
        }

        guard url.startAccessingSecurityScopedResource() else {
            throw AuthorizationError.accessDenied(
                path: directory.path,
                purpose: directory.purpose
            )
        }

        return AuthorizedResource(
            url: url,
            purpose: purpose,
            originalDirectory: directory
        )
    }

    /// Stops accessing all resources in the array
    func stopAccessing(_ resources: [AuthorizedResource]) {
        for resource in resources {
            resource.stopAccessing()
        }
    }

    // MARK: - Private Helpers

    private func resolveBookmark(_ directory: AuthorizedDirectory) throws -> URL {
        // Check if bookmark is stale first
        if let isStale = try? directory.isBookmarkStale(), isStale {
            throw AuthorizationError.staleBookmark(
                path: directory.path,
                purpose: directory.purpose
            )
        }

        // Resolve the bookmark
        return try bookmarkManager.resolveBookmark(for: directory.path)
    }

    private func mapBookmarkError(
        _ error: BookmarkManager.BookmarkError,
        directory: AuthorizedDirectory
    ) -> AuthorizationError {
        switch error {
        case .resolutionFailed:
            return .staleBookmark(path: directory.path, purpose: directory.purpose)
        case .accessDenied:
            return .accessDenied(path: directory.path, purpose: directory.purpose)
        case .creationFailed, .keychainError:
            return .accessDenied(path: directory.path, purpose: directory.purpose)
        }
    }
}
