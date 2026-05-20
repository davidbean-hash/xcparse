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

    static func parseXcresulttoolVersionOutput(_ xcresultVersionString: String) -> Version? {
        let components = xcresultVersionString.components(separatedBy: CharacterSet(charactersIn: ",\n"))
        for string in components {
            let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedString.hasPrefix("xcresulttool version ") {
                let xcresulttoolVersionString = trimmedString.replacingOccurrences(of: "xcresulttool version ", with: "")

                if let xcresulttoolVersionInt = Int(xcresulttoolVersionString) {
                    return Version(xcresulttoolVersionInt, 0, 0)
                }

                if let parsedVersion = Version(string: xcresulttoolVersionString) {
                    return parsedVersion
                }

                let dotComponents = xcresulttoolVersionString.components(separatedBy: ".")
                if let majorString = dotComponents.first, let major = Int(majorString) {
                    let minor = dotComponents.count > 1 ? Int(dotComponents[1]) ?? 0 : 0
                    let patch = dotComponents.count > 2 ? Int(dotComponents[2]) ?? 0 : 0
                    return Version(major, minor, patch)
                }

                return nil
            }
        }

        // Fallback: scan for any "version X.Y.Z" or "version X" pattern
        guard let versionPattern = try? NSRegularExpression(pattern: #"version\s+(\d+(?:\.\d+)*)"#, options: .caseInsensitive) else {
            return nil
        }
        let fullOutput = xcresultVersionString.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = versionPattern.firstMatch(in: fullOutput, range: NSRange(fullOutput.startIndex..., in: fullOutput)),
           let versionRange = Range(match.range(at: 1), in: fullOutput) {
            let versionString = String(fullOutput[versionRange])

            if let versionInt = Int(versionString) {
                return Version(versionInt, 0, 0)
            }

            if let parsedVersion = Version(string: versionString) {
                return parsedVersion
            }

            let dotComponents = versionString.components(separatedBy: ".")
            if let majorString = dotComponents.first, let major = Int(majorString) {
                let minor = dotComponents.count > 1 ? Int(dotComponents[1]) ?? 0 : 0
                let patch = dotComponents.count > 2 ? Int(dotComponents[2]) ?? 0 : 0
                return Version(major, minor, patch)
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
            return parseXcresulttoolVersionOutput(xcresultVersionString)
        } catch {
            print("Failed to parse xcresulttool version with error: \(error)")
            return nil
        }
    }
}
