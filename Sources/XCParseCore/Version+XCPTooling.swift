//
//  Version+XCPTooling.swift
//  XCParseCore
//
//  Created by Alex Botkin on 11/8/19.
//

import Foundation

#if os(macOS)

public struct XCPVersion: Comparable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(_ major: Int, _ minor: Int, _ patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    public init?(string: String) {
        let parts = string.split(separator: ".").compactMap { Int($0) }
        guard !parts.isEmpty else { return nil }
        self.major = parts[0]
        self.minor = parts.count > 1 ? parts[1] : 0
        self.patch = parts.count > 2 ? parts[2] : 0
    }

    public static func < (lhs: XCPVersion, rhs: XCPVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}

public extension XCPVersion {
    static func xcresulttoolCompatibleWithUnicodeExportPath() -> XCPVersion {
        return XCPVersion(15500, 0, 0)
    }

    static func xcresulttoolWithDeprecatedAPIs() -> XCPVersion {
        return XCPVersion(23028, 0, 0)
    }

    static func xcresulttool() -> XCPVersion? {
        guard let xcresulttoolVersionResult = XCResultToolCommand.Version().run() else {
            return nil
        }
        do {
            let xcresultVersionString = try xcresulttoolVersionResult.utf8Output()

            let components = xcresultVersionString.components(separatedBy: CharacterSet(charactersIn: ",\n"))
            for string in components {
                let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedString.hasPrefix("xcresulttool version ") {
                    let xcresulttoolVersionString = trimmedString.replacingOccurrences(of: "xcresulttool version ", with: "")
                    var xcresulttoolVersion: XCPVersion?

                    if let xcresulttoolVersionInt = Int(xcresulttoolVersionString) {
                        xcresulttoolVersion = XCPVersion(xcresulttoolVersionInt, 0, 0)
                    } else {
                        xcresulttoolVersion = XCPVersion(string: xcresulttoolVersionString)
                    }

                    return xcresulttoolVersion
                }
            }

            return nil
        } catch {
            print("Failed to parse xcresulttool version with error: \(error)")
            return nil
        }
    }
}

#endif
