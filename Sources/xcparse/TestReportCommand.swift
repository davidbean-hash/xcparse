//
//  TestReportCommand.swift
//  xcparse
//
//  Created by Devin AI on behalf of ChargePoint/xcparse#78.
//  Copyright © 2024 ChargePoint, Inc. All rights reserved.
//

import Foundation
import TSCBasic
import TSCUtility
import XCParseCore

struct TestReportAttachment: Encodable {
    let name: String?
    let filename: String?
}

struct TestReportFailure: Encodable {
    let file: String
    let line: Int
    let message: String?
    let attachments: [TestReportAttachment]
}

struct TestReportEntry: Encodable {
    let testName: String?
    let testStatus: String
    let failures: [TestReportFailure]
}

struct TestReportCommand: Command {
    let command = "test-report"
    let overview = "Exports a structured JSON test report from an xcresult bundle."
    let usage = "[OPTIONS] xcresult [outputFile]"

    var path: PositionalArgument<PathArgument>
    var outputPath: PositionalArgument<PathArgument>
    var verbose: OptionArgument<Bool>

    init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, usage: usage, overview: overview)
        path = subparser.add(positional: "xcresult", kind: PathArgument.self,
                             optional: false, usage: "Path to the xcresult file", completion: .filename)
        outputPath = subparser.add(positional: "outputFile", kind: PathArgument.self,
                                   optional: true, usage: "Path to write the JSON report (defaults to stdout)", completion: .filename)
        verbose = subparser.add(option: "--verbose", shortName: "-v", kind: Bool.self, usage: "Enable verbose logging")
    }

    func run(with arguments: ArgumentParser.Result) throws {
        guard let xcresultPathArgument = arguments.get(path) else {
            print("Missing xcresult path")
            return
        }
        let xcresultPath = xcresultPathArgument.path

        let verbose = arguments.get(self.verbose) ?? false

        let xcpParser = XCPParser()
        xcpParser.console.verbose = verbose

        var xcresult = XCResult(path: xcresultPath.pathString, console: xcpParser.console)
        guard let invocationRecord = xcresult.invocationRecord else {
            xcpParser.console.writeMessage(""\(xcresult.path)" does not appear to be an xcresult", to: .error)
            return
        }

        var reportEntries: [TestReportEntry] = []

        let actions = invocationRecord.actions.filter { $0.actionResult.testsRef != nil }
        for action in actions {
            guard let testRef = action.actionResult.testsRef else {
                continue
            }

            guard let testPlanRunSummaries: ActionTestPlanRunSummaries = testRef.modelFromReference(withXCResult: xcresult) else {
                xcpParser.console.writeMessage("Error: Unhandled test reference type \(String(describing: testRef.targetType?.getType()))", to: .error)
                continue
            }

            for testPlanRun in testPlanRunSummaries.summaries {
                for testableSummary in testPlanRun.testableSummaries {
                    let testSummaryMap = testableSummary.flattenedTestSummaryMap(withXCResult: xcresult)
                    for (testSummary, _) in testSummaryMap {
                        let failures = testSummary.failureSummaries.map { failureSummary -> TestReportFailure in
                            let attachments = failureSummary.attachments.map { attachment in
                                TestReportAttachment(name: attachment.name,
                                                     filename: attachment.filename)
                            }
                            return TestReportFailure(file: failureSummary.fileName,
                                                     line: failureSummary.lineNumber,
                                                     message: failureSummary.message,
                                                     attachments: attachments)
                        }

                        let entry = TestReportEntry(testName: testSummary.name,
                                                    testStatus: testSummary.testStatus,
                                                    failures: failures)
                        reportEntries.append(entry)
                    }
                }
            }
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(reportEntries)

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            xcpParser.console.writeMessage("Error: Failed to encode JSON report", to: .error)
            return
        }

        if let outputPathArgument = arguments.get(self.outputPath) {
            try jsonData.write(to: URL(fileURLWithPath: outputPathArgument.path.pathString))
            xcpParser.console.writeMessage("Test report written to \(outputPathArgument.path.pathString)")
        } else {
            print(jsonString)
        }
    }
}
