//
//  TestReport.swift
//  xcparse
//
//  Copyright © 2024 ChargePoint, Inc. All rights reserved.
//

import Foundation

struct TestReport: Codable {
    let tests: [TestReportEntry]
}

struct TestReportEntry: Codable {
    let name: String?
    let identifier: String?
    let status: String
    let duration: Double
    let failureSummaries: [TestFailureEntry]?
    let attachments: [TestAttachmentEntry]?
}

struct TestFailureEntry: Codable {
    let file: String?
    let line: Int?
    let message: String?
}

struct TestAttachmentEntry: Codable {
    let name: String?
    let filename: String?
    let uniformTypeIdentifier: String
}
