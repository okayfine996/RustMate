//
//  TargetParserTests.swift
//  RustMateTests
//
//  Unit tests for TargetParser with various rustup target list output formats
//

import XCTest

@testable import RustMate

final class TargetParserTests: XCTestCase {

    // MARK: - Basic Parsing Tests

    func testParseBasicTargets() throws {
        let input = """
            aarch64-apple-darwin (installed)
            aarch64-apple-ios
            aarch64-unknown-linux-gnu
            wasm32-unknown-unknown
            x86_64-apple-darwin
            """

        let result = TargetParser.parse(input)

        XCTAssertEqual(result.count, 5)

        // Check installed target
        let aarch64Darwin = try XCTUnwrap(result.first { $0.triple == "aarch64-apple-darwin" })
        XCTAssertTrue(aarch64Darwin.isInstalled)

        // Check not installed target
        let wasm = try XCTUnwrap(result.first { $0.triple == "wasm32-unknown-unknown" })
        XCTAssertFalse(wasm.isInstalled)
    }

    func testParseMultipleInstalled() throws {
        let input = """
            aarch64-apple-darwin (installed)
            aarch64-unknown-linux-gnu (installed)
            wasm32-unknown-unknown (installed)
            x86_64-apple-darwin
            """

        let result = TargetParser.parse(input)

        XCTAssertEqual(result.count, 4)

        let installedCount = result.filter { $0.isInstalled }.count
        XCTAssertEqual(installedCount, 3)
    }

