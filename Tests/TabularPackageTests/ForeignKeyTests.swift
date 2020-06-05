@testable import DataPackage
import TableSchema
import XCTest

class ForeignKeyTests: XCTestCase {

    func testMissingFields() throws {
        var descriptor = self.baseDescriptor()
        var log = Log()

        let baseFK = try XCTUnwrap(ForeignKey(descriptor: descriptor, log: &log))
        XCTAssertTrue(baseFK.verify(log: &log))

        baseFK.fields = [Field]()
        XCTAssertFalse(baseFK.verify(log: &log))

        descriptor[ForeignKey.Key.fields.rawValue] = [String]()
        log = Log()

        _ = try XCTUnwrap(ForeignKey(descriptor: descriptor, log: &log))
    }

    func testFieldCount() throws {
        var descriptor = self.baseDescriptor()
        descriptor[ForeignKey.Key.fields.rawValue] = ["one", "two", "three"]
        var log = Log()

        let foreignKey = try XCTUnwrap(ForeignKey(descriptor: descriptor, log: &log))
        XCTAssertFalse(foreignKey.verify(log: &log))
    }

    // MARK: - Utility

    func baseDescriptor() -> [String:Any] {
        var descriptor = [String:Any]()
        descriptor[ForeignKey.Key.fields.rawValue] = ["one", "two"]

        var reference = [String:Any]()
        reference[ForeignKey.Key.fields.rawValue] = ["1", "2"]
        reference[ForeignKey.Key.resource.rawValue] = "resource"
        descriptor[ForeignKey.Key.reference.rawValue] = reference

        return descriptor
    }

    static var allTests = [
        ("testMissingFields", testMissingFields),
        ("testFieldCount", testFieldCount)
    ]

}
