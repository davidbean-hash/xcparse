//
//  ActivityTypeFilterTests.swift
//  xcparseTests
//
//  Tests for the BFS traversal of nested activity attachments
//  to verify the fix for https://github.com/ChargePoint/xcparse/issues/79
//

import XCTest
@testable import xcparse
import XCParseCore

final class ActivityTypeFilterTests: XCTestCase {

    // MARK: - JSON Helpers

    private static func stringValue(_ key: String, _ value: String) -> String {
        return "\"\(key)\": {\"_type\": {\"_name\": \"String\"}, \"_value\": \"\(value)\"}"
    }

    private static func intValue(_ key: String, _ value: Int) -> String {
        return "\"\(key)\": {\"_type\": {\"_name\": \"Int\"}, \"_value\": \"\(value)\"}"
    }

    private static func attachmentJSON(filename: String, uti: String = "public.png", identifier: Int = 0) -> String {
        return """
        {
            "_type": {"_name": "ActionTestAttachment"},
            \(stringValue("uniformTypeIdentifier", uti)),
            \(stringValue("name", filename)),
            \(stringValue("lifetime", "keepAlways")),
            \(intValue("inActivityIdentifier", identifier)),
            \(stringValue("filename", filename)),
            \(intValue("payloadSize", 1024))
        }
        """
    }

    private static func activityJSON(
        title: String,
        activityType: String,
        uuid: String,
        attachments: [String] = [],
        subactivities: [String] = []
    ) -> String {
        var parts: [String] = [
            "\"_type\": {\"_name\": \"ActionTestActivitySummary\"}",
            stringValue("title", title),
            stringValue("activityType", activityType),
            stringValue("uuid", uuid)
        ]

        if !attachments.isEmpty {
            parts.append("\"attachments\": {\"_values\": [\(attachments.joined(separator: ","))]}")
        }

        if !subactivities.isEmpty {
            parts.append("\"subactivities\": {\"_values\": [\(subactivities.joined(separator: ","))]}")
        }

        return "{\(parts.joined(separator: ","))}"
    }

