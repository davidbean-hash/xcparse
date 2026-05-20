//
//  UTICompat.swift
//  XCParseCore
//
//  Created for Linux compilation support.
//

import Foundation
#if canImport(CoreServices)
import CoreServices
#endif

public func utiConforms(_ uti: String, to parentUTI: String) -> Bool {
    #if canImport(CoreServices)
    return UTTypeConformsTo(uti as CFString, parentUTI as CFString)
    #else
    if uti == parentUTI { return true }

    let hierarchy: [String: [String]] = [
        "public.data": ["public.image", "public.text", "public.json", "public.xml"],
        "public.image": [
            "public.jpeg", "public.png", "public.heic", "public.heif",
            "public.tiff", "com.compuserve.gif", "public.svg-image",
            "com.apple.icns", "com.microsoft.bmp",
        ],
        "public.text": ["public.plain-text", "public.html", "public.json", "public.xml"],
        "public.plain-text": ["public.utf8-plain-text", "public.utf16-plain-text"],
        "public.json": [],
        "public.xml": [],
    ]

    if let children = hierarchy[parentUTI] {
        if children.contains(uti) { return true }
        for child in children {
            if utiConforms(uti, to: child) { return true }
        }
    }

    return false
    #endif
}
