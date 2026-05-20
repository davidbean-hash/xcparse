//
//  OriginalNameTests.swift
//  xcparseTests
//
//  Created by Devin on 2026-05-20.
//

import XCTest
import XCParseCore

final class OriginalNameTests: XCTestCase {

    // MARK: - resolveOriginalName Tests

    func testResolveOriginalNameWithNilName() {
        let result = AttachmentNameResolver.resolveOriginalName(
            originalName: nil,
            filename: "Screenshot_ABC123.png",
            payloadId: "ref-001"
        )
        XCTAssertEqual(result, "Screenshot_ABC123.png")
    }

    func testResolveOriginalNameWithNilNameAndFilename() {
        let result = AttachmentNameResolver.resolveOriginalName(
            originalName: nil,
            filename: nil,
            payloadId: "ref-001"
        )
        XCTAssertEqual(result, "ref-001")
    }

    func testResolveOriginalNameAllNil() {
        let result = AttachmentNameResolver.resolveOriginalName(
            originalName: nil,
            filename: nil,
            payloadId: nil
        )
        XCTAssertEqual(result, "attachment")
    }

    func testResolveOriginalNameAppendsExtension() {
        // Name without extension, filename has .png
        let result = AttachmentNameResolver.resolveOriginalName(
            originalName: "Login Screen",
            filename: "Screenshot_ABC123.png",
            payloadId: "ref-001"
        )
        XCTAssertEqual(result, "Login Screen.png")
    }

    func testResolveOriginalNamePreventDoubleExtension() {
        // Name already has .png extension matching filename's .png
        let result = AttachmentNameResolver.resolveOriginalName(
            originalName: "screenshot.png",
            filename: "Screenshot_ABC123.png",
            payloadId: "ref-001"
        )
        XCTAssertEqual(result, "screenshot.png")
    }

    func testResolveOriginalNameCaseInsensitiveExtensionMatch() {
        // Extension check should be case-insensitive
        let result = AttachmentNameResolver.resolveOriginalName(
            originalName: "screenshot.PNG",
            filename: "Screenshot_ABC123.png",
            payloadId: "ref-001"
        )
        XCTAssertEqual(result, "screenshot.PNG")
    }

    func testResolveOriginalNameDifferentExtensions() {
        // Name has .jpg but file is .png - should append .png
        let result = AttachmentNameResolver.resolveOriginalName(
            originalName: "photo.jpg",
            filename: "Screenshot_ABC123.png",
            payloadId: "ref-001"
        )
        XCTAssertEqual(result, "photo.jpg.png")
    }

    func testResolveOriginalNameEmptyFileExtension() {
        // Filename has no extension - should just use original name
        let result = AttachmentNameResolver.resolveOriginalName(
            originalName: "My Attachment",
            filename: "payload_data",
            payloadId: "ref-001"
        )
        XCTAssertEqual(result, "My Attachment")
    }

    func testResolveOriginalNameNilFilename() {
        // No filename to derive extension from - falls back to name
        let result = AttachmentNameResolver.resolveOriginalName(
            originalName: "screenshot",
            filename: nil,
            payloadId: "ref-001"
        )
        XCTAssertEqual(result, "screenshot")
    }

    func testResolveOriginalNameWithSpecialCharacters() {
        let result = AttachmentNameResolver.resolveOriginalName(
            originalName: "Screen (1) - Login",
            filename: "Screenshot_ABC123.png",
            payloadId: "ref-001"
        )
        XCTAssertEqual(result, "Screen (1) - Login.png")
    }

    func testResolveOriginalNameWithDotsInName() {
        // Name has dots but last component isn't a known extension
        let result = AttachmentNameResolver.resolveOriginalName(
            originalName: "v2.0.login",
            filename: "Screenshot_ABC123.png",
            payloadId: "ref-001"
        )
        // "login" != "png" so extension gets appended
        XCTAssertEqual(result, "v2.0.login.png")
    }

    func testResolveOriginalNameWithHEICExtension() {
        let result = AttachmentNameResolver.resolveOriginalName(
            originalName: "screenshot",
            filename: "Screenshot_ABC123.heic",
            payloadId: "ref-001"
        )
        XCTAssertEqual(result, "screenshot.heic")
    }

    // MARK: - deduplicateFilenames Tests

    func testDeduplicateFilenamesNoDuplicates() {
        let names = ["login.png", "dashboard.png", "settings.png"]
        let result = AttachmentNameResolver.deduplicateFilenames(names)
        XCTAssertEqual(result, ["login.png", "dashboard.png", "settings.png"])
    }

