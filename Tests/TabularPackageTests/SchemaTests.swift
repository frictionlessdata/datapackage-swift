@testable import DataPackage
import TableSchema
import XCTest

class SchemaTests: XCTestCase {

    // MARK: Fields

    func testFieldsUnique() {
        let lowercaseName = Field("firstname")
        let user = Field("user")

        var log = Log()
        let descriptor = [
            Schema.Key.fields.rawValue: [
                lowercaseName.serialize(),
                user.serialize()
            ]
        ]
        var schema = Schema(descriptor: descriptor, log: &log)
        XCTAssertNotNil(schema)
        XCTAssertEqual(schema!.fields.count, 2)
        XCTAssertEqual(schema!.fields.unique.count, 2)
        XCTAssertFalse(schema!.fields.first! == schema!.fields.last!)
        XCTAssertFalse(schema!.fields.first! === schema!.fields.last!)
        log = Log()
        var (valid, unique) = schema!.verifyFields(log: &log)
        XCTAssertTrue(valid)
        XCTAssertTrue(unique)

        schema = Schema()
        schema!.fields = [lowercaseName, user]
        log = Log()
        (valid, unique) = schema!.verifyFields(log: &log)
        XCTAssertTrue(valid)
        XCTAssertTrue(unique)
    }

    func testFieldsUniqueCaseSensitive() {
        let lowercaseName = Field("firstname")

        var log = Log()
        let descriptor = [
            Schema.Key.fields.rawValue: [
                lowercaseName.serialize(),
                lowercaseName.serialize()
            ]
        ]
        var schema = Schema(descriptor: descriptor, log: &log)
        XCTAssertNotNil(schema)
        XCTAssertEqual(schema!.fields.count, 2)
        XCTAssertEqual(schema!.fields.unique.count, 1)
        XCTAssertTrue(schema!.fields.first! == schema!.fields.last!)
        XCTAssertFalse(schema!.fields.first! === schema!.fields.last!)
        log = Log()
        var (valid, unique) = schema!.verifyFields(log: &log)
        XCTAssertTrue(valid)
        XCTAssertFalse(unique)

        schema = Schema()
        schema!.fields = [lowercaseName, lowercaseName]
        XCTAssertEqual(schema!.fields.count, 2)
        XCTAssertEqual(schema!.fields.unique.count, 1)
        XCTAssertTrue(schema!.fields.first! == schema!.fields.last!)
        XCTAssertTrue(schema!.fields.first! === schema!.fields.last!)
        log = Log()
        (valid, unique) = schema!.verifyFields(log: &log)
        XCTAssertTrue(valid)
        XCTAssertFalse(unique)
    }

    func testFieldsUniqueCaseInsensitive() {
        let lowercaseName = Field("firstname")
        let uppercaseName = Field("firstName")

        var log = Log()
        let descriptor = [
            Schema.Key.fields.rawValue: [
                lowercaseName.serialize(),
                uppercaseName.serialize()
            ]
        ]
        var schema = Schema(descriptor: descriptor, log: &log)
        XCTAssertNotNil(schema)
        XCTAssertEqual(schema!.fields.count, 2)
        XCTAssertEqual(schema!.fields.unique.count, 1)
        XCTAssertTrue(schema!.fields.first! == schema!.fields.last!)
        XCTAssertFalse(schema!.fields.first! === schema!.fields.last!)
        log = Log()
        var (valid, unique) = schema!.verifyFields(log: &log)
        XCTAssertTrue(valid)
        XCTAssertFalse(unique)

        schema = Schema()
        schema!.fields = [lowercaseName, uppercaseName]
        XCTAssertEqual(schema!.fields.count, 2)
        XCTAssertEqual(schema!.fields.unique.count, 1)
        XCTAssertTrue(schema!.fields.first! == schema!.fields.last!)
        XCTAssertFalse(schema!.fields.first! === schema!.fields.last!)
        log = Log()
        (valid, unique) = schema!.verifyFields(log: &log)
        XCTAssertTrue(valid)
        XCTAssertFalse(unique)
    }

