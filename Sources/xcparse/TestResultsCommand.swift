//
//  TestResultsCommand.swift
//  xcparse
//
//  Copyright © 2024 ChargePoint, Inc. All rights reserved.
//

import Foundation
import TSCBasic
import TSCUtility

struct TestResultsCommand: Command {
    let command = "test-results"
    let overview = "Exports test results from xcresult in JSON or JUnit XML format."
    let usage = "[OPTIONS] xcresult [outputPath]"

    var path: PositionalArgument<PathArgument>
    var outputPath: PositionalArgument<PathArgument>
    var verbose: OptionArgument<Bool>
    var format: OptionArgument<String>

    init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, usage: usage, overview: overview)
        path = subparser.add(positional: "xcresult", kind: PathArgument.self,
                             optional: false, usage: "Path to the xcresult file", completion: .filename)
        outputPath = subparser.add(positional: "outputPath", kind: PathArgument.self,
                                   optional: true, usage: "File path or directory to write results to", completion: .filename)
        verbose = subparser.add(option: "--verbose", shortName: "-v", kind: Bool.self, usage: "Enable verbose logging")
        format = subparser.add(option: "--format", shortName: "-f", kind: String.self, usage: "Output format: json (default) or junit")
    }

    func run(with arguments: ArgumentParser.Result) throws {
        guard let xcresultPathArgument = arguments.get(path) else {
            print("Missing xcresult path")
            return
        }
        let xcresultPath = xcresultPathArgument.path

        let outputPath: TSCBasic.AbsolutePath?
        if let outputPathArgument = arguments.get(self.outputPath) {
            outputPath = outputPathArgument.path
        } else {
            outputPath = nil
        }

        let verbose = arguments.get(self.verbose) ?? false
        let formatString = arguments.get(self.format) ?? "json"

        guard let outputFormat = TestResultsOutputFormat(rawValue: formatString.lowercased()) else {
            print("Error: Unknown format \"\(formatString)\". Use \"json\" or \"junit\".")
            return
        }

        let xcpParser = XCPParser()
        xcpParser.console.verbose = verbose
        try xcpParser.extractTestResults(xcresultPath: xcresultPath.pathString,
                                         outputPath: outputPath?.pathString,
                                         format: outputFormat)
    }
}
