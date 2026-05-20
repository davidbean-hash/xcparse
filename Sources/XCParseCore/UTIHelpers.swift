//
//  UTIHelpers.swift
//  XCParseCore
//
//  Provides a fallback UTI conformance check for systems where
//  CoreServices UTTypeConformsTo may not be available (e.g. Linux).
//

import Foundation

#if canImport(CoreServices)
import CoreServices
#endif

/// Known UTI conformance hierarchy (parent types for common UTIs)
private let utiConformanceMap: [String: Set<String>] = [
    "public.png": ["public.image", "public.data", "public.content", "public.item"],
    "public.jpeg": ["public.image", "public.data", "public.content", "public.item"],
    "public.heic": ["public.image", "public.data", "public.content", "public.item"],
    "public.tiff": ["public.image", "public.data", "public.content", "public.item"],
    "com.compuserve.gif": ["public.image", "public.data", "public.content", "public.item"],
    "public.image": ["public.data", "public.content", "public.item"],
    "public.json": ["public.text", "public.data", "public.content", "public.item"],
    "public.plain-text": ["public.text", "public.data", "public.content", "public.item"],
    "public.xml": ["public.text", "public.data", "public.content", "public.item"],
    "public.text": ["public.data", "public.content", "public.item"],
    "public.data": ["public.content", "public.item"],
    "public.content": ["public.item"],
]

/// Checks whether a UTI conforms to a parent UTI.
/// Uses CoreServices on macOS, falls back to a built-in conformance map otherwise.
public func xcparseUTIConforms(_ uti: String, toUTI parentUTI: String) -> Bool {
    if uti == parentUTI {
        return true
    }

    #if canImport(CoreServices)
    if UTTypeConformsTo(uti as CFString, parentUTI as CFString) {
        return true
    }
    #endif

    // Fallback: check our built-in conformance map
    if let parents = utiConformanceMap[uti], parents.contains(parentUTI) {
        return true
    }

    // Walk up the hierarchy
    if let parents = utiConformanceMap[uti] {
        for parent in parents {
            if xcparseUTIConforms(parent, toUTI: parentUTI) {
                return true
            }
        }
    }

    return false
}
