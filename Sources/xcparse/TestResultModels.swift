//
//  TestResultModels.swift
//  xcparse
//
//  Copyright © 2024 ChargePoint, Inc. All rights reserved.
//

import Foundation

enum TestResultsOutputFormat: String {
    case json
    case junit
}

struct TestResultFailure: Codable {
    let message: String
    let fileName: String
    let lineNumber: Int
}

struct TestResultCase: Codable {
    let name: String
    let identifier: String?
    let status: String
    let duration: Double
    let failures: [TestResultFailure]
}

struct TestResultSuite: Codable {
    let name: String
    let testPlanName: String?
    let totalCount: Int
    let failureCount: Int
    let duration: Double
    let testCases: [TestResultCase]
}

struct TestResultReport: Codable {
    let suites: [TestResultSuite]

    func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\": \"\(error.localizedDescription)\"}"
        }
    }

    func toJUnitXML() -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<testsuites>\n"

        for suite in suites {
            let suiteName = xmlEscape(suite.name)
            let tests = suite.totalCount
            let failures = suite.failureCount
            let time = String(format: "%.3f", suite.duration)
            xml += "  <testsuite name=\"\(suiteName)\" tests=\"\(tests)\" failures=\"\(failures)\" time=\"\(time)\">\n"

            for testCase in suite.testCases {
                let className = xmlEscape(suite.name)
                let testName = xmlEscape(testCase.name)
                let testTime = String(format: "%.3f", testCase.duration)
                xml += "    <testcase classname=\"\(className)\" name=\"\(testName)\" time=\"\(testTime)\">\n"

                for failure in testCase.failures {
                    let failureMessage = xmlEscape(failure.message)
                    let location = "\(failure.fileName):\(failure.lineNumber)"
                    xml += "      <failure message=\"\(failureMessage)\">\(xmlEscape(location)): \(failureMessage)</failure>\n"
                }

                xml += "    </testcase>\n"
            }

            xml += "  </testsuite>\n"
        }

        xml += "</testsuites>\n"
        return xml
    }

    private func xmlEscape(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
