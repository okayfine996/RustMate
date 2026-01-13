//
//  MockAuthorizationService.swift
//  RustMateTests
//
//  Mock implementation of AuthorizationService
//

import Foundation

@testable import RustMate

class MockAuthorizationService: AuthorizationService {
    var shouldFail = false

    override func validateAndResolve(
        scope: AuthorizationScope,
        settings: AppSettings
    ) throws -> [AuthorizedResource] {
        if shouldFail {
            throw AuthorizationError.missingScope(purpose: .rustupHome)
        }
        // Return empty list as we don't need real resources for mocking execution
        return []
    }
}
