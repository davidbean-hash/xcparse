//
//  VersionParsingTests.swift
//  xcparseTests
//
//  Tests for Version+XCPTooling.swift parsing logic
//

import XCTest
import TSCUtility
@testable import XCParseCore

final class VersionParsingTests: XCTestCase {

    // MARK: - Plain integer version (pre-Xcode 26 format)

    func testPlainIntegerVersion() {
        let output = "xcresulttool version 23028, format version 3.53 (current)\n"
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(23028, 0, 0))
    }

    func testPlainIntegerVersionWithoutTrailingInfo() {
        let output = "xcresulttool version 23028\n"
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(23028, 0, 0))
    }

    // MARK: - Dotted version (Xcode 26 beta format)

    func testDottedVersionTwoComponents() {
        let output = "xcresulttool version 26.0, format version 3.53 (current)\n"
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(26, 0, 0))
    }

    func testDottedVersionThreeComponents() {
        let output = "xcresulttool version 26.0.0, format version 3.53 (current)\n"
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(26, 0, 0))
    }

    func testDottedVersionWithNonZeroPatch() {
        let output = "xcresulttool version 26.1.2, format version 3.53 (current)\n"
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(26, 1, 2))
    }

    func testDottedVersionWithNonZeroMinor() {
        let output = "xcresulttool version 26.3\n"
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(26, 3, 0))
    }

    // MARK: - Unparseable output

    func testEmptyStringReturnsNil() {
        let output = ""
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNil(version)
    }

    func testGarbageOutputReturnsNil() {
        let output = "some completely unrelated output\n"
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNil(version)
    }

    func testNoVersionNumberReturnsNil() {
        let output = "xcresulttool version abc\n"
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNil(version)
    }

    // MARK: - Fallback regex parsing

    func testFallbackRegexWithDifferentPrefix() {
        let output = "Tool version 23028\n"
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(23028, 0, 0))
    }

    func testFallbackRegexWithDottedVersion() {
        let output = "Tool version 26.0.1\n"
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(26, 0, 1))
    }

    // MARK: - shouldAddLegacyFlag behavior

    func testVersionAboveDeprecatedThresholdShouldAddLegacy() {
        let version = Version(23028, 0, 0)
        let deprecated = Version.xcresulttoolWithDeprecatedAPIs()
        XCTAssertTrue(version >= deprecated)
    }

    func testVersionBelowDeprecatedThresholdShouldNotAddLegacy() {
        let version = Version(15500, 0, 0)
        let deprecated = Version.xcresulttoolWithDeprecatedAPIs()
        XCTAssertFalse(version >= deprecated)
    }

    func testXcode26VersionShouldNotAddLegacy() {
        // Xcode 26 reports version 26.0 which is below 23028
        let version = Version(26, 0, 0)
        let deprecated = Version.xcresulttoolWithDeprecatedAPIs()
        XCTAssertFalse(version >= deprecated)
    }

    // MARK: - Edge cases

    func testMultilineOutputWithVersionOnSecondLine() {
        let output = "some header info\nxcresulttool version 23028, format version 3.53\n"
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(23028, 0, 0))
    }

    func testOutputWithExtraWhitespace() {
        let output = "  xcresulttool version 23028  \n"
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(23028, 0, 0))
    }

    func testOutputWithCommasSeparatingComponents() {
        let output = "xcresulttool version 26.0, format version 3.53 (current)"
        let version = Version.parseXcresulttoolVersionOutput(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(26, 0, 0))
    }

    static var allTests = [
        ("testPlainIntegerVersion", testPlainIntegerVersion),
        ("testPlainIntegerVersionWithoutTrailingInfo", testPlainIntegerVersionWithoutTrailingInfo),
        ("testDottedVersionTwoComponents", testDottedVersionTwoComponents),
        ("testDottedVersionThreeComponents", testDottedVersionThreeComponents),
        ("testDottedVersionWithNonZeroPatch", testDottedVersionWithNonZeroPatch),
        ("testDottedVersionWithNonZeroMinor", testDottedVersionWithNonZeroMinor),
        ("testEmptyStringReturnsNil", testEmptyStringReturnsNil),
        ("testGarbageOutputReturnsNil", testGarbageOutputReturnsNil),
        ("testNoVersionNumberReturnsNil", testNoVersionNumberReturnsNil),
        ("testFallbackRegexWithDifferentPrefix", testFallbackRegexWithDifferentPrefix),
        ("testFallbackRegexWithDottedVersion", testFallbackRegexWithDottedVersion),
        ("testVersionAboveDeprecatedThresholdShouldAddLegacy", testVersionAboveDeprecatedThresholdShouldAddLegacy),
        ("testVersionBelowDeprecatedThresholdShouldNotAddLegacy", testVersionBelowDeprecatedThresholdShouldNotAddLegacy),
        ("testXcode26VersionShouldNotAddLegacy", testXcode26VersionShouldNotAddLegacy),
        ("testMultilineOutputWithVersionOnSecondLine", testMultilineOutputWithVersionOnSecondLine),
        ("testOutputWithExtraWhitespace", testOutputWithExtraWhitespace),
        ("testOutputWithCommasSeparatingComponents", testOutputWithCommasSeparatingComponents),
    ]
}
