//
//  TestReportTests.swift
//  xcparse
//
//  Copyright © 2024 ChargePoint, Inc. All rights reserved.
//

import XCTest
@testable import xcparse

final class TestReportTests: XCTestCase {

    // MARK: - TestAttachmentEntry Codable Tests

    func testAttachmentEntryCodableRoundTrip() throws {
        let attachment = TestAttachmentEntry(
            name: "reference_image",
            filename: "screenshot.png",
            uniformTypeIdentifier: "public.png"
        )

        let data = try JSONEncoder().encode(attachment)
        let decoded = try JSONDecoder().decode(TestAttachmentEntry.self, from: data)

        XCTAssertEqual(decoded.name, "reference_image")
        XCTAssertEqual(decoded.filename, "screenshot.png")
        XCTAssertEqual(decoded.uniformTypeIdentifier, "public.png")
    }

    func testAttachmentEntryWithNilOptionals() throws {
        let attachment = TestAttachmentEntry(
            name: nil,
            filename: nil,
            uniformTypeIdentifier: "public.image"
        )

        let data = try JSONEncoder().encode(attachment)
        let decoded = try JSONDecoder().decode(TestAttachmentEntry.self, from: data)

        XCTAssertNil(decoded.name)
        XCTAssertNil(decoded.filename)
        XCTAssertEqual(decoded.uniformTypeIdentifier, "public.image")
    }

    // MARK: - TestFailureEntry Codable Tests

    func testFailureEntryCodableRoundTrip() throws {
        let failure = TestFailureEntry(
            file: "/path/to/failed_file.swift",
            line: 32,
            message: "XCTAssertEqual failed: (\"a\") is not equal to (\"b\")"
        )

        let data = try JSONEncoder().encode(failure)
        let decoded = try JSONDecoder().decode(TestFailureEntry.self, from: data)

        XCTAssertEqual(decoded.file, "/path/to/failed_file.swift")
        XCTAssertEqual(decoded.line, 32)
        XCTAssertEqual(decoded.message, "XCTAssertEqual failed: (\"a\") is not equal to (\"b\")")
    }

    func testFailureEntryWithNilOptionals() throws {
        let failure = TestFailureEntry(
            file: nil,
            line: nil,
            message: nil
        )

        let data = try JSONEncoder().encode(failure)
        let decoded = try JSONDecoder().decode(TestFailureEntry.self, from: data)

        XCTAssertNil(decoded.file)
        XCTAssertNil(decoded.line)
        XCTAssertNil(decoded.message)
    }

    // MARK: - TestReportEntry Codable Tests

    func testReportEntryCodableRoundTrip() throws {
        let failure = TestFailureEntry(
            file: "/Tests/MyTests.swift",
            line: 42,
            message: "failed - expected true, got false"
        )
        let attachment = TestAttachmentEntry(
            name: "failure_screenshot",
            filename: "failure_screenshot.png",
            uniformTypeIdentifier: "public.png"
        )
        let entry = TestReportEntry(
            name: "testLogin()",
            identifier: "MyAppTests/testLogin()",
            status: "Failure",
            duration: 1.234,
            failureSummaries: [failure],
            attachments: [attachment]
        )

        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TestReportEntry.self, from: data)

