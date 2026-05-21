//
//  XCResult.swift
//  XCParseCore
//
//  Created by Alex Botkin on 10/14/19.
//

import Foundation

public struct XCResult {
    public let path: String
    public let console: Console
    #if os(macOS)
    public lazy var invocationRecord: ActionsInvocationRecord? = ActionsInvocationRecord.recordFromXCResult(self)
    #endif

    public init(path xcresultPath: String, console: Console = Console()) {
        self.path = xcresultPath
        self.console = console
    }
}
