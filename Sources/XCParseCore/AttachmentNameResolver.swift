//
//  AttachmentNameResolver.swift
//  XCParseCore
//
//  Created by Devin on 2026-05-20.
//  Copyright © 2026 ChargePoint, Inc. All rights reserved.
//

import Foundation

public struct AttachmentNameResolver {

    /// Resolves the filename for an attachment when using original names.
    /// - Parameters:
    ///   - originalName: The human-readable name from test code (attachment.name)
    ///   - filename: The system-generated filename (attachment.filename)
    ///   - payloadId: The payload reference ID (attachment.payloadRef?.id)
    /// - Returns: The resolved filename preserving the correct extension
    public static func resolveOriginalName(originalName: String?, filename: String?, payloadId: String?) -> String {
        let baseName = originalName ?? filename ?? payloadId ?? "attachment"
        let fileExtension = (filename as NSString?)?.pathExtension ?? ""
        let nameExtension = (baseName as NSString).pathExtension

        if !fileExtension.isEmpty && nameExtension.lowercased() != fileExtension.lowercased() {
            return (baseName as NSString).appendingPathExtension(fileExtension) ?? baseName
        } else {
            return baseName
        }
    }

    /// Deduplicates an array of filenames by appending _N suffixes for duplicates.
    /// - Parameter names: Array of candidate filenames
    /// - Returns: Array of unique filenames in the same order
    public static func deduplicateFilenames(_ names: [String]) -> [String] {
        var usedNames: [String: Int] = [:]
        var result: [String] = []

        for name in names {
            let count = usedNames[name, default: 0]
            usedNames[name] = count + 1
            if count > 0 {
                let nameWithoutExt = (name as NSString).deletingPathExtension
                let ext = (name as NSString).pathExtension
                if !ext.isEmpty {
                    result.append("\(nameWithoutExt)_\(count).\(ext)")
                } else {
                    result.append("\(nameWithoutExt)_\(count)")
                }
            } else {
                result.append(name)
            }
        }

        return result
    }

    /// Resolves and deduplicates filenames for a batch of attachments.
    /// - Parameter attachments: Array of tuples with (originalName, filename, payloadId)
    /// - Returns: Array of unique, resolved filenames
    public static func resolveAndDeduplicateNames(attachments: [(originalName: String?, filename: String?, payloadId: String?)]) -> [String] {
        let resolved = attachments.map { resolveOriginalName(originalName: $0.originalName, filename: $0.filename, payloadId: $0.payloadId) }
        return deduplicateFilenames(resolved)
    }
}
