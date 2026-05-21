//
//  XCResultToolCommand.swift
//  xcparse
//
//  Created by Nikita Zamalyutdinov on 10/03/19.
//  Copyright © 2019 ChargePoint, Inc. All rights reserved.
//

import Foundation

#if os(macOS)

// MARK: - Process result wrapper

public enum CommandExitStatus: Equatable {
    case terminated(code: Int32)
    case signalled(signal: Int32)
}

public struct CommandResult {
    public let exitStatus: CommandExitStatus
    private let outputData: Data
    private let errorData: Data

    init(exitStatus: CommandExitStatus, outputData: Data, errorData: Data) {
        self.exitStatus = exitStatus
        self.outputData = outputData
        self.errorData = errorData
    }

    public func utf8Output() throws -> String {
        return String(data: outputData, encoding: .utf8) ?? ""
    }

    public func utf8stderrOutput() throws -> String {
        return String(data: errorData, encoding: .utf8) ?? ""
    }
}

// MARK: - XCResultToolCommand

let xcresultToolArguments = ["xcrun", "xcresulttool"]

open class XCResultToolCommand {
    let arguments: [String]

    let xcresult: XCResult
    var console: Console {
        get {
            return self.xcresult.console
        }
    }

    public init(withXCResult xcresult: XCResult, arguments: [String] = ["xcrun", "xcresulttool", "-h"]) {
        self.xcresult = xcresult
        self.arguments = arguments
    }

    @discardableResult public func run() -> CommandResult? {
        guard !arguments.isEmpty else { return nil }

        do {
            self.console.writeMessage("Command: \(arguments.joined(separator: " "))\n", to: .verbose)

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = arguments

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            try process.run()

            // Read both pipes concurrently to avoid deadlock when output
            // exceeds the pipe buffer (~64KB). If either pipe fills and blocks
            // the child process, reading the other pipe sequentially would hang.
            var stderrData = Data()
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.global().async {
                stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                group.leave()
            }
            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            group.wait()

            process.waitUntilExit()

            let result = CommandResult(
                exitStatus: .terminated(code: process.terminationStatus),
                outputData: stdoutData,
                errorData: stderrData
            )

            let stderr = try result.utf8stderrOutput()
            if stderr != "" {
                self.console.writeMessage(stderr, to: .error)
            }

            let stdout = try result.utf8Output()
            self.console.writeMessage(stdout, to: .verbose)

            return result
        } catch {
            print("Error when performing command")
            return nil
        }
    }

    public enum FormatType: String {
        case raw = "raw"
        case json = "json"
    }

    open class Export: XCResultToolCommand {
        public enum ExportType: String {
            case file = "file"
            case directory = "directory"
        }

        var id: String = ""
        var outputPath: String = ""
        var type: ExportType = ExportType.file

        public init(withXCResult xcresult: XCResult, id: String, outputPath: String, type: ExportType) {
            self.id = id
            self.outputPath = outputPath
            self.type = type

            var processArgs = xcresultToolArguments
            processArgs.append(contentsOf: ["export",
                                            "--type", self.type.rawValue,
                                            "--path", xcresult.path,
                                            "--id", self.id,
                                            "--output-path", self.outputPath])
            processArgs.addLegacyFlagIfNeeded()

            super.init(withXCResult: xcresult, arguments: processArgs)
        }

        public init(withXCResult xcresult: XCResult, attachment: ActionTestAttachment, outputPath: String) {
            if let identifier = attachment.payloadRef?.id {
                self.id = identifier;

                // Now let's figure out the filename & path
                let filename = attachment.filename ?? identifier
                let attachmentOutputPath = URL.init(fileURLWithPath: outputPath).appendingPathComponent(filename)
                self.outputPath = attachmentOutputPath.path
            }

            var processArgs = xcresultToolArguments
            processArgs.append(contentsOf: ["export",
                                            "--type", self.type.rawValue,
                                            "--path", xcresult.path,
                                            "--id", self.id,
                                            "--output-path", self.outputPath])

            processArgs.addLegacyFlagIfNeeded()

            super.init(withXCResult: xcresult, arguments: processArgs)
        }
    }

    open class Get: XCResultToolCommand {
        var id: String = ""
        var outputPath: String = ""
        var format = FormatType.raw

        convenience public init(path: String, id: String, outputPath: String, format: FormatType, console: Console = Console()) {
            let xcresult = XCResult(path: path, console: console)
            self.init(withXCResult: xcresult, id: id, outputPath: outputPath, format: format)
        }

        public init(withXCResult xcresult: XCResult, id: String, outputPath: String, format: FormatType) {
            self.id = id
            self.outputPath = outputPath
            self.format = format

            var processArgs = xcresultToolArguments
            processArgs.append(contentsOf: ["get",
                                            "--path", xcresult.path,
                                            "--format", self.format.rawValue])
            if self.id != "" {
                processArgs.append(contentsOf: ["--id", self.id])
            }
            if self.outputPath != "" {
                processArgs.append(contentsOf: ["--output-path", self.outputPath])
            }
            processArgs.addLegacyFlagIfNeeded()

            super.init(withXCResult: xcresult, arguments: processArgs)
        }
    }

    open class Graph: XCResultToolCommand {
        var id: String = ""
        var version: Int?

        public init(withXCResult xcresult: XCResult, id: String, version: Int?) {
            self.id = id
            self.version = version

            var processArgs = xcresultToolArguments
            processArgs.append(contentsOf: ["graph",
                                            "--path", xcresult.path])
            if self.id != "" {
                processArgs.append(contentsOf: ["--id", self.id])
            }
            if let version = self.version {
                processArgs.append(contentsOf: ["--version", "\(version)"])
            }
            processArgs.addLegacyFlagIfNeeded()

            super.init(withXCResult: xcresult, arguments: processArgs)
        }
    }

    open class MetadataGet: XCResultToolCommand {

        public init(withXCResult xcresult: XCResult) {
            var processArgs = xcresultToolArguments
            processArgs.append(contentsOf: ["metadata", "get",
                                            "--path", xcresult.path])

            super.init(withXCResult: xcresult, arguments: processArgs)
        }
    }

    open class Version: XCResultToolCommand {

        public init() {
            var processArgs = xcresultToolArguments
            processArgs.append(contentsOf: ["version"])

            let xcresult = XCResult(path: "")
            super.init(withXCResult: xcresult, arguments: processArgs)
        }
    }
}

// MARK: - Legacy flag

private let shouldAddLegacyFlag: Bool = {
    guard let xcresulttoolVersion = XCPVersion.xcresulttool() else {
      return false
    }

    let versionWithDeprecatedAPIs = XCPVersion.xcresulttoolWithDeprecatedAPIs()

    return xcresulttoolVersion >= versionWithDeprecatedAPIs
}()

private extension Array where Element: StringProtocol {
  mutating func addLegacyFlagIfNeeded() {
    if shouldAddLegacyFlag {
      self.append("--legacy")
    }
  }
}

#endif
