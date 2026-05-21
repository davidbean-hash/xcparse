//
//  ScreenshotCommandUTITests.swift
//  
//
//  Created by Alexander Botkin on 6/30/20.
//

import XCTest
import class Foundation.Bundle

final class ScreenshotCommandUTITests: XCTestCase {
    func testScreenshotUTIFilter() throws {
        let imageUTIs = [
            "public.heic",
            "public.heif",
            "public.png",
            "public.jpeg",
            "com.compuserve.gif",
        ]

        for UTI in imageUTIs {
            let conformsAsImage = UTTypeConformsTo(UTI as CFString, "public.image" as CFString)
            XCTAssertTrue(conformsAsImage, "\(UTI) does not conform to public.image UTI. Screenshots command will not extract")
        }

        let nonImageUTIs = [
            "public.plain-text",
            "com.adobe.pdf",
        ]

        for UTI in nonImageUTIs {
            let conformsAsImage = UTTypeConformsTo(UTI as CFString, "public.image" as CFString)
            XCTAssertFalse(conformsAsImage, "\(UTI) unexpectedly conforms to public.image UTI. Screenshots command will extract this")
        }
    }

    func testAttachmentsCommandIncludesNonImageUTIs() throws {
        let nonImageUTIs = [
            "public.json",
            "public.plain-text",
            "com.adobe.pdf",
            "public.data",
        ]

        for UTI in nonImageUTIs {
            let conformsAsImage = UTTypeConformsTo(UTI as CFString, "public.image" as CFString)
            XCTAssertFalse(conformsAsImage, "\(UTI) conforms to public.image — the screenshots command would extract it, but the attachments command is needed for these types")
        }

        let allUTIs = [
            "public.heic",
            "public.png",
            "public.jpeg",
            "public.json",
            "public.plain-text",
            "com.adobe.pdf",
            "public.data",
        ]

        for UTI in allUTIs {
            // The attachments command's default filter should accept all UTIs
            let defaultAttachmentFilter: (String) -> Bool = { _ in return true }
            XCTAssertTrue(defaultAttachmentFilter(UTI), "\(UTI) should be accepted by the default attachments command filter")
        }
    }

    static var allTests = [
        ("testScreenshotUTIFilter", testScreenshotUTIFilter),
        ("testAttachmentsCommandIncludesNonImageUTIs", testAttachmentsCommandIncludesNonImageUTIs),
    ]
}
