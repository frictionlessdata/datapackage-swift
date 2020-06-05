import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(FieldTests.allTests),
        testCase(ForeignKeyTests.allTests),
        testCase(SchemaTests.allTests),
        testCase(TabularPackageTests.allTests)
    ]
}
#endif
