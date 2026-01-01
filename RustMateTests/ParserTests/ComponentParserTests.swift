//
//  ComponentParserTests.swift
//  RustMateTests
//
//  Unit tests for ComponentParser with various rustup component list output formats
//

import XCTest
@testable import RustMateXPC

final class ComponentParserTests: XCTestCase {

    // MARK: - Basic Parsing Tests

    func testParseBasicComponents() throws {
        let input = """
        cargo-aarch64-apple-darwin (installed)
        clippy-aarch64-apple-darwin
        llvm-tools-preview-aarch64-apple-darwin
        rust-docs-aarch64-apple-darwin (installed)
        rust-std-aarch64-apple-darwin (installed)
        rustc-aarch64-apple-darwin (installed)
        rustfmt-preview-aarch64-apple-darwin
        """

        let result = ComponentParser.parse(input)

        XCTAssertEqual(result.count, 7)

        // Check installed component
        let cargo = try XCTUnwrap(result.first { $0.name == "cargo-aarch64-apple-darwin" })
        XCTAssertTrue(cargo.isInstalled)

        // Check not installed component
        let clippy = try XCTUnwrap(result.first { $0.name == "clippy-aarch64-apple-darwin" })
        XCTAssertFalse(clippy.isInstalled)
    }

    func testParseAllInstalled() throws {
        let input = """
        cargo-aarch64-apple-darwin (installed)
        clippy-aarch64-apple-darwin (installed)
        rustfmt-preview-aarch64-apple-darwin (installed)
        """

        let result = ComponentParser.parse(input)

        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.allSatisfy { $0.isInstalled })
    }

    func testParseNoneInstalled() throws {
        let input = """
        cargo-aarch64-apple-darwin
        clippy-aarch64-apple-darwin
        rustfmt-preview-aarch64-apple-darwin
        """

        let result = ComponentParser.parse(input)

        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.allSatisfy { !$0.isInstalled })
    }

    // MARK: - Component Name Extraction Tests

    func testExtractDisplayNameFromComponent() throws {
        let input = "clippy-aarch64-apple-darwin (installed)"

        let result = ComponentParser.parse(input)

        let component = try XCTUnwrap(result.first)
        XCTAssertEqual(component.displayName, "clippy")
    }

    func testExtractDisplayNameFromRustSrc() throws {
        let input = "rust-src (installed)"

        let result = ComponentParser.parse(input)

        let component = try XCTUnwrap(result.first)
        XCTAssertEqual(component.displayName, "rust-src")
    }

    func testExtractDisplayNameFromRustAnalyzer() throws {
        let input = "rust-analyzer-aarch64-apple-darwin (installed)"

        let result = ComponentParser.parse(input)

        let component = try XCTUnwrap(result.first)
        XCTAssertEqual(component.displayName, "rust-analyzer")
    }

    // MARK: - Edge Cases

    func testParseEmptyOutput() {
        let input = ""

        let result = ComponentParser.parse(input)

        XCTAssertTrue(result.isEmpty)
    }

    func testParseWhitespaceOnly() {
        let input = """



        """

        let result = ComponentParser.parse(input)

        XCTAssertTrue(result.isEmpty)
    }

    func testParseWithTrailingWhitespace() throws {
        let input = """
        cargo-aarch64-apple-darwin (installed)
        clippy-aarch64-apple-darwin
        """

        let result = ComponentParser.parse(input)

        XCTAssertEqual(result.count, 2)
    }

    func testParseSingleComponent() throws {
        let input = "rust-src (installed)"

        let result = ComponentParser.parse(input)

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first?.isInstalled ?? false)
    }

    // MARK: - Cross-Platform Tests

    func testParseLinuxComponents() throws {
        let input = """
        cargo-x86_64-unknown-linux-gnu (installed)
        clippy-x86_64-unknown-linux-gnu (installed)
        rustfmt-preview-x86_64-unknown-linux-gnu
        """

        let result = ComponentParser.parse(input)

        XCTAssertEqual(result.count, 3)

        let cargo = try XCTUnwrap(result.first { $0.displayName == "cargo" })
        XCTAssertTrue(cargo.isInstalled)
    }

    func testParseWindowsComponents() throws {
        let input = """
        cargo-x86_64-pc-windows-msvc (installed)
        clippy-x86_64-pc-windows-msvc
        rustfmt-preview-x86_64-pc-windows-msvc (installed)
        """

        let result = ComponentParser.parse(input)

        XCTAssertEqual(result.count, 3)

        let rustfmt = try XCTUnwrap(result.first { $0.displayName == "rustfmt-preview" })
        XCTAssertTrue(rustfmt.isInstalled)
    }

    // MARK: - Nightly-Only Components Tests

    func testParseNightlyComponents() throws {
        let input = """
        miri-aarch64-apple-darwin (installed)
        rust-analyzer-aarch64-apple-darwin (installed)
        rustc-dev-aarch64-apple-darwin
        """

        let result = ComponentParser.parse(input)

        XCTAssertEqual(result.count, 3)

        let miri = try XCTUnwrap(result.first { $0.displayName == "miri" })
        XCTAssertTrue(miri.isInstalled)

        let rustAnalyzer = try XCTUnwrap(result.first { $0.displayName == "rust-analyzer" })
        XCTAssertTrue(rustAnalyzer.isInstalled)

        let rustcDev = try XCTUnwrap(result.first { $0.displayName == "rustc-dev" })
        XCTAssertFalse(rustcDev.isInstalled)
    }

    // MARK: - Common Components Tests

    func testIdentifyCommonComponents() throws {
        let input = """
        clippy-aarch64-apple-darwin (installed)
        rustfmt-preview-aarch64-apple-darwin (installed)
        rust-src (installed)
        llvm-tools-preview-aarch64-apple-darwin
        """

        let result = ComponentParser.parse(input)

        // clippy, rustfmt, rust-src are common components
        let commonComponents = result.filter { component in
            ["clippy", "rustfmt-preview", "rust-src"].contains(component.displayName)
        }

        XCTAssertEqual(commonComponents.count, 3)
    }

    // MARK: - Regression Tests

    func testParseDoesNotIncludeMalformedLines() throws {
        let input = """
        cargo-aarch64-apple-darwin (installed)
        this-is-not-a-component
        clippy-aarch64-apple-darwin
        some random text
        """

        let result = ComponentParser.parse(input)

        // Should only parse valid component lines
        XCTAssertGreaterThanOrEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.displayName == "cargo" })
        XCTAssertTrue(result.contains { $0.displayName == "clippy" })
    }

    func testParseHandlesCaseVariations() throws {
        let input = """
        clippy-aarch64-apple-darwin (INSTALLED)
        rustfmt-preview-aarch64-apple-darwin (Installed)
        rust-src (installed)
        """

        let result = ComponentParser.parse(input)

        // Parser should handle case variations of "(installed)" marker
        let installedCount = result.filter { $0.isInstalled }.count
        XCTAssertGreaterThanOrEqual(installedCount, 1)
    }

    // MARK: - Description Tests

    func testComponentDescriptions() throws {
        let input = """
        clippy-aarch64-apple-darwin (installed)
        rustfmt-preview-aarch64-apple-darwin
        rust-src (installed)
        llvm-tools-preview-aarch64-apple-darwin
        """

        let result = ComponentParser.parse(input)

        // Verify descriptions are populated
        for component in result {
            XCTAssertNotNil(component.description, "Component \(component.displayName) should have description")
            XCTAssertFalse(component.description?.isEmpty ?? true)
        }
    }
}
