import XCTest
import PackageTests
import TabularPackageTests

var tests = [XCTestCaseEntry]()
tests += PackageTests.allTests()
tests += TabularPackageTests.allTests()
XCTMain(tests)
