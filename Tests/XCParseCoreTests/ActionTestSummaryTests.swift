//
//  ActionTestSummaryTests.swift
//  xcparseTests
//
//  Tests for allAttachments() method and failureSummary attachment collection
//

import XCTest
@testable import XCParseCore

final class ActionTestSummaryTests: XCTestCase {

    // MARK: - allAttachments() Tests

    func testAllAttachmentsReturnsActivityAttachments() throws {
        let json = makeTestSummaryJSON(
            activityAttachments: [
                makeAttachmentJSON(filename: "screenshot1.png", uti: "public.png", payloadRefId: "ref-001"),
                makeAttachmentJSON(filename: "screenshot2.heic", uti: "public.heic", payloadRefId: "ref-002"),
            ],
            failureAttachments: []
        )

        let testSummary = try decodeTestSummary(from: json)
        let allAttachments = testSummary.allAttachments()

        XCTAssertEqual(allAttachments.count, 2)
        XCTAssertEqual(allAttachments[0].filename, "screenshot1.png")
        XCTAssertEqual(allAttachments[1].filename, "screenshot2.heic")
    }

    func testAllAttachmentsReturnsFailureSummaryAttachments() throws {
        let json = makeTestSummaryJSON(
            activityAttachments: [],
            failureAttachments: [
                makeAttachmentJSON(filename: "failure_screenshot.png", uti: "public.png", payloadRefId: "ref-003"),
            ]
        )

        let testSummary = try decodeTestSummary(from: json)
        let allAttachments = testSummary.allAttachments()

        XCTAssertEqual(allAttachments.count, 1)
        XCTAssertEqual(allAttachments[0].filename, "failure_screenshot.png")
    }

    func testAllAttachmentsCombinesActivityAndFailureAttachments() throws {
        let json = makeTestSummaryJSON(
            activityAttachments: [
                makeAttachmentJSON(filename: "activity.png", uti: "public.png", payloadRefId: "ref-001"),
            ],
            failureAttachments: [
                makeAttachmentJSON(filename: "failure.json", uti: "public.json", payloadRefId: "ref-002"),
            ]
        )

        let testSummary = try decodeTestSummary(from: json)
        let allAttachments = testSummary.allAttachments()

        XCTAssertEqual(allAttachments.count, 2)
        let filenames = allAttachments.compactMap { $0.filename }
        XCTAssertTrue(filenames.contains("activity.png"))
        XCTAssertTrue(filenames.contains("failure.json"))
    }

    func testAllAttachmentsReturnsEmptyWhenNoAttachments() throws {
        let json = makeTestSummaryJSON(
            activityAttachments: [],
            failureAttachments: []
        )

        let testSummary = try decodeTestSummary(from: json)
        let allAttachments = testSummary.allAttachments()

        XCTAssertEqual(allAttachments.count, 0)
    }

    func testAllAttachmentsIncludesSubactivityAttachments() throws {
        let json = makeTestSummaryJSONWithSubactivities(
            topAttachments: [
                makeAttachmentJSON(filename: "top.png", uti: "public.png", payloadRefId: "ref-001"),
            ],
            subAttachments: [
                makeAttachmentJSON(filename: "sub.png", uti: "public.png", payloadRefId: "ref-002"),
            ],
            failureAttachments: []
        )

        let testSummary = try decodeTestSummary(from: json)
        let allAttachments = testSummary.allAttachments()

        XCTAssertEqual(allAttachments.count, 2)
        let filenames = allAttachments.compactMap { $0.filename }
        XCTAssertTrue(filenames.contains("top.png"))
        XCTAssertTrue(filenames.contains("sub.png"))
    }

    func testAllAttachmentsIncludesNilPayloadRefAttachments() throws {
        let json = makeTestSummaryJSON(
            activityAttachments: [
                makeAttachmentJSON(filename: "no_payload.png", uti: "public.png", payloadRefId: nil),
            ],
            failureAttachments: []
        )

        let testSummary = try decodeTestSummary(from: json)
        let allAttachments = testSummary.allAttachments()

        XCTAssertEqual(allAttachments.count, 1)
        XCTAssertNil(allAttachments[0].payloadRef)
    }

    // MARK: - Export Failable Init Tests

    func testExportInitReturnsNilWhenPayloadRefIsNil() throws {
        let json = makeAttachmentJSON(filename: "test.png", uti: "public.png", payloadRefId: nil)
        let attachment = try decodeAttachment(from: json)

        let xcresult = XCResult(path: "/tmp/fake.xcresult")
        let exportCommand = XCResultToolCommand.Export(withXCResult: xcresult, attachment: attachment, outputPath: "/tmp/output")

        XCTAssertNil(exportCommand)
    }

