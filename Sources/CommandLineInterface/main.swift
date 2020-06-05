import DataPackage
import Foundation

let processURL = URL(fileURLWithPath: CommandLine.arguments[0])
print(processURL.lastPathComponent, "version", Version.long)

guard CommandLine.argc > 1 else {
    print("Missing package path argument.")
    exit(1)
}

let path = CommandLine.arguments[1]
let url = URL(fileURLWithPath: path)

let registry = Registry(default: Package.self)
registry.add(profile: Package.self)
registry.add(profile: TabularPackage.self)

var log = Log()

let wrappedPackage = Package.package(url: url, registry: registry, log: &log)
log.print()

guard let package = wrappedPackage, log.pruning(by: .error).count == 0 else {
    print("Package failed to load.")
    exit(1)
}

log = Log()
let isValid = package.verify(log: &log)
log.print()

guard isValid, log.pruning(by: .error).count == 0 else {
    print("Package failed to validate.")
    exit(1)
}

print("Package okay.")

if CommandLine.argc > 2 {
    let exportPath = CommandLine.arguments[2]
    let exportURL = URL(fileURLWithPath: exportPath)
    print("Exporting to '\(exportURL.absoluteString)'")
    let result = package.save(to: exportURL)
    guard result else {
        print("Package failed to export.")
        exit(1)
    }
    print("Package exported.")
}

exit(0)
