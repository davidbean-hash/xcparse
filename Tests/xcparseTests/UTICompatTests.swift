//
//  UTICompatTests.swift
//
//  Tests for cross-platform UTI conformance checking.
//

import XCTest
import XCParseCore

final class UTICompatTests: XCTestCase {

    // MARK: - Identity

    func testIdentityConformance() {
        XCTAssertTrue(utiConforms("public.image", to: "public.image"))
        XCTAssertTrue(utiConforms("public.data", to: "public.data"))
        XCTAssertTrue(utiConforms("public.text", to: "public.text"))
        XCTAssertTrue(utiConforms("public.json", to: "public.json"))
    }

    // MARK: - Image types

    func testImageConformance() {
        let imageUTIs = [
            "public.heic",
            "public.heif",
            "public.png",
            "public.jpeg",
            "com.compuserve.gif",
            "public.tiff",
            "com.microsoft.bmp",
            "public.svg-image",
            "com.apple.icns",
        ]
        for uti in imageUTIs {
            XCTAssertTrue(utiConforms(uti, to: "public.image"),
                          "\(uti) should conform to public.image")
        }
    }

    func testNonImageDoesNotConformToImage() {
        let nonImageUTIs = [
            "public.plain-text",
            "public.json",
            "public.xml",
            "com.adobe.pdf",
            "public.html",
        ]
        for uti in nonImageUTIs {
            XCTAssertFalse(utiConforms(uti, to: "public.image"),
                           "\(uti) should not conform to public.image")
        }
    }

    // MARK: - Text types

    func testPlainTextConformance() {
        XCTAssertTrue(utiConforms("public.plain-text", to: "public.text"))
        XCTAssertTrue(utiConforms("public.utf8-plain-text", to: "public.plain-text"))
        XCTAssertTrue(utiConforms("public.utf16-plain-text", to: "public.plain-text"))
    }

    func testTextSubtypes() {
        XCTAssertTrue(utiConforms("public.html", to: "public.text"))
        XCTAssertTrue(utiConforms("public.json", to: "public.text"))
        XCTAssertTrue(utiConforms("public.xml", to: "public.text"))
    }

    func testTransitivePlainTextToText() {
        XCTAssertTrue(utiConforms("public.utf8-plain-text", to: "public.text"))
        XCTAssertTrue(utiConforms("public.utf16-plain-text", to: "public.text"))
    }

    // MARK: - Data (public.data) hierarchy

    func testDataConformance() {
        XCTAssertTrue(utiConforms("public.image", to: "public.data"))
        XCTAssertTrue(utiConforms("public.text", to: "public.data"))
        XCTAssertTrue(utiConforms("public.json", to: "public.data"))
        XCTAssertTrue(utiConforms("public.xml", to: "public.data"))
    }

    func testTransitiveImageToData() {
        XCTAssertTrue(utiConforms("public.png", to: "public.data"))
        XCTAssertTrue(utiConforms("public.jpeg", to: "public.data"))
        XCTAssertTrue(utiConforms("com.compuserve.gif", to: "public.data"))
    }

    func testTransitiveTextToData() {
        XCTAssertTrue(utiConforms("public.plain-text", to: "public.data"))
        XCTAssertTrue(utiConforms("public.html", to: "public.data"))
    }

    // MARK: - Negative cases

    func testUnknownUTI() {
        XCTAssertFalse(utiConforms("com.example.unknown", to: "public.image"))
        XCTAssertFalse(utiConforms("com.example.unknown", to: "public.data"))
    }

    func testReverseConformanceDoesNotHold() {
        XCTAssertFalse(utiConforms("public.image", to: "public.png"))
        XCTAssertFalse(utiConforms("public.text", to: "public.plain-text"))
        XCTAssertFalse(utiConforms("public.data", to: "public.image"))
    }

    // MARK: - All tests (Linux)

    static var allTests = [
        ("testIdentityConformance", testIdentityConformance),
        ("testImageConformance", testImageConformance),
        ("testNonImageDoesNotConformToImage", testNonImageDoesNotConformToImage),
        ("testPlainTextConformance", testPlainTextConformance),
        ("testTextSubtypes", testTextSubtypes),
        ("testTransitivePlainTextToText", testTransitivePlainTextToText),
        ("testDataConformance", testDataConformance),
        ("testTransitiveImageToData", testTransitiveImageToData),
        ("testTransitiveTextToData", testTransitiveTextToData),
        ("testUnknownUTI", testUnknownUTI),
        ("testReverseConformanceDoesNotHold", testReverseConformanceDoesNotHold),
    ]
}
