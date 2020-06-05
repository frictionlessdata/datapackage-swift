@testable import DataPackage
import XCTest

class PackageTests: XCTestCase {

    func testAdditionalKeys() throws {
        let package = try XCTUnwrap(self.package(named: "Exemplar"))
        XCTAssertEqual(package.additionalProperties.count, 1)
        XCTAssertEqual(package.additionalProperties["updated"] as? String, "2020-01-01T23:59:59Z")
    }

    func testContributors() throws {
        let package = try XCTUnwrap(self.package(named: "Exemplar"))
        XCTAssertEqual(package.contributors.count, 1)
        let contributor = try XCTUnwrap(package.contributors.first)
        XCTAssertEqual(contributor.email, "first@example.com")
        XCTAssertEqual(contributor.organization, "Self")
        XCTAssertEqual(contributor.path?.absoluteString, "http://example.com")
        XCTAssertEqual(contributor.role, .maintainer)
        XCTAssertEqual(contributor.title, "First Last")
    }

    func testInlineData() throws {
        let package = try XCTUnwrap(self.package(named: "Minimal"))
        let resource = try XCTUnwrap(package.resources.first)
        XCTAssertEqual(resource.rawData as? [String], ["one", "two", "three"])
    }

    func testLicenses() throws {
        let package = try XCTUnwrap(self.package(named: "Exemplar"))
        XCTAssertEqual(package.licenses.count, 1)
        let license = try XCTUnwrap(package.licenses.first)
        XCTAssertEqual(license.name, "mit")
        XCTAssertEqual(license.path?.absoluteString, "https://opensource.org/licenses/MIT")
        XCTAssertEqual(license.title, "MIT License")
    }

    func testLoadByContainingDirectory() {
        let registry = Registry(default: Package.self)
        let url = URL(fileURLWithPath: "./Fixtures/Package/Minimal")
        var log = Log()
        XCTAssertNotNil(Package.package(url: url, registry: registry, log: &log))
    }

    func testResources() throws {
        let package = try XCTUnwrap(self.package(named: "Exemplar"))
        XCTAssertEqual(package.resources.count, 1)
        let resource = try XCTUnwrap(package.resources.first)
        XCTAssertEqual(resource.bytes, 0)
        XCTAssertEqual(resource.description, "Example data resource")
        XCTAssertEqual(resource.encoding, "UTF-8")
        XCTAssertEqual(resource.format, "csv")
        XCTAssertEqual(resource.hash, "sha1:8843d7f92416211de9ebb963ff4ce28125932878")
        XCTAssertEqual(resource.mediatype, "text/csv")
        XCTAssertEqual(resource.name, "quotation")
        XCTAssertEqual(resource.paths.count, 1)
        XCTAssertEqual(resource.paths.first?.absoluteString, "quotation.csv")
        XCTAssertEqual(resource.profile, "data-resource")
        XCTAssertEqual(resource.title, "Quotation Archive")
        XCTAssertEqual(resource.additionalProperties.count, 0)

        XCTAssertEqual(resource.licenses.count, 1)
        let license = try XCTUnwrap(resource.licenses.first)
        XCTAssertEqual(license.name, "other-pd")
        XCTAssertNil(license.path)
        XCTAssertEqual(license.title, "Other (Public Domain)")

        let source = try XCTUnwrap(resource.sources.first)
        XCTAssertEqual(source.path?.absoluteString, "https://en.wikiquote.org/wiki/Voltaire")
        XCTAssertEqual(source.title, "Voltaire - Wikiquote")
        XCTAssertNil(source.email)
    }

    func testRootProperties() throws {
        let package = try XCTUnwrap(self.package(named: "Exemplar"))
        XCTAssertEqual(package.created?.timeIntervalSince1970, 482196050)
        XCTAssertEqual(package.description, "Example of a valid data package")
        XCTAssertEqual(package.homepage?.absoluteString, "http://example.com")
        XCTAssertEqual(package.identifier, "58587183-0d93-4728-9b66-d85e19fed966")
        XCTAssertEqual(package.image?.absoluteString, "http://example.com/logo.png")
        XCTAssertEqual(package.keywords.count, 2)
        XCTAssertEqual(package.keywords.first, "quotes")
        XCTAssertEqual(package.keywords.last, "voltaire")
        XCTAssertEqual(package.name, "quotations")
        XCTAssertEqual(package.profile, "data-package")
        XCTAssertEqual(package.title, "Quotations Archive")
        XCTAssertEqual(package.version, "0.0.0")
    }

    func testSources() throws {
        let package = try XCTUnwrap(self.package(named: "Exemplar"))
        XCTAssertEqual(package.sources.count, 1)
        let source = try XCTUnwrap(package.sources.first)
        XCTAssertEqual(source.path?.absoluteString, "https://en.wikiquote.org/wiki/Voltaire")
        XCTAssertEqual(source.title, "Voltaire - Wikiquote")
        XCTAssertEqual(source.email, "me@example.com")
    }

    static var allTests = [
        ("testAdditionalKeys", testAdditionalKeys),
        ("testContributors", testContributors),
        ("testInlineData", testInlineData),
        ("testLicenses", testLicenses),
        ("testLoadByContainingDirectory", testLoadByContainingDirectory),
        ("testResources", testResources),
        ("testRootProperties", testRootProperties),
        ("testSources", testSources),
    ]

    // MARK: - Utility

    func package(named: String) throws -> Package {
        let registry = Registry(default: Package.self)
        registry.add(profile: Package.self)
        var url = URL(fileURLWithPath: "./Fixtures/Package/")
        url.appendPathComponent(named, isDirectory: true)
        url.appendPathComponent("datapackage.json")
        var log = Log()
        let package = try XCTUnwrap(Package.package(url: url, registry: registry, log: &log))
        let isValid = package.verify(log: &log)
        XCTAssertTrue(isValid)
        return package
    }

}
