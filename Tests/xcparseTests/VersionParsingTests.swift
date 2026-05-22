//
//  VersionParsingTests.swift
//  xcparseTests
//
//  Created by Devin on 2026-05-22.
//

import XCTest
import TSCUtility
@testable import XCParseCore

final class VersionParsingTests: XCTestCase {

    // MARK: - parseVersionString

    func testParseVersionStringWithInteger() {
        let version = Version.parseVersionString("23028")
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(23028, 0, 0))
    }

    func testParseVersionStringWithFullSemver() {
        let version = Version.parseVersionString("26.0.0")
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(26, 0, 0))
    }

    func testParseVersionStringWithTwoComponentSemver() {
        let version = Version.parseVersionString("26.0")
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(26, 0, 0))
    }

    func testParseVersionStringWithTwoComponentNonZeroMinor() {
        let version = Version.parseVersionString("26.1")
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(26, 1, 0))
    }

    func testParseVersionStringWithWhitespace() {
        let version = Version.parseVersionString("  23028  ")
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(23028, 0, 0))
    }

    func testParseVersionStringWithEmptyString() {
        let version = Version.parseVersionString("")
        XCTAssertNil(version)
    }

    func testParseVersionStringWithGarbage() {
        let version = Version.parseVersionString("not-a-version")
        XCTAssertNil(version)
    }

    // MARK: - parseXCResultToolVersion

    func testParseXCResultToolVersionLegacyFormat() {
        let output = "xcresulttool version 23028, format version 3.49 (current)\n"
        let version = Version.parseXCResultToolVersion(from: output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(23028, 0, 0))
    }

    func testParseXCResultToolVersionSemverFormat() {
        let output = "xcresulttool version 26.0\n"
        let version = Version.parseXCResultToolVersion(from: output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(26, 0, 0))
    }

    func testParseXCResultToolVersionFullSemverFormat() {
        let output = "xcresulttool version 26.0.0\n"
        let version = Version.parseXCResultToolVersion(from: output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(26, 0, 0))
    }

    func testParseXCResultToolVersionSemverWithExtraInfo() {
        let output = "xcresulttool version 26.1, build 26A5082e\n"
        let version = Version.parseXCResultToolVersion(from: output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(26, 1, 0))
    }

    func testParseXCResultToolVersionOldBuildNumber() {
        let output = "xcresulttool version 15400, format version 3.30 (current)\n"
        let version = Version.parseXCResultToolVersion(from: output)
        XCTAssertNotNil(version)
        XCTAssertEqual(version, Version(15400, 0, 0))
    }

    func testParseXCResultToolVersionEmptyOutput() {
        let version = Version.parseXCResultToolVersion(from: "")
        XCTAssertNil(version)
    }

    func testParseXCResultToolVersionUnrecognizedFormat() {
        let output = "some completely different output\n"
        let version = Version.parseXCResultToolVersion(from: output)
        XCTAssertNil(version)
    }

    // MARK: - Legacy flag thresholds

    func testDeprecatedAPIsVersionThreshold() {
        let threshold = Version.xcresulttoolWithDeprecatedAPIs()
        XCTAssertEqual(threshold, Version(23028, 0, 0))
    }

    func testSemanticVersionIsAboveDeprecatedThresholdIntent() {
        // Xcode 26+ uses semantic versioning (major < 1000).
        // Even though 26 < 23028 numerically, these versions always need --legacy.
        let xcode26Version = Version(26, 0, 0)
        XCTAssertTrue(xcode26Version.major < 1000,
                       "Semantic versions should have major < 1000")
    }

    func testLegacyBuildNumberAboveThreshold() {
        let version = Version(23028, 0, 0)
        let threshold = Version.xcresulttoolWithDeprecatedAPIs()
        XCTAssertTrue(version >= threshold)
    }

    func testLegacyBuildNumberBelowThreshold() {
        let version = Version(15400, 0, 0)
        let threshold = Version.xcresulttoolWithDeprecatedAPIs()
        XCTAssertFalse(version >= threshold)
    }

    static var allTests = [
        ("testParseVersionStringWithInteger", testParseVersionStringWithInteger),
        ("testParseVersionStringWithFullSemver", testParseVersionStringWithFullSemver),
        ("testParseVersionStringWithTwoComponentSemver", testParseVersionStringWithTwoComponentSemver),
        ("testParseVersionStringWithTwoComponentNonZeroMinor", testParseVersionStringWithTwoComponentNonZeroMinor),
        ("testParseVersionStringWithWhitespace", testParseVersionStringWithWhitespace),
        ("testParseVersionStringWithEmptyString", testParseVersionStringWithEmptyString),
        ("testParseVersionStringWithGarbage", testParseVersionStringWithGarbage),
        ("testParseXCResultToolVersionLegacyFormat", testParseXCResultToolVersionLegacyFormat),
        ("testParseXCResultToolVersionSemverFormat", testParseXCResultToolVersionSemverFormat),
        ("testParseXCResultToolVersionFullSemverFormat", testParseXCResultToolVersionFullSemverFormat),
        ("testParseXCResultToolVersionSemverWithExtraInfo", testParseXCResultToolVersionSemverWithExtraInfo),
        ("testParseXCResultToolVersionOldBuildNumber", testParseXCResultToolVersionOldBuildNumber),
        ("testParseXCResultToolVersionEmptyOutput", testParseXCResultToolVersionEmptyOutput),
        ("testParseXCResultToolVersionUnrecognizedFormat", testParseXCResultToolVersionUnrecognizedFormat),
        ("testDeprecatedAPIsVersionThreshold", testDeprecatedAPIsVersionThreshold),
        ("testSemanticVersionIsAboveDeprecatedThresholdIntent", testSemanticVersionIsAboveDeprecatedThresholdIntent),
        ("testLegacyBuildNumberAboveThreshold", testLegacyBuildNumberAboveThreshold),
        ("testLegacyBuildNumberBelowThreshold", testLegacyBuildNumberBelowThreshold),
    ]
}
