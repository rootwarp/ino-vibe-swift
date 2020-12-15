import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(UserTests.allTests),
        testCase(DeviceTests.allTests)
    ]
}
#endif
