//
//  ToolchainParserTests.swift
//  RustMateTests
//
//  Unit tests for ToolchainParser with various rustup output formats
//

import XCTest
@testable import RustMateXPC

final class ToolchainParserTests: XCTestCase {

    // MARK: - Basic Parsing Tests

    func testParseBasicOutput() throws {
        let input = """
        stable-aarch64-apple-darwin (default)
        nightly-aarch64-apple-darwin
        """

        let result = ToolchainParser.parse(input)

        XCTAssertEqual(result.count, 2)

        // Check first toolchain (default)
        let stable = try XCTUnwrap(result.first { $0.name == "stable-aarch64-apple-darwin" })
        XCTAssertTrue(stable.isDefault)
        XCTAssertEqual(stable.host, "aarch64-apple-darwin")

        // Check second toolchain (not default)
        let nightly = try XCTUnwrap(result.first { $0.name == "nightly-aarch64-apple-darwin" })
        XCTAssertFalse(nightly.isDefault)
        XCTAssertEqual(nightly.host, "aarch64-apple-darwin")
    }

    func testParseMultipleToolchains() throws {
        let input = """
        stable-aarch64-apple-darwin
        beta-aarch64-apple-darwin
        nightly-aarch64-apple-darwin (default)
        1.75.0-aarch64-apple-darwin
        """

        let result = ToolchainParser.parse(input)

        XCTAssertEqual(result.count, 4)

        // Only nightly should be default
        let defaultToolchains = result.filter { $0.isDefault }
        XCTAssertEqual(defaultToolchains.count, 1)
        XCTAssertEqual(defaultToolchains.first?.name, "nightly-aarch64-apple-darwin")
    }

    func testParseSingleToolchain() throws {
        let input = "stable-aarch64-apple-darwin (default)"

        let result = ToolchainParser.parse(input)

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first?.isDefault ?? false)
    }

    // MARK: - Edge Cases

    func testParseNoDefaultMarker() throws {
        let input = """
        stable-aarch64-apple-darwin
        nightly-aarch64-apple-darwin
        """

        let result = ToolchainParser.parse(input)

        XCTAssertEqual(result.count, 2)

        // No toolchain should be marked as default
        let defaultToolchains = result.filter { $0.isDefault }
        XCTAssertEqual(defaultToolchains.count, 0)
    }

    func testParseEmptyOutput() {
        let input = ""

        let result = ToolchainParser.parse(input)

        XCTAssertTrue(result.isEmpty)
    }

    func testParseWhitespaceOnly() {
        let input = """



        """

        let result = ToolchainParser.parse(input)

        XCTAssertTrue(result.isEmpty)
    }

    func testParseWithTrailingWhitespace() throws {
        let input = """
        stable-aarch64-apple-darwin (default)
        nightly-aarch64-apple-darwin
        """

        let result = ToolchainParser.parse(input)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.name, "stable-aarch64-apple-darwin")
    }

    // MARK: - Custom and Versioned Toolchains

    func testParseCustomToolchain() throws {
        let input = """
        stable-aarch64-apple-darwin (default)
        nightly-2024-01-15-aarch64-apple-darwin
        my-custom-toolchain
        """

        let result = ToolchainParser.parse(input)

        XCTAssertEqual(result.count, 3)

        let custom = try XCTUnwrap(result.first { $0.name == "my-custom-toolchain" })
        XCTAssertFalse(custom.isDefault)
    }

    func testParseVersionedToolchains() throws {
        let input = """
        1.74.0-aarch64-apple-darwin (default)
        1.75.0-aarch64-apple-darwin
        1.76.0-beta.4-aarch64-apple-darwin
        """

        let result = ToolchainParser.parse(input)

        XCTAssertEqual(result.count, 3)

        let v174 = try XCTUnwrap(result.first { $0.name == "1.74.0-aarch64-apple-darwin" })
        XCTAssertTrue(v174.isDefault)
        XCTAssertEqual(v174.version, "1.74.0")
    }

    // MARK: - Cross-Platform Tests

    func testParseLinuxHost() throws {
        let input = """
        stable-x86_64-unknown-linux-gnu (default)
        beta-x86_64-unknown-linux-gnu
        nightly-x86_64-unknown-linux-gnu
        """

        let result = ToolchainParser.parse(input)

        XCTAssertEqual(result.count, 3)

        let stable = try XCTUnwrap(result.first { $0.isDefault })
        XCTAssertEqual(stable.host, "x86_64-unknown-linux-gnu")
    }

    func testParseWindowsHost() throws {
        let input = """
        stable-x86_64-pc-windows-msvc (default)
        nightly-x86_64-pc-windows-msvc
        """

        let result = ToolchainParser.parse(input)

        XCTAssertEqual(result.count, 2)

        let stable = try XCTUnwrap(result.first { $0.isDefault })
        XCTAssertEqual(stable.host, "x86_64-pc-windows-msvc")
    }

    func testParseMixedArchitectures() throws {
        let input = """
        stable-aarch64-apple-darwin (default)
        stable-x86_64-apple-darwin
        stable-aarch64-unknown-linux-gnu
        """

        let result = ToolchainParser.parse(input)

        XCTAssertEqual(result.count, 3)

        // Verify different architectures parsed correctly
        let hosts = Set(result.map { $0.host })
        XCTAssertTrue(hosts.contains("aarch64-apple-darwin"))
        XCTAssertTrue(hosts.contains("x86_64-apple-darwin"))
        XCTAssertTrue(hosts.contains("aarch64-unknown-linux-gnu"))
    }

    // MARK: - Regression Tests

    func testParseDoesNotFailOnUnexpectedFormat() {
        let input = """
        some-random-text
        not-a-toolchain-format
        stable-aarch64-apple-darwin (default)
        """

        // Should not crash, should extract valid toolchain
        let result = ToolchainParser.parse(input)

        // Should at least get the valid toolchain
        XCTAssertGreaterThanOrEqual(result.count, 1)
        XCTAssertTrue(result.contains { $0.name == "stable-aarch64-apple-darwin" })
    }

    func testParseHandlesMalformedDefaultMarker() throws {
        let input = """
        stable-aarch64-apple-darwin (default
        nightly-aarch64-apple-darwin (DEFAULT)
        beta-aarch64-apple-darwin (Default)
        """

        let result = ToolchainParser.parse(input)

        // Parser should be case-insensitive or handle variations
        XCTAssertGreaterThanOrEqual(result.count, 1)
    }
}