    func testDeduplicateFilenamesTwoDuplicates() {
        let names = ["screenshot.png", "screenshot.png"]
        let result = AttachmentNameResolver.deduplicateFilenames(names)
        XCTAssertEqual(result, ["screenshot.png", "screenshot_1.png"])
    }

    func testDeduplicateFilenamesThreeDuplicates() {
        let names = ["screenshot.png", "screenshot.png", "screenshot.png"]
        let result = AttachmentNameResolver.deduplicateFilenames(names)
        XCTAssertEqual(result, ["screenshot.png", "screenshot_1.png", "screenshot_2.png"])
    }

    func testDeduplicateFilenamesMixedDuplicates() {
        let names = ["login.png", "screenshot.png", "login.png", "dashboard.png", "screenshot.png"]
        let result = AttachmentNameResolver.deduplicateFilenames(names)
        XCTAssertEqual(result, ["login.png", "screenshot.png", "login_1.png", "dashboard.png", "screenshot_1.png"])
    }

    func testDeduplicateFilenamesNoExtension() {
        let names = ["attachment", "attachment", "attachment"]
        let result = AttachmentNameResolver.deduplicateFilenames(names)
        XCTAssertEqual(result, ["attachment", "attachment_1", "attachment_2"])
    }

    func testDeduplicateFilenamesDifferentExtensionsSameName() {
        let names = ["screenshot.png", "screenshot.jpg"]
        let result = AttachmentNameResolver.deduplicateFilenames(names)
        XCTAssertEqual(result, ["screenshot.png", "screenshot.jpg"])
    }

    func testDeduplicateFilenamesEmptyArray() {
        let result = AttachmentNameResolver.deduplicateFilenames([])
        XCTAssertEqual(result, [])
    }

    func testDeduplicateFilenamesSingleElement() {
        let result = AttachmentNameResolver.deduplicateFilenames(["test.png"])
        XCTAssertEqual(result, ["test.png"])
    }

    // MARK: - resolveAndDeduplicateNames (Integration) Tests

    func testResolveAndDeduplicateNamesBasic() {
        let attachments: [(originalName: String?, filename: String?, payloadId: String?)] = [
            (originalName: "Login Screen", filename: "Screenshot_001.png", payloadId: "ref-001"),
            (originalName: "Dashboard", filename: "Screenshot_002.png", payloadId: "ref-002"),
        ]
        let result = AttachmentNameResolver.resolveAndDeduplicateNames(attachments: attachments)
        XCTAssertEqual(result, ["Login Screen.png", "Dashboard.png"])
    }

    func testResolveAndDeduplicateNamesDuplicateOriginalNames() {
        let attachments: [(originalName: String?, filename: String?, payloadId: String?)] = [
            (originalName: "screenshot", filename: "Screenshot_001.png", payloadId: "ref-001"),
            (originalName: "screenshot", filename: "Screenshot_002.png", payloadId: "ref-002"),
            (originalName: "screenshot", filename: "Screenshot_003.png", payloadId: "ref-003"),
        ]
        let result = AttachmentNameResolver.resolveAndDeduplicateNames(attachments: attachments)
        XCTAssertEqual(result, ["screenshot.png", "screenshot_1.png", "screenshot_2.png"])
    }

    func testResolveAndDeduplicateNamesWithNilNames() {
        let attachments: [(originalName: String?, filename: String?, payloadId: String?)] = [
            (originalName: nil, filename: "Screenshot_001.png", payloadId: "ref-001"),
            (originalName: nil, filename: "Screenshot_002.png", payloadId: "ref-002"),
        ]
        let result = AttachmentNameResolver.resolveAndDeduplicateNames(attachments: attachments)
        XCTAssertEqual(result, ["Screenshot_001.png", "Screenshot_002.png"])
    }

    func testResolveAndDeduplicateNamesMixedNilAndDuplicate() {
        let attachments: [(originalName: String?, filename: String?, payloadId: String?)] = [
            (originalName: "Login", filename: "Screenshot_001.png", payloadId: "ref-001"),
            (originalName: nil, filename: "Screenshot_002.png", payloadId: "ref-002"),
            (originalName: "Login", filename: "Screenshot_003.png", payloadId: "ref-003"),
        ]
        let result = AttachmentNameResolver.resolveAndDeduplicateNames(attachments: attachments)
        XCTAssertEqual(result, ["Login.png", "Screenshot_002.png", "Login_1.png"])
    }