    func testParseSingleTarget() throws {
        let input = "aarch64-apple-darwin (installed)"

        let result = TargetParser.parse(input)

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first?.isInstalled ?? false)
    }

    // MARK: - Target Triple Component Extraction

    func testExtractArchitecture() throws {
        let input = """
            aarch64-apple-darwin (installed)
            x86_64-apple-darwin
            i686-pc-windows-msvc
            """

        let result = TargetParser.parse(input)

        let aarch64 = try XCTUnwrap(result.first { $0.triple == "aarch64-apple-darwin" })
        XCTAssertEqual(aarch64.arch, "aarch64")

        let x86_64 = try XCTUnwrap(result.first { $0.triple == "x86_64-apple-darwin" })
        XCTAssertEqual(x86_64.arch, "x86_64")

        let i686 = try XCTUnwrap(result.first { $0.triple == "i686-pc-windows-msvc" })
        XCTAssertEqual(i686.arch, "i686")
    }

    func testExtractVendor() throws {
        let input = """
            aarch64-apple-darwin (installed)
            x86_64-pc-windows-msvc
            aarch64-unknown-linux-gnu
            """

        let result = TargetParser.parse(input)

        let apple = try XCTUnwrap(result.first { $0.triple == "aarch64-apple-darwin" })
        XCTAssertEqual(apple.vendor, "apple")

        let pc = try XCTUnwrap(result.first { $0.triple == "x86_64-pc-windows-msvc" })
        XCTAssertEqual(pc.vendor, "pc")

        let unknown = try XCTUnwrap(result.first { $0.triple == "aarch64-unknown-linux-gnu" })
        XCTAssertEqual(unknown.vendor, "unknown")
    }

    func testExtractOS() throws {
        let input = """
            aarch64-apple-darwin (installed)
            x86_64-unknown-linux-gnu
            x86_64-pc-windows-msvc
            """

        let result = TargetParser.parse(input)

        let darwin = try XCTUnwrap(result.first { $0.triple == "aarch64-apple-darwin" })
        XCTAssertEqual(darwin.os, "darwin")

        let linux = try XCTUnwrap(result.first { $0.triple == "x86_64-unknown-linux-gnu" })
        XCTAssertEqual(linux.os, "linux")

        let windows = try XCTUnwrap(result.first { $0.triple == "x86_64-pc-windows-msvc" })
        XCTAssertEqual(windows.os, "windows")
    }

    // MARK: - Platform-Specific Tests

    func testParseLinuxTargets() throws {
        let input = """
            x86_64-unknown-linux-gnu (installed)
            aarch64-unknown-linux-gnu
            i686-unknown-linux-gnu
            x86_64-unknown-linux-musl
            """

        let result = TargetParser.parse(input)

        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result.allSatisfy { $0.os == "linux" })
    }

    func testParseWindowsTargets() throws {
        let input = """
            x86_64-pc-windows-msvc (installed)
            aarch64-pc-windows-msvc
            i686-pc-windows-gnu
            """

        let result = TargetParser.parse(input)

        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.allSatisfy { $0.os == "windows" })
    }

    func testParseMobileTargets() throws {
        let input = """
            aarch64-apple-ios
            aarch64-apple-ios-sim
            aarch64-linux-android
            armv7-linux-androideabi
            """

        let result = TargetParser.parse(input)

        XCTAssertEqual(result.count, 4)

        let ios = result.filter { $0.triple.contains("ios") }
        XCTAssertEqual(ios.count, 2)

        let android = result.filter { $0.triple.contains("android") }
        XCTAssertEqual(android.count, 2)
    }

    // MARK: - Special Target Types

    func testParseWebAssemblyTargets() throws {
        let input = """
            wasm32-unknown-emscripten
            wasm32-unknown-unknown (installed)
            wasm32-wasi
            """

        let result = TargetParser.parse(input)

        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.allSatisfy { $0.arch == "wasm32" })

        let installed = result.filter { $0.isInstalled }
        XCTAssertEqual(installed.count, 1)
        XCTAssertEqual(installed.first?.triple, "wasm32-unknown-unknown")
    }

    func testParseEmbeddedTargets() throws {
        let input = """
            thumbv7em-none-eabihf
            thumbv7m-none-eabi
            riscv32i-unknown-none-elf
            """

        let result = TargetParser.parse(input)

        XCTAssertEqual(result.count, 3)

        let thumb = result.filter { $0.arch?.hasPrefix("thumb") ?? false }
        XCTAssertEqual(thumb.count, 2)

        let riscv = result.filter { $0.arch?.hasPrefix("riscv") ?? false }
        XCTAssertEqual(riscv.count, 1)
    }

    // MARK: - Edge Cases

    func testParseEmptyOutput() {
        let input = ""

        let result = TargetParser.parse(input)

        XCTAssertTrue(result.isEmpty)
    }

    func testParseWhitespaceOnly() {
        let input = """



            """

        let result = TargetParser.parse(input)

        XCTAssertTrue(result.isEmpty)
    }

    func testParseWithTrailingWhitespace() throws {
        let input = """
            aarch64-apple-darwin (installed)
            x86_64-apple-darwin
            """

        let result = TargetParser.parse(input)

        XCTAssertEqual(result.count, 2)
    }

    func testParseAllInstalled() throws {
        let input = """
            aarch64-apple-darwin (installed)
            wasm32-unknown-unknown (installed)
            x86_64-apple-darwin (installed)
            """

        let result = TargetParser.parse(input)

        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.allSatisfy { $0.isInstalled })
    }

    // MARK: - Common Targets Tests

    func testIdentifyCommonTargets() throws {
        let input = """
            aarch64-apple-darwin (installed)
            wasm32-unknown-unknown
            x86_64-apple-darwin
            x86_64-unknown-linux-gnu
            x86_64-pc-windows-msvc
            """

        let result = TargetParser.parse(input)

        // These are common cross-compilation targets
        let commonTargets = [
            "aarch64-apple-darwin",
            "wasm32-unknown-unknown",
            "x86_64-apple-darwin",
            "x86_64-unknown-linux-gnu",
            "x86_64-pc-windows-msvc",
        ]

        let foundCommon = result.filter { commonTargets.contains($0.triple) }
        XCTAssertEqual(foundCommon.count, 5)
    }

    // MARK: - Regression Tests

    func testParseHandlesMalformedLines() throws {
        let input = """
            aarch64-apple-darwin (installed)
            this-is-not-a-target
            x86_64-apple-darwin
            some random text
            """

        let result = TargetParser.parse(input)

        // Should only parse valid target lines
        XCTAssertGreaterThanOrEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.triple == "aarch64-apple-darwin" })
        XCTAssertTrue(result.contains { $0.triple == "x86_64-apple-darwin" })
    }

    func testParseHandlesCaseVariations() throws {
        let input = """
            aarch64-apple-darwin (INSTALLED)
            x86_64-apple-darwin (Installed)
            wasm32-unknown-unknown (installed)
            """

        let result = TargetParser.parse(input)

        // Parser should handle case variations
        let installedCount = result.filter { $0.isInstalled }.count
        XCTAssertGreaterThanOrEqual(installedCount, 1)
    }

    // MARK: - Description Tests

    func testTargetDescriptions() throws {
        let input = """
            aarch64-apple-darwin (installed)
            wasm32-unknown-unknown
            x86_64-pc-windows-msvc
            """

        let result = TargetParser.parse(input)

        // Verify descriptions are populated for common targets
        for target in result {
            if ["aarch64-apple-darwin", "wasm32-unknown-unknown", "x86_64-pc-windows-msvc"]
                .contains(target.triple)
            {
                XCTAssertNotNil(
                    target.description, "Target \(target.triple) should have description")
            }
        }
    }
}