    // MARK: Primary Keys

    func testPrimaryKeysUnique() {
        let name = Field("name")
        let identifier = Field("identifier")

        let schema = Schema()
        schema.fields = [name, identifier]
        schema.primaryKeys = [name, identifier]
        XCTAssertFalse(schema.primaryKeys.last! == schema.primaryKeys.first!)
        XCTAssertFalse(schema.primaryKeys.last! === schema.primaryKeys.first!)

        var log = Log()
        let (valid, unique) = schema.verifyPrimaryKeys(log: &log)
        XCTAssertTrue(valid)
        XCTAssertTrue(unique)
    }

    // TODO: func testPrimaryKeysUniqueCaseSensitive()

    // TODO: func testPrimaryKeysUniqueCaseInsensitive()

    func testPrimaryKeysByName() {
        let name = Field("name")
        let identifier = Field("identifier")
        let otherIdentifier = Field(identifier.name)

        let schema = Schema()
        schema.fields = [name, identifier]
        schema.primaryKeys = [otherIdentifier]
        XCTAssertTrue(schema.fields.last! == schema.primaryKeys.first!)
        XCTAssertFalse(schema.fields.last! === schema.primaryKeys.first!)

        var log = Log()
        let (valid, _) = schema.verifyPrimaryKeys(log: &log)
        XCTAssertTrue(valid)
    }

    func testPrimaryKeysByInstance() {
        let name = Field("name")
        let identifier = Field("identifier")
        let otherIdentifier = Field(identifier.name)

        var log = Log()
        let descriptor = [
            Schema.Key.fields.rawValue: [
                name.serialize(),
                identifier.serialize()
            ],
            Schema.Key.primaryKeys.rawValue: [otherIdentifier.name]
        ]
        var schema = Schema(descriptor: descriptor, log: &log)
        XCTAssertNotNil(schema)
        XCTAssertTrue(schema!.fields.last! === schema!.primaryKeys.first!)

        schema = Schema()
        schema!.fields = [name, identifier]
        schema!.primaryKeys = [identifier]
        XCTAssertTrue(schema!.fields.last! === schema!.primaryKeys.first!)
        log = Log()
        let (valid, _) = schema!.verifyPrimaryKeys(log: &log)
        XCTAssertTrue(valid)
    }

    func testPrimaryKeysMissing() {
        let name = Field("name")
        let identifier = Field("identifier")

        var log = Log()
        let descriptor = [
            Schema.Key.fields.rawValue: [
                name.serialize()
            ],
            Schema.Key.primaryKeys.rawValue: [identifier.name]
        ]
        var schema = Schema(descriptor: descriptor, log: &log)
        XCTAssertNil(schema)

        schema = Schema()
        schema!.fields = [name]
        schema!.primaryKeys = [identifier]

        log = Log()
        let (valid, _) = schema!.verifyPrimaryKeys(log: &log)
        XCTAssertFalse(valid)
    }

    // MARK: Foreign Keys

    // TODO: func testForeignKeyFieldUniqueCaseSensitive()

    // TODO: func testForeignKeyFieldUniqueCaseInsensitive()

    static var allTests = [
        ("testFieldsUnique", testFieldsUnique),
        ("testFieldsUniqueCaseSensitive", testFieldsUniqueCaseSensitive),
        ("testFieldsUniqueCaseInsensitive", testFieldsUniqueCaseInsensitive),
        ("testPrimaryKeysUnique", testPrimaryKeysUnique),
        ("testPrimaryKeysByName", testPrimaryKeysByName),
        ("testPrimaryKeysByInstance", testPrimaryKeysByInstance),
        ("testPrimaryKeysMissing", testPrimaryKeysMissing)
    ]

}
