import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(xcparseTests.allTests),
        testCase(ActivityTypeFilterTests.allTests),
    ]
}
#endif
