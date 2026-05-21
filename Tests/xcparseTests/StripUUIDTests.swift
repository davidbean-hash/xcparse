//
//  StripUUIDTests.swift
//
//  Created for xcparse issue #42: Option to remove UUID from image filenames.
//

import XCTest
import Foundation
@testable import xcparse

final class StripUUIDTests: XCTestCase {

    // MARK: - filenameByStrippingUUID Tests

    func testStripsUUIDFromTypicalScreenshotFilename() {
        let input = "Screenshot_1_BC641069-A876-42D7-AD9E-54D7CB3B984D.heic"
        let result = XCPParser.filenameByStrippingUUID(from: input)
        XCTAssertEqual(result, "Screenshot_1.heic")
    }

    func testStripsUUIDFromPNGFilename() {
        let input = "Screenshot_2_AABBCCDD-1234-5678-9ABC-DEF012345678.png"
        let result = XCPParser.filenameByStrippingUUID(from: input)
        XCTAssertEqual(result, "Screenshot_2.png")
    }

    func testStripsLowercaseUUID() {
        let input = "Screenshot_1_bc641069-a876-42d7-ad9e-54d7cb3b984d.heic"
        let result = XCPParser.filenameByStrippingUUID(from: input)
        XCTAssertEqual(result, "Screenshot_1.heic")
    }

    func testStripsMultipleUUIDs() {
        let input = "Screenshot_BC641069-A876-42D7-AD9E-54D7CB3B984D_AABBCCDD-1234-5678-9ABC-DEF012345678.heic"
        let result = XCPParser.filenameByStrippingUUID(from: input)
        XCTAssertEqual(result, "Screenshot.heic")
    }

    func testNoUUIDLeavesFilenameUnchanged() {
        let input = "Screenshot_1.heic"
        let result = XCPParser.filenameByStrippingUUID(from: input)
        XCTAssertEqual(result, "Screenshot_1.heic")
    }

    func testNoExtensionStripsUUID() {
        let input = "Screenshot_1_BC641069-A876-42D7-AD9E-54D7CB3B984D"
        let result = XCPParser.filenameByStrippingUUID(from: input)
        XCTAssertEqual(result, "Screenshot_1")
    }

    func testFilenameIsOnlyUUIDReturnsOriginal() {
        // When stripping the UUID would leave an empty name, return original
        let input = "_BC641069-A876-42D7-AD9E-54D7CB3B984D.heic"
        let result = XCPParser.filenameByStrippingUUID(from: input)
        XCTAssertEqual(result, "_BC641069-A876-42D7-AD9E-54D7CB3B984D.heic")
    }

    func testFilenameWithNoExtensionOnlyUUIDReturnsOriginal() {
        let input = "_BC641069-A876-42D7-AD9E-54D7CB3B984D"
        let result = XCPParser.filenameByStrippingUUID(from: input)
        // Stripped name is empty, so original is returned
        XCTAssertEqual(result, "_BC641069-A876-42D7-AD9E-54D7CB3B984D")
    }

    func testDoesNotStripPartialUUID() {
        let input = "Screenshot_1_BC641069-A876-42D7.heic"
        let result = XCPParser.filenameByStrippingUUID(from: input)
        XCTAssertEqual(result, "Screenshot_1_BC641069-A876-42D7.heic")
    }

    func testPreservesJPEGExtension() {
        let input = "Attachment_1_AABBCCDD-1234-5678-9ABC-DEF012345678.jpeg"
        let result = XCPParser.filenameByStrippingUUID(from: input)
        XCTAssertEqual(result, "Attachment_1.jpeg")
    }

    func testUUIDAtStartOfNameWithPrefix() {
        let input = "test_00000000-0000-0000-0000-000000000000.png"
        let result = XCPParser.filenameByStrippingUUID(from: input)
        XCTAssertEqual(result, "test.png")
    }

    static var allTests = [
        ("testStripsUUIDFromTypicalScreenshotFilename", testStripsUUIDFromTypicalScreenshotFilename),
        ("testStripsUUIDFromPNGFilename", testStripsUUIDFromPNGFilename),
        ("testStripsLowercaseUUID", testStripsLowercaseUUID),
        ("testStripsMultipleUUIDs", testStripsMultipleUUIDs),
        ("testNoUUIDLeavesFilenameUnchanged", testNoUUIDLeavesFilenameUnchanged),
        ("testNoExtensionStripsUUID", testNoExtensionStripsUUID),
        ("testFilenameIsOnlyUUIDReturnsOriginal", testFilenameIsOnlyUUIDReturnsOriginal),
        ("testFilenameWithNoExtensionOnlyUUIDReturnsOriginal", testFilenameWithNoExtensionOnlyUUIDReturnsOriginal),
        ("testDoesNotStripPartialUUID", testDoesNotStripPartialUUID),
        ("testPreservesJPEGExtension", testPreservesJPEGExtension),
        ("testUUIDAtStartOfNameWithPrefix", testUUIDAtStartOfNameWithPrefix),
    ]
}