        XCTAssertEqual(decoded.name, "testLogin()")
        XCTAssertEqual(decoded.identifier, "MyAppTests/testLogin()")
        XCTAssertEqual(decoded.status, "Failure")
        XCTAssertEqual(decoded.duration, 1.234, accuracy: 0.001)
        XCTAssertEqual(decoded.failureSummaries?.count, 1)
        XCTAssertEqual(decoded.failureSummaries?.first?.file, "/Tests/MyTests.swift")
        XCTAssertEqual(decoded.failureSummaries?.first?.line, 42)
        XCTAssertEqual(decoded.attachments?.count, 1)
        XCTAssertEqual(decoded.attachments?.first?.filename, "failure_screenshot.png")
    }

    func testReportEntrySuccessWithNoFailures() throws {
        let entry = TestReportEntry(
            name: "testSuccess()",
            identifier: "MyAppTests/testSuccess()",
            status: "Success",
            duration: 0.5,
            failureSummaries: nil,
            attachments: nil
        )

        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TestReportEntry.self, from: data)

        XCTAssertEqual(decoded.name, "testSuccess()")
        XCTAssertEqual(decoded.status, "Success")
        XCTAssertEqual(decoded.duration, 0.5, accuracy: 0.001)
        XCTAssertNil(decoded.failureSummaries)
        XCTAssertNil(decoded.attachments)
    }

    // MARK: - TestReport Codable Tests

    func testReportCodableRoundTrip() throws {
        let entries = [
            TestReportEntry(
                name: "testA()",
                identifier: "Suite/testA()",
                status: "Success",
                duration: 0.1,
                failureSummaries: nil,
                attachments: nil
            ),
            TestReportEntry(
                name: "testB()",
                identifier: "Suite/testB()",
                status: "Failure",
                duration: 2.0,
                failureSummaries: [
                    TestFailureEntry(file: "/Tests/B.swift", line: 10, message: "assertion failed")
                ],
                attachments: [
                    TestAttachmentEntry(name: "diff", filename: "diff.png", uniformTypeIdentifier: "public.png")
                ]
            ),
        ]
        let report = TestReport(tests: entries)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(report)
        let decoded = try JSONDecoder().decode(TestReport.self, from: data)

        XCTAssertEqual(decoded.tests.count, 2)
        XCTAssertEqual(decoded.tests[0].status, "Success")
        XCTAssertEqual(decoded.tests[1].status, "Failure")
        XCTAssertEqual(decoded.tests[1].failureSummaries?.count, 1)
        XCTAssertEqual(decoded.tests[1].attachments?.count, 1)
    }

    func testEmptyReport() throws {
        let report = TestReport(tests: [])

        let data = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(TestReport.self, from: data)

        XCTAssertEqual(decoded.tests.count, 0)
    }

    // MARK: - JSON Structure Validation

    func testJSONOutputContainsExpectedKeys() throws {
        let failure = TestFailureEntry(
            file: "/path/to/failed_file.swift",
            line: 32,
            message: "failure message reported"
        )
        let attachment = TestAttachmentEntry(
            name: "reference",
            filename: "reference_image.png",
            uniformTypeIdentifier: "public.png"
        )
        let entry = TestReportEntry(
            name: "testSnapshot()",
            identifier: "SnapshotTests/testSnapshot()",
            status: "Failure",
            duration: 3.5,
            failureSummaries: [failure],
            attachments: [attachment]
        )
        let report = TestReport(tests: [entry])

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(report)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Top-level JSON is not a dictionary")
            return
        }

        // Verify top-level "tests" array
        guard let tests = json["tests"] as? [[String: Any]] else {
            XCTFail("Missing 'tests' array")
            return
        }
        XCTAssertEqual(tests.count, 1)

        let testEntry = tests[0]
        XCTAssertNotNil(testEntry["name"])
        XCTAssertNotNil(testEntry["identifier"])
        XCTAssertNotNil(testEntry["status"])
        XCTAssertNotNil(testEntry["duration"])

        // Verify failure summaries contain file, line, message
        guard let failures = testEntry["failureSummaries"] as? [[String: Any]] else {
            XCTFail("Missing 'failureSummaries' array")
            return
        }
        XCTAssertEqual(failures.count, 1)
        XCTAssertEqual(failures[0]["file"] as? String, "/path/to/failed_file.swift")
        XCTAssertEqual(failures[0]["line"] as? Int, 32)
        XCTAssertEqual(failures[0]["message"] as? String, "failure message reported")

        // Verify attachments contain name, filename, UTI
        guard let attachments = testEntry["attachments"] as? [[String: Any]] else {
            XCTFail("Missing 'attachments' array")
            return
        }
        XCTAssertEqual(attachments.count, 1)
        XCTAssertEqual(attachments[0]["name"] as? String, "reference")
        XCTAssertEqual(attachments[0]["filename"] as? String, "reference_image.png")
        XCTAssertEqual(attachments[0]["uniformTypeIdentifier"] as? String, "public.png")
    }

    func testJSONDecodingFromRawString() throws {
        let jsonString = """
        {
            "tests": [
                {
                    "name": "testExample()",
                    "identifier": "MyTests/testExample()",
                    "status": "Success",
                    "duration": 0.25,
                    "failureSummaries": null,
                    "attachments": null
                }
            ]
        }
        """
        let data = jsonString.data(using: .utf8)!
        let report = try JSONDecoder().decode(TestReport.self, from: data)

        XCTAssertEqual(report.tests.count, 1)
        XCTAssertEqual(report.tests[0].name, "testExample()")
        XCTAssertEqual(report.tests[0].status, "Success")
        XCTAssertEqual(report.tests[0].duration, 0.25, accuracy: 0.001)
        XCTAssertNil(report.tests[0].failureSummaries)
        XCTAssertNil(report.tests[0].attachments)
    }

    func testMultipleFailuresAndAttachments() throws {
        let entry = TestReportEntry(
            name: "testSnapshotComparison()",
            identifier: "SnapshotTests/testSnapshotComparison()",
            status: "Failure",
            duration: 5.0,
            failureSummaries: [
                TestFailureEntry(file: "/Tests/Snap.swift", line: 10, message: "reference mismatch"),
                TestFailureEntry(file: "/Tests/Snap.swift", line: 20, message: "pixel diff too large"),
            ],
            attachments: [
                TestAttachmentEntry(name: "reference", filename: "ref.png", uniformTypeIdentifier: "public.png"),
                TestAttachmentEntry(name: "failure", filename: "fail.png", uniformTypeIdentifier: "public.png"),
                TestAttachmentEntry(name: "difference", filename: "diff.png", uniformTypeIdentifier: "public.png"),
            ]
        )

        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TestReportEntry.self, from: data)

        XCTAssertEqual(decoded.failureSummaries?.count, 2)
        XCTAssertEqual(decoded.attachments?.count, 3)
        XCTAssertEqual(decoded.attachments?[0].name, "reference")
        XCTAssertEqual(decoded.attachments?[1].name, "failure")
        XCTAssertEqual(decoded.attachments?[2].name, "difference")
    }

    // MARK: - allTests (Linux support)

    static var allTests = [
        ("testAttachmentEntryCodableRoundTrip", testAttachmentEntryCodableRoundTrip),
        ("testAttachmentEntryWithNilOptionals", testAttachmentEntryWithNilOptionals),
        ("testFailureEntryCodableRoundTrip", testFailureEntryCodableRoundTrip),
        ("testFailureEntryWithNilOptionals", testFailureEntryWithNilOptionals),
        ("testReportEntryCodableRoundTrip", testReportEntryCodableRoundTrip),
        ("testReportEntrySuccessWithNoFailures", testReportEntrySuccessWithNoFailures),
        ("testReportCodableRoundTrip", testReportCodableRoundTrip),
        ("testEmptyReport", testEmptyReport),
        ("testJSONOutputContainsExpectedKeys", testJSONOutputContainsExpectedKeys),
        ("testJSONDecodingFromRawString", testJSONDecodingFromRawString),
        ("testMultipleFailuresAndAttachments", testMultipleFailuresAndAttachments),
    ]
}