    func testResolveAndDeduplicateNamesPreventDoubleExtension() {
        let attachments: [(originalName: String?, filename: String?, payloadId: String?)] = [
            (originalName: "screenshot.png", filename: "Screenshot_001.png", payloadId: "ref-001"),
            (originalName: "screenshot.png", filename: "Screenshot_002.png", payloadId: "ref-002"),
        ]
        let result = AttachmentNameResolver.resolveAndDeduplicateNames(attachments: attachments)
        XCTAssertEqual(result, ["screenshot.png", "screenshot_1.png"])
    }

    func testResolveAndDeduplicateNamesAllNilFallsToPayloadId() {
        let attachments: [(originalName: String?, filename: String?, payloadId: String?)] = [
            (originalName: nil, filename: nil, payloadId: "ref-001"),
            (originalName: nil, filename: nil, payloadId: "ref-002"),
        ]
        let result = AttachmentNameResolver.resolveAndDeduplicateNames(attachments: attachments)
        XCTAssertEqual(result, ["ref-001", "ref-002"])
    }

    func testResolveAndDeduplicateNamesAllNilFallsToAttachment() {
        let attachments: [(originalName: String?, filename: String?, payloadId: String?)] = [
            (originalName: nil, filename: nil, payloadId: nil),
            (originalName: nil, filename: nil, payloadId: nil),
        ]
        let result = AttachmentNameResolver.resolveAndDeduplicateNames(attachments: attachments)
        XCTAssertEqual(result, ["attachment", "attachment_1"])
    }

    static var allTests = [
        ("testResolveOriginalNameWithNilName", testResolveOriginalNameWithNilName),
        ("testResolveOriginalNameWithNilNameAndFilename", testResolveOriginalNameWithNilNameAndFilename),
        ("testResolveOriginalNameAllNil", testResolveOriginalNameAllNil),
        ("testResolveOriginalNameAppendsExtension", testResolveOriginalNameAppendsExtension),
        ("testResolveOriginalNamePreventDoubleExtension", testResolveOriginalNamePreventDoubleExtension),
        ("testResolveOriginalNameCaseInsensitiveExtensionMatch", testResolveOriginalNameCaseInsensitiveExtensionMatch),
        ("testResolveOriginalNameDifferentExtensions", testResolveOriginalNameDifferentExtensions),
        ("testResolveOriginalNameEmptyFileExtension", testResolveOriginalNameEmptyFileExtension),
        ("testResolveOriginalNameNilFilename", testResolveOriginalNameNilFilename),
        ("testResolveOriginalNameWithSpecialCharacters", testResolveOriginalNameWithSpecialCharacters),
        ("testResolveOriginalNameWithDotsInName", testResolveOriginalNameWithDotsInName),
        ("testResolveOriginalNameWithHEICExtension", testResolveOriginalNameWithHEICExtension),
        ("testDeduplicateFilenamesNoDuplicates", testDeduplicateFilenamesNoDuplicates),
        ("testDeduplicateFilenamesTwoDuplicates", testDeduplicateFilenamesTwoDuplicates),
        ("testDeduplicateFilenamesThreeDuplicates", testDeduplicateFilenamesThreeDuplicates),
        ("testDeduplicateFilenamesMixedDuplicates", testDeduplicateFilenamesMixedDuplicates),
        ("testDeduplicateFilenamesNoExtension", testDeduplicateFilenamesNoExtension),
        ("testDeduplicateFilenamesDifferentExtensionsSameName", testDeduplicateFilenamesDifferentExtensionsSameName),
        ("testDeduplicateFilenamesEmptyArray", testDeduplicateFilenamesEmptyArray),
        ("testDeduplicateFilenamesSingleElement", testDeduplicateFilenamesSingleElement),
        ("testResolveAndDeduplicateNamesBasic", testResolveAndDeduplicateNamesBasic),
        ("testResolveAndDeduplicateNamesDuplicateOriginalNames", testResolveAndDeduplicateNamesDuplicateOriginalNames),
        ("testResolveAndDeduplicateNamesWithNilNames", testResolveAndDeduplicateNamesWithNilNames),
        ("testResolveAndDeduplicateNamesMixedNilAndDuplicate", testResolveAndDeduplicateNamesMixedNilAndDuplicate),
        ("testResolveAndDeduplicateNamesPreventDoubleExtension", testResolveAndDeduplicateNamesPreventDoubleExtension),
        ("testResolveAndDeduplicateNamesAllNilFallsToPayloadId", testResolveAndDeduplicateNamesAllNilFallsToPayloadId),
        ("testResolveAndDeduplicateNamesAllNilFallsToAttachment", testResolveAndDeduplicateNamesAllNilFallsToAttachment),
    ]
}
