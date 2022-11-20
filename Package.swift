// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "datapackage-swift",
    products: [
        .library(name: "DataPackage", targets: ["DataPackage"]),
        .executable(name: "datapackage-swift", targets: ["DataPackageCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/frictionlessdata/tableschema-swift.git", .upToNextMinor(from: "0.9.0"))
    ],
    targets: [
        .target(name: "DataPackage", dependencies: ["TableSchema"], path: "Sources/DataPackage"),
        .testTarget(name: "PackageTests", dependencies: ["DataPackage"]),
        .testTarget(name: "TabularPackageTests", dependencies: ["DataPackage"]),
        .target(name: "DataPackageCLI", dependencies: ["DataPackage"], path: "Sources/CommandLineInterface")
    ],
    swiftLanguageVersions: [.version("4.2")]
)
