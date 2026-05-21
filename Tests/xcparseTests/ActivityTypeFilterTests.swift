//
//  ActivityTypeFilterTests.swift
//  xcparseTests
//
//  Tests for activity type matching logic used by --activity-type filtering.
//  Verifies case-insensitive and suffix-based matching that supports
//  activity type string changes across Xcode versions (e.g. Xcode 14.2+).
//

import XCTest
@testable import xcparse

final class ActivityTypeFilterTests: XCTestCase {

    // MARK: - Exact match (full domain)

    func testExactMatchWithFullDomain() {
        let allowed = ["com.apple.dt.xctest.activity-type.testAssertionFailure"]
        XCTAssertTrue(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.dt.xctest.activity-type.testAssertionFailure",
                allowedTypes: allowed))
    }

    func testExactMatchIsCaseInsensitive() {
        let allowed = ["com.apple.dt.xctest.activity-type.testAssertionFailure"]
        XCTAssertTrue(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.dt.xctest.activity-type.TESTASSERTIONFAILURE",
                allowedTypes: allowed))
        XCTAssertTrue(
            AttachmentExportOptions.activityTypeMatches(
                "COM.APPLE.DT.XCTEST.ACTIVITY-TYPE.TESTASSERTIONFAILURE",
                allowedTypes: allowed))
    }

    // MARK: - Short name expansion

    func testShortNameExpandsToKnownDomain() {
        let allowed = ["testAssertionFailure"]
        XCTAssertTrue(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.dt.xctest.activity-type.testAssertionFailure",
                allowedTypes: allowed))
    }

    func testShortNameMatchIsCaseInsensitive() {
        let allowed = ["testassertionfailure"]
        XCTAssertTrue(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.dt.xctest.activity-type.testAssertionFailure",
                allowedTypes: allowed))
    }

    // MARK: - Suffix matching (handles changed prefix in Xcode 14.2+)

    func testShortNameMatchesDifferentPrefix() {
        let allowed = ["testAssertionFailure"]
        // Hypothetical new prefix in future Xcode
        XCTAssertTrue(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.dt.xctest.activity.testAssertionFailure",
                allowedTypes: allowed))
        XCTAssertTrue(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.xctest.activity-type.testAssertionFailure",
                allowedTypes: allowed))
    }

    func testSuffixMatchIsCaseInsensitive() {
        let allowed = ["testAssertionFailure"]
        XCTAssertTrue(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.dt.xctest.activity.TESTASSERTIONFAILURE",
                allowedTypes: allowed))
    }

    // MARK: - Multiple allowed types

    func testMultipleAllowedTypes() {
        let allowed = ["userCreated", "attachmentContainer"]
        XCTAssertTrue(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.dt.xctest.activity-type.userCreated",
                allowedTypes: allowed))
        XCTAssertTrue(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.dt.xctest.activity-type.attachmentContainer",
                allowedTypes: allowed))
        XCTAssertFalse(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.dt.xctest.activity-type.testAssertionFailure",
                allowedTypes: allowed))
    }

    func testMixedShortAndFullDomainAllowedTypes() {
        let allowed = [
            "userCreated",
            "com.apple.dt.xctest.activity-type.testAssertionFailure"
        ]
        XCTAssertTrue(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.dt.xctest.activity-type.userCreated",
                allowedTypes: allowed))
        XCTAssertTrue(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.dt.xctest.activity-type.testAssertionFailure",
                allowedTypes: allowed))
    }

    // MARK: - Non-matching

    func testNonMatchingActivityType() {
        let allowed = ["testAssertionFailure"]
        XCTAssertFalse(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.dt.xctest.activity-type.internal",
                allowedTypes: allowed))
    }

    func testEmptyAllowedTypes() {
        XCTAssertFalse(
            AttachmentExportOptions.activityTypeMatches(
                "com.apple.dt.xctest.activity-type.testAssertionFailure",
                allowedTypes: []))
    }

    func testEmptyActivityType() {
        let allowed = ["testAssertionFailure"]
        XCTAssertFalse(
            AttachmentExportOptions.activityTypeMatches("", allowedTypes: allowed))
    }

    // MARK: - All known activity types

    func testAllKnownActivityTypes() {
        let knownTypes: [(shortName: String, fullDomain: String)] = [
            ("attachmentContainer", "com.apple.dt.xctest.activity-type.attachmentContainer"),
            ("deletedAttachment", "com.apple.dt.xctest.activity-type.deletedAttachment"),
            ("internal", "com.apple.dt.xctest.activity-type.internal"),
            ("testAssertionFailure", "com.apple.dt.xctest.activity-type.testAssertionFailure"),
            ("userCreated", "com.apple.dt.xctest.activity-type.userCreated"),
        ]

        for knownType in knownTypes {
            // Short name should match full domain
            XCTAssertTrue(
                AttachmentExportOptions.activityTypeMatches(
                    knownType.fullDomain,
                    allowedTypes: [knownType.shortName]),
                "\(knownType.shortName) should match \(knownType.fullDomain)")

            // Full domain should match full domain
            XCTAssertTrue(
                AttachmentExportOptions.activityTypeMatches(
                    knownType.fullDomain,
                    allowedTypes: [knownType.fullDomain]),
                "\(knownType.fullDomain) should match itself")
        }
    }

    // MARK: - Full domain allowed type should not do suffix matching

    func testFullDomainDoesNotSuffixMatch() {
        // When user passes a full domain string, only exact (case-insensitive)
        // match should apply, not suffix matching
        let allowed = ["com.apple.dt.xctest.activity-type.testAssertionFailure"]
        XCTAssertFalse(
            AttachmentExportOptions.activityTypeMatches(
                "com.other.domain.testAssertionFailure",
                allowedTypes: allowed))
    }

    static var allTests = [
        ("testExactMatchWithFullDomain", testExactMatchWithFullDomain),
        ("testExactMatchIsCaseInsensitive", testExactMatchIsCaseInsensitive),
        ("testShortNameExpandsToKnownDomain", testShortNameExpandsToKnownDomain),
        ("testShortNameMatchIsCaseInsensitive", testShortNameMatchIsCaseInsensitive),
        ("testShortNameMatchesDifferentPrefix", testShortNameMatchesDifferentPrefix),
        ("testSuffixMatchIsCaseInsensitive", testSuffixMatchIsCaseInsensitive),
        ("testMultipleAllowedTypes", testMultipleAllowedTypes),
        ("testMixedShortAndFullDomainAllowedTypes", testMixedShortAndFullDomainAllowedTypes),
        ("testNonMatchingActivityType", testNonMatchingActivityType),
        ("testEmptyAllowedTypes", testEmptyAllowedTypes),
        ("testEmptyActivityType", testEmptyActivityType),
        ("testAllKnownActivityTypes", testAllKnownActivityTypes),
        ("testFullDomainDoesNotSuffixMatch", testFullDomainDoesNotSuffixMatch),
    ]
}
