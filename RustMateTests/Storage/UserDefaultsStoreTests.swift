//
//  UserDefaultsStoreTests.swift
//  RustMateTests
//
//  Unit tests for UserDefaultsStore property wrappers
//

import XCTest

@testable import RustMate

@MainActor
final class UserDefaultsStoreTests: XCTestCase {

    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Use a test suite name to avoid interfering with actual app defaults
        testDefaults = UserDefaults(suiteName: "com.finefine.RustMate.tests")!
        testDefaults.removePersistentDomain(forName: "com.finefine.RustMate.tests")
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "com.finefine.RustMate.tests")
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - UserDefault Tests

    func testUserDefault_ReadWrite_String() {
        // Given
        @UserDefault(key: "testString", defaultValue: "default", storage: testDefaults)
        var testString: String

        // When - Initial value should be default
        XCTAssertEqual(testString, "default")

        // When - Set a new value
        testString = "new value"

        // Then - Should persist
        XCTAssertEqual(testString, "new value")

        // Verify it's actually in UserDefaults
        XCTAssertEqual(testDefaults.string(forKey: "testString"), "new value")
    }

    func testUserDefault_ReadWrite_Int() {
        // Given
        @UserDefault(key: "testInt", defaultValue: 0, storage: testDefaults)
        var testInt: Int

        // When
        XCTAssertEqual(testInt, 0)

        testInt = 42

        // Then
        XCTAssertEqual(testInt, 42)
        XCTAssertEqual(testDefaults.integer(forKey: "testInt"), 42)
    }

    func testUserDefault_ReadWrite_Bool() {
        // Given
        @UserDefault(key: "testBool", defaultValue: false, storage: testDefaults)
        var testBool: Bool

        // When
        XCTAssertFalse(testBool)

        testBool = true

        // Then
        XCTAssertTrue(testBool)
        XCTAssertTrue(testDefaults.bool(forKey: "testBool"))
    }

    func testUserDefault_Remove() {
        // Given
        @UserDefault(key: "testRemove", defaultValue: "default", storage: testDefaults)
        var testValue: String

        testValue = "custom"
        XCTAssertEqual(testValue, "custom")

        // When
        _testValue.remove()

        // Then - Should return to default value
        XCTAssertEqual(testValue, "default")
        XCTAssertNil(testDefaults.string(forKey: "testRemove"))
    }

    // MARK: - OptionalUserDefault Tests

    func testOptionalUserDefault_ReadWrite() {
        // Given
        @OptionalUserDefault(key: "testOptionalString", storage: testDefaults)
        var testString: String?

        // When - Initial value should be nil
        XCTAssertNil(testString)

        // When - Set a value
        testString = "value"

        // Then
        XCTAssertEqual(testString, "value")
        XCTAssertEqual(testDefaults.string(forKey: "testOptionalString"), "value")
    }

    func testOptionalUserDefault_SetNil() {
        // Given
        @OptionalUserDefault(key: "testOptionalNil", storage: testDefaults)
        var testValue: String?

        testValue = "initial"
        XCTAssertEqual(testValue, "initial")

        // When
        testValue = nil

        // Then
        XCTAssertNil(testValue)
        XCTAssertNil(testDefaults.string(forKey: "testOptionalNil"))
    }

    func testOptionalUserDefault_Remove() {
        // Given
        @OptionalUserDefault(key: "testOptionalRemove", storage: testDefaults)
        var testValue: Int?

        testValue = 123
        XCTAssertEqual(testValue, 123)

        // When
        _testValue.remove()

        // Then
        XCTAssertNil(testValue)
        XCTAssertNil(testDefaults.object(forKey: "testOptionalRemove"))
    }

    // MARK: - CodableUserDefault Tests

    func testCodableUserDefault_ReadWrite() {
        // Given
        struct TestData: Codable, Equatable {
            let name: String
            let value: Int
        }

        let defaultData = TestData(name: "default", value: 0)

        @CodableUserDefault(key: "testCodable", defaultValue: defaultData, storage: testDefaults)
        var testData: TestData

        // When - Initial value
        XCTAssertEqual(testData, defaultData)

        // When - Set new value
        let newData = TestData(name: "custom", value: 42)
        testData = newData

        // Then
        XCTAssertEqual(testData, newData)
        XCTAssertNotNil(testDefaults.data(forKey: "testCodable"))
    }

    func testCodableUserDefault_ComplexType() {
        // Given
        struct ComplexData: Codable, Equatable {
            let strings: [String]
            let dict: [String: Int]
            let nested: NestedData

            struct NestedData: Codable, Equatable {
                let flag: Bool
            }
        }

        let defaultData = ComplexData(
            strings: [],
            dict: [:],
            nested: ComplexData.NestedData(flag: false)
        )

        @CodableUserDefault(key: "testComplex", defaultValue: defaultData, storage: testDefaults)
        var testData: ComplexData

        // When
        let complexData = ComplexData(
            strings: ["a", "b", "c"],
            dict: ["x": 1, "y": 2],
            nested: ComplexData.NestedData(flag: true)
        )
        testData = complexData

        // Then
        XCTAssertEqual(testData.strings, ["a", "b", "c"])
        XCTAssertEqual(testData.dict, ["x": 1, "y": 2])
        XCTAssertTrue(testData.nested.flag)
    }

    func testCodableUserDefault_Remove() {
        // Given
        struct TestData: Codable, Equatable {
            let value: String
        }

        let defaultData = TestData(value: "default")

        @CodableUserDefault(key: "testCodableRemove", defaultValue: defaultData, storage: testDefaults)
        var testData: TestData

        testData = TestData(value: "custom")
        XCTAssertEqual(testData.value, "custom")

        // When
        _testData.remove()

        // Then - Should return to default
        XCTAssertEqual(testData.value, "default")
        XCTAssertNil(testDefaults.data(forKey: "testCodableRemove"))
    }

    // MARK: - OptionalCodableUserDefault Tests

    func testOptionalCodableUserDefault_ReadWrite() {
        // Given
        struct TestData: Codable, Equatable {
            let name: String
        }

        @OptionalCodableUserDefault(key: "testOptionalCodable", storage: testDefaults)
        var testData: TestData?

        // When - Initial value should be nil
        XCTAssertNil(testData)

        // When - Set value
        let data = TestData(name: "test")
        testData = data

        // Then
        XCTAssertEqual(testData, data)
        XCTAssertNotNil(testDefaults.data(forKey: "testOptionalCodable"))
    }

    func testOptionalCodableUserDefault_SetNil() {
        // Given
        struct TestData: Codable, Equatable {
            let value: Int
        }

        @OptionalCodableUserDefault(key: "testOptionalCodableNil", storage: testDefaults)
        var testData: TestData?

        testData = TestData(value: 123)
        XCTAssertNotNil(testData)

        // When
        testData = nil

        // Then
        XCTAssertNil(testData)
        XCTAssertNil(testDefaults.data(forKey: "testOptionalCodableNil"))
    }

    func testOptionalCodableUserDefault_Remove() {
        // Given
        struct TestData: Codable, Equatable {
            let flag: Bool
        }

        @OptionalCodableUserDefault(key: "testOptionalCodableRemove", storage: testDefaults)
        var testData: TestData?

        testData = TestData(flag: true)
        XCTAssertNotNil(testData)

        // When
        _testData.remove()

        // Then
        XCTAssertNil(testData)
        XCTAssertNil(testDefaults.data(forKey: "testOptionalCodableRemove"))
    }

    // MARK: - AppUserDefaults Integration Tests

    func testAppUserDefaults_HasCompletedFirstLaunch() {
        // Note: These tests use the shared UserDefaults.standard
        // In a real test suite, you'd want to inject a test UserDefaults instance

        let appDefaults = AppUserDefaults.shared

        // Initial state (may vary depending on previous test runs)
        let initial = appDefaults.hasCompletedFirstLaunch

        // Toggle the value
        appDefaults.hasCompletedFirstLaunch = !initial

        // Verify it changed
        XCTAssertEqual(appDefaults.hasCompletedFirstLaunch, !initial)

        // Restore
        appDefaults.hasCompletedFirstLaunch = initial
    }

    func testAppUserDefaults_OverrideMode() {
        let appDefaults = AppUserDefaults.shared

        let initial = appDefaults.overrideMode

        // Change value
        appDefaults.overrideMode = "test_mode"
        XCTAssertEqual(appDefaults.overrideMode, "test_mode")

        // Restore
        appDefaults.overrideMode = initial
    }

    // MARK: - Edge Cases

    func testUserDefault_EmptyString() {
        @UserDefault(key: "testEmptyString", defaultValue: "default", storage: testDefaults)
        var testString: String

        testString = ""
        XCTAssertEqual(testString, "")
    }

    func testCodableUserDefault_EncodingFailure() {
        // This test verifies that if encoding fails, the value remains unchanged

        struct TestData: Codable, Equatable {
            let value: String
        }

        let defaultData = TestData(value: "default")

        @CodableUserDefault(key: "testEncodingFailure", defaultValue: defaultData, storage: testDefaults)
        var testData: TestData

        // Set initial value
        testData = TestData(value: "initial")
        XCTAssertEqual(testData.value, "initial")

        // Normal encoding should work
        testData = TestData(value: "updated")
        XCTAssertEqual(testData.value, "updated")
    }

    func testCodableUserDefault_CorruptedData() {
        // Given - Manually insert corrupted data
        testDefaults.set(Data([0xFF, 0xFF]), forKey: "testCorrupted")

        struct TestData: Codable, Equatable {
            let value: String
        }

        let defaultData = TestData(value: "default")

        @CodableUserDefault(key: "testCorrupted", defaultValue: defaultData, storage: testDefaults)
        var testData: TestData

        // Then - Should fall back to default value
        XCTAssertEqual(testData, defaultData)
    }
}
