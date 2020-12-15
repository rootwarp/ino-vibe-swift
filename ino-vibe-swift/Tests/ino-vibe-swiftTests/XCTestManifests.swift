import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ino_vibe_swiftTests.allTests),
    ]
}
#endif
