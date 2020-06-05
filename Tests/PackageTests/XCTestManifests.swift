import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RegistryTests.allTests),
        testCase(PackageTests.allTests)
    ]
}
#endif
