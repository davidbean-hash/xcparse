//
//  ScreenshotCommandUTITests.swift
//  
//
//  Created by Alexander Botkin on 6/30/20.
//

import XCTest
import class Foundation.Bundle
#if canImport(CoreServices)
import CoreServices
#endif

final class ScreenshotCommandUTITests: XCTestCase {

    /// Cross-platform UTI conformance check for tests.
    private func checkUTIConforms(_ uti: String, toType parentType: String) -> Bool {
        #if canImport(CoreServices)
        return UTTypeConformsTo(uti as CFString, parentType as CFString)
        #else
        if uti == parentType { return true }
        return testUTIAncestors(of: uti).contains(parentType)
        #endif
    }

    #if !canImport(CoreServices)
    private func testUTIAncestors(of uti: String) -> Set<String> {
        let parentMap: [String: [String]] = [
            "public.png":           ["public.image"],
            "public.jpeg":          ["public.image"],
            "public.heif":          ["public.image"],
            "public.heic":          ["public.image"],
            "com.compuserve.gif":   ["public.image"],
            "public.image":         ["public.content", "public.data"],
            "public.plain-text":    ["public.text"],
            "public.text":          ["public.content", "public.data"],
            "public.pdf":           ["public.composite-content", "public.data"],
            "public.data":          ["public.item"],
            "public.content":       ["public.item"],
            "public.item":          [],
        ]
        var visited = Set<String>()
        var queue = [uti]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            guard !visited.contains(current) else { continue }
            visited.insert(current)
            if let parents = parentMap[current] {
                queue.append(contentsOf: parents)
            }
        }
        return visited
    }
    #endif

    func testScreenshotUTIFilter() throws {
        let imageUTIs = [
            "public.heic",
            "public.heif",
            "public.png",
            "public.jpeg",
            "com.compuserve.gif",
        ]

        for UTI in imageUTIs {
            let conformsAsImage = checkUTIConforms(UTI, toType: "public.image")
            XCTAssertTrue(conformsAsImage, "\(UTI) does not conform to public.image UTI. Screenshots command will not extract")
        }

        let nonImageUTIs = [
            "public.plain-text",
            "com.adobe.pdf",
        ]

        for UTI in nonImageUTIs {
            let conformsAsImage = checkUTIConforms(UTI, toType: "public.image")
            XCTAssertFalse(conformsAsImage, "\(UTI) unexpectedly conforms to public.image UTI. Screenshots command will extract this")
        }
    }

    static var allTests = [
        ("testScreenshotUTIFilter", testScreenshotUTIFilter),
    ]
}
