//
//  UTICompat.swift
//  xcparse
//
//  Cross-platform UTI conformance checking.
//  On macOS this delegates to CoreServices; on Linux it uses a static lookup table.
//

import Foundation
#if canImport(CoreServices)
import CoreServices
#endif

/// Checks whether the UTI `uti` conforms to (is a subtype of) `parentType`.
func utiConforms(_ uti: String, toType parentType: String) -> Bool {
    #if canImport(CoreServices)
    return UTTypeConformsTo(uti as CFString, parentType as CFString)
    #else
    if uti == parentType {
        return true
    }
    return utiAncestors(of: uti).contains(parentType)
    #endif
}

#if !canImport(CoreServices)
/// Walks the UTI hierarchy and collects every ancestor of `uti`.
private func utiAncestors(of uti: String) -> Set<String> {
    var visited = Set<String>()
    var queue = [uti]
    while !queue.isEmpty {
        let current = queue.removeFirst()
        guard !visited.contains(current) else { continue }
        visited.insert(current)
        if let parents = utiParentMap[current] {
            queue.append(contentsOf: parents)
        }
    }
    return visited
}

/// Static mapping of common UTIs to their parent types.
/// Covers the types xcparse actually encounters in xcresult bundles.
private let utiParentMap: [String: [String]] = [
    // Images
    "public.png":                  ["public.image"],
    "public.jpeg":                 ["public.image"],
    "public.tiff":                 ["public.image"],
    "com.compuserve.gif":          ["public.image"],
    "public.heif":                 ["public.image"],
    "public.heic":                 ["public.image"],
    "com.apple.icns":              ["public.image"],
    "public.svg-image":            ["public.image"],
    "com.microsoft.bmp":           ["public.image"],
    "public.image":                ["public.content", "public.data"],

    // Text
    "public.plain-text":           ["public.text"],
    "public.utf8-plain-text":      ["public.plain-text"],
    "public.utf16-plain-text":     ["public.plain-text"],
    "public.rtf":                  ["public.text"],
    "public.html":                 ["public.text"],
    "public.xml":                  ["public.text"],
    "public.json":                 ["public.text"],
    "public.yaml":                 ["public.text"],
    "public.source-code":          ["public.plain-text"],
    "public.swift-source":         ["public.source-code"],
    "public.c-source":             ["public.source-code"],
    "public.objective-c-source":   ["public.source-code"],
    "public.c-plus-plus-source":   ["public.source-code"],
    "public.c-header":             ["public.source-code"],
    "public.text":                 ["public.content", "public.data"],

    // Data / content
    "public.data":                 ["public.item"],
    "public.content":              ["public.item"],
    "public.item":                 [],

    // Composites
    "public.composite-content":    ["public.content"],
    "public.pdf":                  ["public.composite-content", "public.data"],

    // Audio / Video
    "public.audio":                ["public.content", "public.data"],
    "public.video":                ["public.content", "public.data"],
    "public.movie":                ["public.content", "public.data"],
    "public.mpeg-4":               ["public.movie"],
    "public.mpeg-4-audio":         ["public.audio"],
    "com.apple.quicktime-movie":   ["public.movie"],

    // Archives
    "public.archive":              ["public.data"],
    "public.zip-archive":          ["public.archive"],
    "org.gnu.gnu-tar-archive":     ["public.archive"],

    // Misc Apple types that may appear in xcresult bundles
    "com.apple.property-list":     ["public.data"],
    "com.apple.crashreport":       ["public.plain-text"],
    "com.apple.log":               ["public.plain-text"],
]
#endif