    func testExportInitSucceedsWhenPayloadRefExists() throws {
        let json = makeAttachmentJSON(filename: "test.png", uti: "public.png", payloadRefId: "ref-123")
        let attachment = try decodeAttachment(from: json)

        let xcresult = XCResult(path: "/tmp/fake.xcresult")
        let exportCommand = XCResultToolCommand.Export(withXCResult: xcresult, attachment: attachment, outputPath: "/tmp/output")

        XCTAssertNotNil(exportCommand)
    }

    func testExportInitUsesFilenameInOutputPath() throws {
        let json = makeAttachmentJSON(filename: "myScreenshot.png", uti: "public.png", payloadRefId: "ref-456")
        let attachment = try decodeAttachment(from: json)

        let xcresult = XCResult(path: "/tmp/fake.xcresult")
        let exportCommand = XCResultToolCommand.Export(withXCResult: xcresult, attachment: attachment, outputPath: "/tmp/output")

        XCTAssertNotNil(exportCommand)
        XCTAssertTrue(exportCommand!.outputPath.hasSuffix("myScreenshot.png"))
    }

    func testExportInitUsesIdentifierWhenFilenameIsNil() throws {
        let json = makeAttachmentJSON(filename: nil, uti: "public.png", payloadRefId: "ref-789")
        let attachment = try decodeAttachment(from: json)

        let xcresult = XCResult(path: "/tmp/fake.xcresult")
        let exportCommand = XCResultToolCommand.Export(withXCResult: xcresult, attachment: attachment, outputPath: "/tmp/output")

        XCTAssertNotNil(exportCommand)
        XCTAssertTrue(exportCommand!.outputPath.hasSuffix("ref-789"))
    }

    // MARK: - Helpers

    private func decodeTestSummary(from json: String) throws -> ActionTestSummary {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(ActionTestSummary.self, from: data)
    }

    private func decodeAttachment(from json: String) throws -> ActionTestAttachment {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(ActionTestAttachment.self, from: data)
    }

    private func makeAttachmentJSON(filename: String?, uti: String, payloadRefId: String?) -> String {
        var payloadRefJSON = ""
        if let refId = payloadRefId {
            payloadRefJSON = """
            , "payloadRef": {
                "_type": {"_name": "Reference"},
                "id": {"_type": {"_name": "String"}, "_value": "\(refId)"}
            }
            """
        }

        var filenameJSON = ""
        if let name = filename {
            filenameJSON = """
            , "filename": {"_type": {"_name": "String"}, "_value": "\(name)"}
            """
        }

        return """
        {
            "_type": {"_name": "ActionTestAttachment"},
            "uniformTypeIdentifier": {"_type": {"_name": "String"}, "_value": "\(uti)"},
            "lifetime": {"_type": {"_name": "String"}, "_value": "keepAlways"},
            "inActivityIdentifier": {"_type": {"_name": "Int"}, "_value": "1"},
            "payloadSize": {"_type": {"_name": "Int"}, "_value": "1024"}
            \(filenameJSON)
            \(payloadRefJSON)
        }
        """
    }

    private func makeActivitySummaryJSON(attachments: [String]) -> String {
        let attachmentsArray = attachments.joined(separator: ", ")
        return """
        {
            "_type": {"_name": "ActionTestActivitySummary"},
            "title": {"_type": {"_name": "String"}, "_value": "Test Activity"},
            "activityType": {"_type": {"_name": "String"}, "_value": "com.apple.dt.xctest.activity-type.internal"},
            "uuid": {"_type": {"_name": "String"}, "_value": "activity-uuid-1"},
            "attachments": {"_values": [\(attachmentsArray)]},
            "subactivities": {"_values": []},
            "failureSummaryIDs": {"_values": []},
            "expectedFailureIDs": {"_values": []}
        }
        """
    }

    private func makeFailureSummaryJSON(attachments: [String]) -> String {
        let attachmentsArray = attachments.joined(separator: ", ")
        return """
        {
            "_type": {"_name": "ActionTestFailureSummary"},
            "message": {"_type": {"_name": "String"}, "_value": "XCTAssertTrue failed"},
            "fileName": {"_type": {"_name": "String"}, "_value": "/path/to/Test.swift"},
            "lineNumber": {"_type": {"_name": "Int"}, "_value": "42"},
            "isPerformanceFailure": {"_type": {"_name": "Bool"}, "_value": "false"},
            "uuid": {"_type": {"_name": "String"}, "_value": "failure-uuid-1"},
            "attachments": {"_values": [\(attachmentsArray)]},
            "isTopLevelFailure": {"_type": {"_name": "Bool"}, "_value": "true"}
        }
        """
    }

