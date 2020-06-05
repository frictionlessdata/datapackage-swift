@testable import DataPackage
import TableSchema
import XCTest

class FieldTests: XCTestCase {

    func testUnique() {
        let lowercaseName = Field("firstname")
        let uppercaseName = Field("firstName")

        XCTAssertTrue(lowercaseName == uppercaseName)
        XCTAssertFalse(lowercaseName === uppercaseName)

        XCTAssertTrue(lowercaseName == lowercaseName)
        XCTAssertTrue(lowercaseName === lowercaseName)
    }

    static var allTests = [
        ("testUnique", testUnique)
    ]

}
