//
//  Version+XCPTooling.swift
//  XCParseCore
//
//  Created by Alex Botkin on 11/8/19.
//

import Foundation
import TSCBasic
import TSCUtility

public extension Version {
    static func xcresulttoolCompatibleWithUnicodeExportPath() -> Version {
        return Version(15500, 0, 0)
    }

    static func xcresulttoolWithDeprecatedAPIs() -> Version {
        return Version(23028, 0, 0)
    }

    static func xcresulttool() -> Version? {
        if let version = runXCResultToolVersion(legacyFlag: false) {
            return version
        }
        return runXCResultToolVersion(legacyFlag: true)
    }

    /// Extracts the xcresulttool version from a version output string.
    static func parseXCResultToolVersionString(_ output: String) -> Version? {
        let components = output.components(separatedBy: CharacterSet(charactersIn: ",\n"))
        for string in components {
            let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedString.hasPrefix("xcresulttool version ") {
                let versionString = trimmedString.replacingOccurrences(of: "xcresulttool version ", with: "")

                if let versionInt = Int(versionString) {
                    return Version(versionInt, 0, 0)
                } else {
                    return Version(string: versionString)
                }
            }
        }
        return nil
    }

    // MARK: - Private

    private static func runXCResultToolVersion(legacyFlag: Bool) -> Version? {
        let command = XCResultToolCommand.Version(legacyFlag: legacyFlag)
        guard let result = command.run() else {
            return nil
        }
        do {
            let stdout = try result.utf8Output()
            if let version = parseXCResultToolVersionString(stdout) {
                return version
            }

            let stderr = try result.utf8stderrOutput()
            return parseXCResultToolVersionString(stderr)
        } catch {
            return nil
        }
    }
}
