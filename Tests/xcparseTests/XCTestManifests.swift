import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(xcparseTests.allTests),
        testCase(StripUUIDTests.allTests),
    ]
}
#endif