    private func makeTestSummaryJSON(activityAttachments: [String], failureAttachments: [String]) -> String {
        let activityJSON = activityAttachments.isEmpty ? "" : makeActivitySummaryJSON(attachments: activityAttachments)
        let activityArray = activityAttachments.isEmpty ? "" : activityJSON
        let failureJSON = failureAttachments.isEmpty ? "" : makeFailureSummaryJSON(attachments: failureAttachments)
        let failureArray = failureAttachments.isEmpty ? "" : failureJSON

        return """
        {
            "_type": {"_name": "ActionTestSummary", "_supertype": {"_name": "ActionTestSummaryIdentifiableObject", "_supertype": {"_name": "ActionAbstractTestSummary"}}},
            "name": {"_type": {"_name": "String"}, "_value": "testExample()"},
            "testStatus": {"_type": {"_name": "String"}, "_value": "Success"},
            "duration": {"_type": {"_name": "Double"}, "_value": "0.5"},
            "performanceMetrics": {"_values": []},
            "failureSummaries": {"_values": [\(failureArray)]},
            "activitySummaries": {"_values": [\(activityArray)]},
            "expectedFailures": {"_values": []}
        }
        """
    }

    private func makeTestSummaryJSONWithSubactivities(topAttachments: [String], subAttachments: [String], failureAttachments: [String]) -> String {
        let subAttachmentsArray = subAttachments.joined(separator: ", ")
        let topAttachmentsArray = topAttachments.joined(separator: ", ")

        let subactivityJSON = """
        {
            "_type": {"_name": "ActionTestActivitySummary"},
            "title": {"_type": {"_name": "String"}, "_value": "Sub Activity"},
            "activityType": {"_type": {"_name": "String"}, "_value": "com.apple.dt.xctest.activity-type.internal"},
            "uuid": {"_type": {"_name": "String"}, "_value": "sub-activity-uuid-1"},
            "attachments": {"_values": [\(subAttachmentsArray)]},
            "subactivities": {"_values": []},
            "failureSummaryIDs": {"_values": []},
            "expectedFailureIDs": {"_values": []}
        }
        """

        let topActivityJSON = """
        {
            "_type": {"_name": "ActionTestActivitySummary"},
            "title": {"_type": {"_name": "String"}, "_value": "Top Activity"},
            "activityType": {"_type": {"_name": "String"}, "_value": "com.apple.dt.xctest.activity-type.internal"},
            "uuid": {"_type": {"_name": "String"}, "_value": "top-activity-uuid-1"},
            "attachments": {"_values": [\(topAttachmentsArray)]},
            "subactivities": {"_values": [\(subactivityJSON)]},
            "failureSummaryIDs": {"_values": []},
            "expectedFailureIDs": {"_values": []}
        }
        """

        let failureJSON = failureAttachments.isEmpty ? "" : makeFailureSummaryJSON(attachments: failureAttachments)
        let failureArray = failureAttachments.isEmpty ? "" : failureJSON

        return """
        {
            "_type": {"_name": "ActionTestSummary", "_supertype": {"_name": "ActionTestSummaryIdentifiableObject", "_supertype": {"_name": "ActionAbstractTestSummary"}}},
            "name": {"_type": {"_name": "String"}, "_value": "testWithSubactivities()"},
            "testStatus": {"_type": {"_name": "String"}, "_value": "Success"},
            "duration": {"_type": {"_name": "Double"}, "_value": "1.0"},
            "performanceMetrics": {"_values": []},
            "failureSummaries": {"_values": [\(failureArray)]},
            "activitySummaries": {"_values": [\(topActivityJSON)]},
            "expectedFailures": {"_values": []}
        }
        """
    }

    static var allTests = [
        ("testAllAttachmentsReturnsActivityAttachments", testAllAttachmentsReturnsActivityAttachments),
        ("testAllAttachmentsReturnsFailureSummaryAttachments", testAllAttachmentsReturnsFailureSummaryAttachments),
        ("testAllAttachmentsCombinesActivityAndFailureAttachments", testAllAttachmentsCombinesActivityAndFailureAttachments),
        ("testAllAttachmentsReturnsEmptyWhenNoAttachments", testAllAttachmentsReturnsEmptyWhenNoAttachments),
        ("testAllAttachmentsIncludesSubactivityAttachments", testAllAttachmentsIncludesSubactivityAttachments),
        ("testAllAttachmentsIncludesNilPayloadRefAttachments", testAllAttachmentsIncludesNilPayloadRefAttachments),
        ("testExportInitReturnsNilWhenPayloadRefIsNil", testExportInitReturnsNilWhenPayloadRefIsNil),
        ("testExportInitSucceedsWhenPayloadRefExists", testExportInitSucceedsWhenPayloadRefExists),
        ("testExportInitUsesFilenameInOutputPath", testExportInitUsesFilenameInOutputPath),
        ("testExportInitUsesIdentifierWhenFilenameIsNil", testExportInitUsesIdentifierWhenFilenameIsNil),
    ]
}
