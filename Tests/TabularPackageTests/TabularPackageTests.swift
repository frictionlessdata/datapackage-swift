@testable import DataPackage
import TableSchema
import XCTest

class TabularPackageTests: XCTestCase {

    func testTabularProfile() throws {
        let registry = Registry(default: Package.self)
        registry.add(profile: Package.self)
        registry.add(profile: TabularPackage.self)
        let url = URL(fileURLWithPath: "./Fixtures/TabularPackage/Exemplar/datapackage.json")
        var log = Log()
        let package = try XCTUnwrap(Package.package(url: url, registry: registry, log: &log))
        let tabular = try XCTUnwrap(package as? TabularPackage)
        XCTAssertEqual(tabular.resources.count, 3)
        for resource in tabular.resources {
            XCTAssertNotNil(resource is TabularResource)
        }

        log = Log()
        let isValid = tabular.verify(log: &log)
        XCTAssertTrue(isValid)
    }

    // MARK: - Foreign Keys

    func testForeignKeyReferencesBetweenSelf() {
        let package = TabularPackage()

        let tag = TabularResource("tag")
        tag.rawData = [String: Any]()
        package.resources.append(tag)

        let schema = Schema()
        tag.schema = schema

        let tagName = Field("name")
        let tagQuotation = Field("quotation")
        schema.fields = [tagName, tagQuotation]
        schema.primaryKeys = [tagName, tagQuotation]

        let quotationReference = ForeignKey.Reference()
        quotationReference.fields = [tagName, tagQuotation]
        let quotationForeignKey = ForeignKey(fields: [tagQuotation], reference: quotationReference)
        schema.foreignKeys = [quotationForeignKey]

        var log = Log()
        XCTAssertTrue(package.verifyForeignKeyReferences(log: &log))
    }

    func testForeignKeyReferencesBetweenSelfMissing() {
        let package = TabularPackage()

        let tag = TabularResource("tag")
        tag.rawData = [String: Any]()
        package.resources.append(tag)

        let schema = Schema()
        tag.schema = schema

        let tagName = Field("name")
        let tagQuotation = Field("quotation")
        schema.fields = [tagName, tagQuotation]
        schema.primaryKeys = [tagName, tagQuotation]

        let quotationReference = ForeignKey.Reference()
        quotationReference.fields = [Field("id")]
        let quotationForeignKey = ForeignKey(fields: [tagQuotation], reference: quotationReference)
        schema.foreignKeys = [quotationForeignKey]

        var log = Log()
        XCTAssertFalse(package.verifyForeignKeyReferences(log: &log))
    }

    func testForeignKeyReferencesBetweenResources() {
        let package = TabularPackage()

        // Quotation
        let quotation = TabularResource("quotation")
        quotation.rawData = [String: Any]()
        package.resources.append(quotation)

        var schema = Schema()
        quotation.schema = schema

        let quotationIdentifier = Field("id")
        let quotationQuote = Field("quote")
        schema.fields = [quotationIdentifier, quotationQuote]

        // Tag
        let tag = TabularResource("tag")
        tag.rawData = [String: Any]()
        package.resources.append(tag)

        schema = Schema()
        tag.schema = schema

        let tagName = Field("name")
        let tagQuotation = Field("quotation")
        schema.fields = [tagName, tagQuotation]
        schema.primaryKeys = [tagName, tagQuotation]

        let quotationReference = ForeignKey.Reference(quotation)
        quotationReference.fields = [quotationIdentifier]
        let quotationForeignKey = ForeignKey(fields: [tagQuotation], reference: quotationReference)
        schema.foreignKeys = [quotationForeignKey]

        var log = Log()
        XCTAssertTrue(package.verifyForeignKeyReferences(log: &log))
    }

    func testForeignKeyReferenceToWrongResourceProfile() {
        let package = TabularPackage()

        // Quotation
        let quotation = Resource("quotation")
        quotation.rawData = [String: Any]()
        package.resources.append(quotation)

        // Tag
        let tag = TabularResource("tag")
        tag.rawData = [String: Any]()
        package.resources.append(tag)

        let schema = Schema()
        tag.schema = schema

        let tagName = Field("name")
        let tagQuotation = Field("quotation")
        schema.fields = [tagName, tagQuotation]
        schema.primaryKeys = [tagName, tagQuotation]

        let quotationReference = ForeignKey.Reference(quotation)
        quotationReference.fields = [Field("id")]
        let quotationForeignKey = ForeignKey(fields: [tagQuotation], reference: quotationReference)
        schema.foreignKeys = [quotationForeignKey]

        var log = Log()
        XCTAssertFalse(package.verifyForeignKeyReferences(log: &log))
    }

    func testForeignKeyReferencesMissing() {
        let package = TabularPackage()

        let tag = TabularResource("tag")
        tag.rawData = [String: Any]()
        package.resources.append(tag)

        let schema = Schema()
        tag.schema = schema

        let tagName = Field("name")
        let tagQuotation = Field("quotation")
        schema.fields = [tagName, tagQuotation]
        schema.primaryKeys = [tagName, tagQuotation]

        let quotationReference = ForeignKey.Reference(resource: "unknown")
        quotationReference.fields = [Field("id")]
        let quotationForeignKey = ForeignKey(fields: [tagQuotation], reference: quotationReference)
        schema.foreignKeys = [quotationForeignKey]

        var log = Log()
        XCTAssertFalse(package.verifyForeignKeyReferences(log: &log))
    }

    static var allTests = [
        ("testTabularProfile", testTabularProfile),
        ("testForeignKeyReferencesBetweenSelf", testForeignKeyReferencesBetweenSelf),
        ("testForeignKeyReferencesBetweenSelfMissing", testForeignKeyReferencesBetweenSelfMissing),
        ("testForeignKeyReferencesBetweenResources", testForeignKeyReferencesBetweenResources),
        ("testForeignKeyReferenceToWrongResourceProfile", testForeignKeyReferenceToWrongResourceProfile),
        ("testForeignKeyReferencesMissing", testForeignKeyReferencesMissing)
    ]

}
