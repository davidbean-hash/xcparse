//
//  VersionParsingTests.swift
//  xcparseTests
//
//  Tests for xcresulttool version string parsing.
//

import XCTest
import TSCUtility
@testable import XCParseCore

final class VersionParsingTests: XCTestCase {

    // MARK: - Standard format (integer build number)

    func testParseStandardVersionString() {
        let output = "xcresulttool version 23028, format version 3.53 (current)\n"
        let version = Version.parseXCResultToolVersionString(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(23028, 0, 0))
    }

    func testParseOlderVersionString() {
        let output = "xcresulttool version 15500, format version 3.19 (current)\n"
        let version = Version.parseXCResultToolVersionString(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(15500, 0, 0))
    }

    // MARK: - Semantic version format

    func testParseSemverVersionString() {
        let output = "xcresulttool version 23028.0.1, format version 3.53 (current)\n"
        let version = Version.parseXCResultToolVersionString(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(23028, 0, 1))
    }

    func testParseTwoComponentSemverString() {
        let output = "xcresulttool version 26000.1, format version 4.0 (current)\n"
        let version = Version.parseXCResultToolVersionString(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(26000, 1, 0))
    }

    // MARK: - Edge cases

    func testParseEmptyString() {
        let version = Version.parseXCResultToolVersionString("")
        XCTAssertNil(version)
    }

    func testParseNoVersionPrefix() {
        let output = "some unexpected output\n"
        let version = Version.parseXCResultToolVersionString(output)
        XCTAssertNil(version)
    }

    func testParseVersionOnly() {
        let output = "xcresulttool version 23028\n"
        let version = Version.parseXCResultToolVersionString(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(23028, 0, 0))
    }

    func testParseMultilineOutput() {
        let output = "some header line\nxcresulttool version 23028, format version 3.53\nanother line\n"
        let version = Version.parseXCResultToolVersionString(output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(23028, 0, 0))
    }

    // MARK: - Version comparison with deprecated API threshold

    func testVersionAboveDeprecatedThreshold() {
        let output = "xcresulttool version 26000, format version 4.0 (current)\n"
        let version = Version.parseXCResultToolVersionString(output)
        XCTAssertNotNil(version)
        let threshold = Version.xcresulttoolWithDeprecatedAPIs()
        XCTAssertTrue(version! >= threshold, "Version 26000 should be >= deprecated API threshold \(threshold)")
    }

    func testVersionBelowDeprecatedThreshold() {
        let output = "xcresulttool version 15500, format version 3.19 (current)\n"
        let version = Version.parseXCResultToolVersionString(output)
        XCTAssertNotNil(version)
        let threshold = Version.xcresulttoolWithDeprecatedAPIs()
        XCTAssertTrue(version! < threshold, "Version 15500 should be < deprecated API threshold \(threshold)")
    }

    func testVersionAtExactThreshold() {
        let output = "xcresulttool version 23028, format version 3.53 (current)\n"
        let version = Version.parseXCResultToolVersionString(output)
        XCTAssertNotNil(version)
        let threshold = Version.xcresulttoolWithDeprecatedAPIs()
        XCTAssertTrue(version! >= threshold, "Version 23028 should be >= deprecated API threshold \(threshold)")
    }

    static var allTests = [
        ("testParseStandardVersionString", testParseStandardVersionString),
        ("testParseOlderVersionString", testParseOlderVersionString),
        ("testParseSemverVersionString", testParseSemverVersionString),
        ("testParseTwoComponentSemverString", testParseTwoComponentSemverString),
        ("testParseEmptyString", testParseEmptyString),
        ("testParseNoVersionPrefix", testParseNoVersionPrefix),
        ("testParseVersionOnly", testParseVersionOnly),
        ("testParseMultilineOutput", testParseMultilineOutput),
        ("testVersionAboveDeprecatedThreshold", testVersionAboveDeprecatedThreshold),
        ("testVersionBelowDeprecatedThreshold", testVersionBelowDeprecatedThreshold),
        ("testVersionAtExactThreshold", testVersionAtExactThreshold),
    ]
}
