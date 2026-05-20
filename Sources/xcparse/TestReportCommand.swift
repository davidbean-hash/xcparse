//
//  TestReportCommand.swift
//  xcparse
//
//  Copyright © 2024 ChargePoint, Inc. All rights reserved.
//

import Foundation
import TSCBasic
import TSCUtility

struct TestReportCommand: Command {
    let command = "test-report"
    let overview = "Generates a JSON test report from xcresult."
    let usage = "[OPTIONS] xcresult [outputFile]"

    var path: PositionalArgument<PathArgument>
    var outputPath: PositionalArgument<PathArgument>
    var verbose: OptionArgument<Bool>

    init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, usage: usage, overview: overview)
        path = subparser.add(positional: "xcresult", kind: PathArgument.self,
                             optional: false, usage: "Path to the xcresult file", completion: .filename)
        outputPath = subparser.add(positional: "outputFile", kind: PathArgument.self,
                                   optional: true, usage: "Path to write JSON report (defaults to stdout)", completion: .filename)
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

        let report = try xcpParser.generateTestReport(xcresultPath: xcresultPath.pathString)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(report)

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("Error: Failed to encode report as JSON")
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
