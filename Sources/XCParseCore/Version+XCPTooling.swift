//
//  Version+XCPTooling.swift
//  XCParseCore
//
//  Created by Alex Botkin on 11/8/19.
//

import Foundation
import TSCUtility

public extension Version {
    static func xcresulttoolCompatibleWithUnicodeExportPath() -> Version {
        return Version(15500, 0, 0)
    }

    static func xcresulttoolWithDeprecatedAPIs() -> Version {
        return Version(23028, 0, 0)
    }

    /// Parses a version string that could be an integer build number (e.g., "23028")
    /// or a semantic version (e.g., "26.0", "26.0.0").
    static func parseVersionString(_ versionString: String) -> Version? {
        let trimmed = versionString.trimmingCharacters(in: .whitespacesAndNewlines)

        if let versionInt = Int(trimmed) {
            return Version(versionInt, 0, 0)
        }

        if let version = Version(string: trimmed) {
            return version
        }

        let dotComponents = trimmed.split(separator: ".")
        if dotComponents.count == 2,
           let major = Int(dotComponents[0]),
           let minor = Int(dotComponents[1]) {
            return Version(major, minor, 0)
        }

        return nil
    }

    /// Parses the xcresulttool version from its command output string.
    static func parseXCResultToolVersion(from output: String) -> Version? {
        let components = output.components(separatedBy: CharacterSet(charactersIn: ",\n"))
        for string in components {
            let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedString.hasPrefix("xcresulttool version ") {
                let versionString = trimmedString.replacingOccurrences(of: "xcresulttool version ", with: "")
                return parseVersionString(versionString)
            }
        }
        return nil
    }

    static func xcresulttool() -> Version? {
        guard let xcresulttoolVersionResult = XCResultToolCommand.Version().run() else {
            return nil
        }
        do {
            let xcresultVersionString = try xcresulttoolVersionResult.utf8Output()
            return parseXCResultToolVersion(from: xcresultVersionString)
        } catch {
            print("Failed to parse xcresulttool version with error: \(error)")
            return nil
        }
    }
}
