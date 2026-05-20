//
//  ReportCommand.swift
//  xcparse
//
//  Exports a test report in JSON format from an xcresult bundle.
//

import Foundation
import TSCBasic
import TSCUtility
import XCParseCore

struct ReportCommand: Command {
    let command = "report"
    let overview = "Exports a test report JSON from xcresult."
    let usage = "[OPTIONS] xcresult [outputDirectory]"

    var path: PositionalArgument<PathArgument>
    var outputPath: PositionalArgument<PathArgument>
    var verbose: OptionArgument<Bool>

    init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, usage: usage, overview: overview)
        path = subparser.add(positional: "xcresult", kind: PathArgument.self,
                             optional: false, usage: "Path to the xcresult file", completion: .filename)
        outputPath = subparser.add(positional: "outputDirectory", kind: PathArgument.self,
                                   optional: true, usage: "Folder to export report to", completion: .filename)
        verbose = subparser.add(option: "--verbose", shortName: "-v", kind: Bool.self, usage: "Enable verbose logging")
    }

    func run(with arguments: ArgumentParser.Result) throws {
        guard let xcresultPathArgument = arguments.get(path) else {
            print("Missing xcresult path")
            return
        }
        let xcresultPath = xcresultPathArgument.path

        var outputPath: TSCBasic.AbsolutePath
        if let outputPathArgument = arguments.get(self.outputPath) {
            outputPath = outputPathArgument.path
        } else if let workingDirectory = localFileSystem.currentWorkingDirectory {
            outputPath = workingDirectory
        } else {
            print("Missing output path")
            return
        }

        let verbose = arguments.get(self.verbose) ?? false

        let xcpParser = XCPParser()
        xcpParser.console.verbose = verbose
        try xcpParser.extractReport(xcresultPath: xcresultPath.pathString,
                                    destination: outputPath.pathString)
    }
}