    private static func decodeActivity(json: String) -> ActionTestActivitySummary? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ActionTestActivitySummary.self, from: data)
    }

    private static let failureType = ActionTestActivityType.testAssertionFailure.rawValue
    private static let internalType = ActionTestActivityType.internal.rawValue
    private static let userCreatedType = ActionTestActivityType.userCreated.rawValue
    private static let attachmentContainerType = ActionTestActivityType.attachmentContainer.rawValue

    private func failureFilter(_ activity: ActionTestActivitySummary) -> Bool {
        return activity.activityType == Self.failureType
    }

    private func acceptAllAttachments(_ attachment: ActionTestAttachment) -> Bool {
        return true
    }

    private func pngOnlyFilter(_ attachment: ActionTestAttachment) -> Bool {
        return attachment.uniformTypeIdentifier == "public.png"
    }

    // MARK: - Tests

    func testNoActivities() {
        let result = XCPParser.collectFilteredAttachments(
            from: [],
            activityFilter: failureFilter,
            attachmentFilter: acceptAllAttachments
        )
        XCTAssertEqual(result.count, 0)
    }

    func testSingleMatchingActivityWithAttachment() {
        let json = Self.activityJSON(
            title: "Assertion Failure",
            activityType: Self.failureType,
            uuid: "uuid-1",
            attachments: [Self.attachmentJSON(filename: "failure_screenshot.png")]
        )
        guard let activity = Self.decodeActivity(json: json) else {
            XCTFail("Failed to decode activity")
            return
        }

        let result = XCPParser.collectFilteredAttachments(
            from: [activity],
            activityFilter: failureFilter,
            attachmentFilter: acceptAllAttachments
        )
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.filename, "failure_screenshot.png")
    }

    func testSingleNonMatchingActivitySkipped() {
        let json = Self.activityJSON(
            title: "Internal Activity",
            activityType: Self.internalType,
            uuid: "uuid-1",
            attachments: [Self.attachmentJSON(filename: "internal_screenshot.png")]
        )
        guard let activity = Self.decodeActivity(json: json) else {
            XCTFail("Failed to decode activity")
            return
        }

        let result = XCPParser.collectFilteredAttachments(
            from: [activity],
            activityFilter: failureFilter,
            attachmentFilter: acceptAllAttachments
        )
        XCTAssertEqual(result.count, 0)
    }

    func testNestedDescendantAttachmentsCollected() {
        // Simulates Xcode 14.2+ structure: failure screenshot attached to a child
        // activity nested under testAssertionFailure
        let childJSON = Self.activityJSON(
            title: "Nested Failure Detail",
            activityType: Self.attachmentContainerType,
            uuid: "uuid-child",
            attachments: [Self.attachmentJSON(filename: "nested_failure_screenshot.png")]
        )
        let parentJSON = Self.activityJSON(
            title: "Assertion Failure",
            activityType: Self.failureType,
            uuid: "uuid-parent",
            attachments: [Self.attachmentJSON(filename: "parent_screenshot.png")],
            subactivities: [childJSON]
        )
        guard let parent = Self.decodeActivity(json: parentJSON) else {
            XCTFail("Failed to decode activity")
            return
        }

        let result = XCPParser.collectFilteredAttachments(
            from: [parent],
            activityFilter: failureFilter,
            attachmentFilter: acceptAllAttachments
        )
        XCTAssertEqual(result.count, 2)
        let filenames = result.compactMap { $0.filename }
        XCTAssertTrue(filenames.contains("parent_screenshot.png"))
        XCTAssertTrue(filenames.contains("nested_failure_screenshot.png"))
    }

    func testDeeplyNestedAttachmentsCollected() {
        // Three levels: grandparent -> child -> grandchild
        let grandchildJSON = Self.activityJSON(
            title: "Grandchild",
            activityType: Self.attachmentContainerType,
            uuid: "uuid-grandchild",
            attachments: [Self.attachmentJSON(filename: "deep_screenshot.png")]
        )
        let childJSON = Self.activityJSON(
            title: "Child",
            activityType: Self.attachmentContainerType,
            uuid: "uuid-child",
            subactivities: [grandchildJSON]
        )
        let parentJSON = Self.activityJSON(
            title: "Assertion Failure",
            activityType: Self.failureType,
            uuid: "uuid-parent",
            attachments: [Self.attachmentJSON(filename: "top_screenshot.png")],
            subactivities: [childJSON]
        )
        guard let parent = Self.decodeActivity(json: parentJSON) else {
            XCTFail("Failed to decode activity")
            return
        }

        let result = XCPParser.collectFilteredAttachments(
            from: [parent],
            activityFilter: failureFilter,
            attachmentFilter: acceptAllAttachments
        )
        XCTAssertEqual(result.count, 2)
        let filenames = result.compactMap { $0.filename }
        XCTAssertTrue(filenames.contains("top_screenshot.png"))
        XCTAssertTrue(filenames.contains("deep_screenshot.png"))
    }

    func testDuplicateActivitiesInFlattenedList() {
        // Simulates what happens when allChildActivitySummaries() flattens the tree:
        // both the parent and child appear in the list. If the child also matches the
        // filter, the visited set should prevent duplicate attachment exports.
        let childJSON = Self.activityJSON(
            title: "Nested Failure",
            activityType: Self.failureType,
            uuid: "uuid-child",
            attachments: [Self.attachmentJSON(filename: "child_screenshot.png")]
        )
        let parentJSON = Self.activityJSON(
            title: "Top Failure",
            activityType: Self.failureType,
            uuid: "uuid-parent",
            subactivities: [childJSON]
        )
        guard let parent = Self.decodeActivity(json: parentJSON) else {
            XCTFail("Failed to decode parent activity")
            return
        }
        let child = parent.subactivities[0]

        // Simulate flattened list: [parent, child] — both match the filter
        let result = XCPParser.collectFilteredAttachments(
            from: [parent, child],
            activityFilter: failureFilter,
            attachmentFilter: acceptAllAttachments
        )

        // Child's attachment should appear exactly once despite being in the list twice
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.filename, "child_screenshot.png")
    }

    func testAttachmentFilterApplied() {
        let json = Self.activityJSON(
            title: "Assertion Failure",
            activityType: Self.failureType,
            uuid: "uuid-1",
            attachments: [
                Self.attachmentJSON(filename: "screenshot.png", uti: "public.png"),
                Self.attachmentJSON(filename: "log.txt", uti: "public.plain-text", identifier: 1)
            ]
        )
        guard let activity = Self.decodeActivity(json: json) else {
            XCTFail("Failed to decode activity")
            return
        }

        let result = XCPParser.collectFilteredAttachments(
            from: [activity],
            activityFilter: failureFilter,
            attachmentFilter: pngOnlyFilter
        )
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.filename, "screenshot.png")
    }

    func testAcceptAllActivityFilter() {
        let failureJSON = Self.activityJSON(
            title: "Failure",
            activityType: Self.failureType,
            uuid: "uuid-1",
            attachments: [Self.attachmentJSON(filename: "failure.png")]
        )
        let internalJSON = Self.activityJSON(
            title: "Internal",
            activityType: Self.internalType,
            uuid: "uuid-2",
            attachments: [Self.attachmentJSON(filename: "internal.png", identifier: 1)]
        )
        guard let failure = Self.decodeActivity(json: failureJSON),
              let internalActivity = Self.decodeActivity(json: internalJSON) else {
            XCTFail("Failed to decode activities")
            return
        }

        let result = XCPParser.collectFilteredAttachments(
            from: [failure, internalActivity],
            activityFilter: { _ in true },
            attachmentFilter: acceptAllAttachments
        )
        XCTAssertEqual(result.count, 2)
    }

    func testMultipleMatchingActivitiesWithSeparateSubtrees() {
        let child1JSON = Self.activityJSON(
            title: "Child 1",
            activityType: Self.attachmentContainerType,
            uuid: "uuid-child1",
            attachments: [Self.attachmentJSON(filename: "child1_screenshot.png")]
        )
        let parent1JSON = Self.activityJSON(
            title: "Failure 1",
            activityType: Self.failureType,
            uuid: "uuid-parent1",
            subactivities: [child1JSON]
        )
        let child2JSON = Self.activityJSON(
            title: "Child 2",
            activityType: Self.attachmentContainerType,
            uuid: "uuid-child2",
            attachments: [Self.attachmentJSON(filename: "child2_screenshot.png")]
        )
        let parent2JSON = Self.activityJSON(
            title: "Failure 2",
            activityType: Self.failureType,
            uuid: "uuid-parent2",
            subactivities: [child2JSON]
        )
        guard let parent1 = Self.decodeActivity(json: parent1JSON),
              let parent2 = Self.decodeActivity(json: parent2JSON) else {
            XCTFail("Failed to decode activities")
            return
        }

        let result = XCPParser.collectFilteredAttachments(
            from: [parent1, parent2],
            activityFilter: failureFilter,
            attachmentFilter: acceptAllAttachments
        )
        XCTAssertEqual(result.count, 2)
        let filenames = result.compactMap { $0.filename }
        XCTAssertTrue(filenames.contains("child1_screenshot.png"))
        XCTAssertTrue(filenames.contains("child2_screenshot.png"))
    }

    func testActivitiesWithNoAttachments() {
        let json = Self.activityJSON(
            title: "Empty Failure",
            activityType: Self.failureType,
            uuid: "uuid-1"
        )
        guard let activity = Self.decodeActivity(json: json) else {
            XCTFail("Failed to decode activity")
            return
        }

        let result = XCPParser.collectFilteredAttachments(
            from: [activity],
            activityFilter: failureFilter,
            attachmentFilter: acceptAllAttachments
        )
        XCTAssertEqual(result.count, 0)
    }

    func testAttachmentOrderPreserved() {
        // Attachments should be collected in BFS order: parent first, then children
        let childJSON = Self.activityJSON(
            title: "Child",
            activityType: Self.attachmentContainerType,
            uuid: "uuid-child",
            attachments: [Self.attachmentJSON(filename: "second.png", identifier: 1)]
        )
        let parentJSON = Self.activityJSON(
            title: "Failure",
            activityType: Self.failureType,
            uuid: "uuid-parent",
            attachments: [Self.attachmentJSON(filename: "first.png")],
            subactivities: [childJSON]
        )
        guard let parent = Self.decodeActivity(json: parentJSON) else {
            XCTFail("Failed to decode activity")
            return
        }

        let result = XCPParser.collectFilteredAttachments(
            from: [parent],
            activityFilter: failureFilter,
            attachmentFilter: acceptAllAttachments
        )
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].filename, "first.png")
        XCTAssertEqual(result[1].filename, "second.png")
    }

    static var allTests = [
        ("testNoActivities", testNoActivities),
        ("testSingleMatchingActivityWithAttachment", testSingleMatchingActivityWithAttachment),
        ("testSingleNonMatchingActivitySkipped", testSingleNonMatchingActivitySkipped),
        ("testNestedDescendantAttachmentsCollected", testNestedDescendantAttachmentsCollected),
        ("testDeeplyNestedAttachmentsCollected", testDeeplyNestedAttachmentsCollected),
        ("testDuplicateActivitiesInFlattenedList", testDuplicateActivitiesInFlattenedList),
        ("testAttachmentFilterApplied", testAttachmentFilterApplied),
        ("testAcceptAllActivityFilter", testAcceptAllActivityFilter),
        ("testMultipleMatchingActivitiesWithSeparateSubtrees", testMultipleMatchingActivitiesWithSeparateSubtrees),
        ("testActivitiesWithNoAttachments", testActivitiesWithNoAttachments),
        ("testAttachmentOrderPreserved", testAttachmentOrderPreserved),
    ]
}
