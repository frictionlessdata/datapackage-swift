@testable import DataPackage
import XCTest

class RegistryTests: XCTestCase {

    func testNoProfiles() {
        let registry = Registry(default: Package.self)
        let url = URL(fileURLWithPath: "./Fixtures/Package/Minimal/datapackage.json")
        var log = Log()
        XCTAssertNotNil(Package.package(url: url, registry: registry, log: &log))
    }

    func testPackageProfile() {
        let registry = Registry(default: Package.self)
        registry.add(profile: Package.self)
        let url = URL(fileURLWithPath: "./Fixtures/Package/Minimal/datapackage.json")
        var log = Log()
        XCTAssertNotNil(Package.package(url: url, registry: registry, log: &log))
    }

    static var allTests = [
        ("testNoProfiles", testNoProfiles),
        ("testPackageProfile", testPackageProfile)
    ]

}
