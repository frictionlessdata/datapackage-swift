import Foundation

/**
    Package represents a Data Package that contains metadata about the contents of the package and its data resources.

    - SeeAlso: [Data Package](https://specs.frictionlessdata.io/data-package/)
*/
public class Package: Profile, Serializable, Verifiable {

    static let descriptorPathComponent: String = "datapackage.json"

    public enum Key: String, CaseIterable {
    case resources
    case licenses
    case profile
    case name
    case identifier = "id"
    case title
    case description
    case homepage
    case version
    case sources
    case contributors
    case keywords
    case image
    case created
    }

    // MARK: - Properties

    public var resources: [Resource] = [Resource]()
    internal var resourcesByName: [String: Resource] {
        var resourcesByName = [String: Resource]()
        for resource in self.resources {
            resourcesByName[resource.name] = resource
        }
        return resourcesByName
    }
    public var licenses: [License] = [License]()
    public var profile: String? = Registry.defaultProfile
    public var name: String?
    public var identifier: String?
    public var title: String?
    public var description: String?
    public var homepage: URL?
    public var version: String?
    public var sources: [Source] = [Source]()
    public var contributors: [Contributor] = [Contributor]()
    public var keywords: [String] = [String]()
    public var image: URL?
    public var created: Date?

    /**
        Custom properties not otherwise defined by the specification.

        Properties defined by the specification take precedence over these additional properties. If a new property is declared, or if a subclass adds a property, it will no longer appear here.
    */
    public var additionalProperties = [String: Any]()
    /**
        Additional property names to exclude in `additionalProperties`.

        Subclasses should override with any new properties it declares.
    */
    open private(set) var additionalKeys = Set<String>()

    // MARK: - Setup & Teardown

    public init() {}

    // MARK: - Profile

    /**
        Instantiates a package from a JSON-originating dictionary descriptor.

        - Parameter descriptor: A JSON-originating dictionary description of the package.
        - Parameter log: Log for writing encountered issues with the descriptor.
    */
    required public init?(descriptor: [String: Any], log: inout Log) {
        if let resourceDescriptors = descriptor[Key.resources.rawValue] as? [[String: Any]] {
            let registry = Registry(default: Resource.self)
            registry.add(profile: Resource.self)

            var resourcesLog = Log(baseKeyPath: [Key.resources.rawValue])
            for descriptor in resourceDescriptors {
                if let profile = registry.profile(descriptor: descriptor, log: &resourcesLog), let resource = profile as? Resource {
                    self.resources.append(resource)
                }
            }
            log.append(contentsOf: resourcesLog)
        }

        if let licenseDescriptors = descriptor[Key.licenses.rawValue] as? [[String: Any]] {
            var licensesLog = Log(baseKeyPath: [Key.licenses.rawValue])
            for descriptor in licenseDescriptors {
                if let license = License(descriptor: descriptor, log: &licensesLog) {
                    self.licenses.append(license)
                }
            }
            log.append(contentsOf: licensesLog)
        }

        if let profile = descriptor[Key.profile.rawValue] as? String {
            self.profile = profile
        } else {
            log.append(keyPath: [Key.profile.rawValue], level: .warning, entry: .missing)
        }

        if let name = descriptor[Key.name.rawValue] as? String {
            self.name = name
        }

        if let identifier = descriptor[Key.identifier.rawValue] as? String {
            self.identifier = identifier
        }

        if let title = descriptor[Key.title.rawValue] as? String {
            self.title = title
        }

        if let description = descriptor[Key.description.rawValue] as? String {
            self.description = description
        }

        if let homepage = descriptor[Key.homepage.rawValue] as? String {
            if let url = URL(string: homepage) {
                self.homepage = url
            } else {
                log.append(keyPath: [Key.homepage.rawValue], level: .warning, entry: .badInput(homepage))
            }
        }

        if let version = descriptor[Key.version.rawValue] as? String {
            self.version = version
        }

        if let sourceDescriptors = descriptor[Key.sources.rawValue] as? [[String: Any]] {
            var sourcesLog = Log(baseKeyPath: [Key.sources.rawValue])
            for descriptor in sourceDescriptors {
                if let source = Source(descriptor: descriptor, log: &sourcesLog) {
                    self.sources.append(source)
                }
            }
            log.append(contentsOf: sourcesLog)
        }

        if let contributorDescriptors = descriptor[Key.contributors.rawValue] as? [[String: Any]] {
            var contributorsLog = Log(baseKeyPath: [Key.contributors.rawValue])
            for descriptor in contributorDescriptors {
                if let contributor = Contributor(descriptor: descriptor, log: &contributorsLog) {
                    self.contributors.append(contributor)
                }
            }
            log.append(contentsOf: contributorsLog)
        }

        if let keywords = descriptor[Key.keywords.rawValue] as? [String] {
            self.keywords = keywords
        }

        if let image = descriptor[Key.image.rawValue] as? String {
            if let url = URL(string: image) {
                self.image = url
            } else {
                log.append(keyPath: [Key.image.rawValue], level: .warning, entry: .badInput(image))
            }
        }

        #if os(iOS) || os(macOS)
        if #available(iOS 10, macOS 10.12, *) {
            let dateFormatter = ISO8601DateFormatter()
            if let created = descriptor[Key.created.rawValue] as? String {
                if let date = dateFormatter.date(from: created) {
                    self.created = date
                } else {
                    log.append(keyPath: [Key.created.rawValue], level: .warning, entry: .badInput(created))
                }
            }
        }
        #endif

        var omitProperties = Set<String>(Key.allCases.map { $0.rawValue })
        omitProperties.formUnion(additionalKeys)
        self.additionalProperties = descriptor.filter { !omitProperties.contains($0.key) }
    }

    public class var profileName: String { return "data-package" }

    // MARK: - Class Methods

    /**
        Instantiates a package of any registered profile from a local URL.

        - Parameter url: URL to a local file.
        - Parameter registry: Registry from which to grab profiles.
        - Parameter log: Log for writing encountered issues with the descriptor.
    */
    public final class func package(url: URL, registry: Registry, log: inout Log) -> Package? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return nil
        }

        var descriptorURL = url

        if isDirectory.boolValue {
            descriptorURL.appendPathComponent(Package.descriptorPathComponent)
            guard FileManager.default.fileExists(atPath: descriptorURL.path) else {
                return nil
            }
        }

        guard let data = FileManager.default.contents(atPath: descriptorURL.path) else {
            return nil
        }

        return self.package(descriptor: data, registry: registry, log: &log)
    }

    /**
        Instantiates a package of any registered profile from a descriptor.

        - Parameter descriptor: Data descriptor containing JSON.
        - Parameter registry: Registry from which to find and instantiate profiles.
        - Parameter log: Log for writing encountered issues with the descriptor.
    */
    public final class func package(descriptor: Data, registry: Registry, log: inout Log) -> Package? {
        guard let descriptorRoot = (try? JSONSerialization.jsonObject(with: descriptor, options: [])) as? [String: Any] else {
            return nil
        }

        return registry.profile(descriptor: descriptorRoot, log: &log) as? Package
    }

    // MARK: - Methods

    /**
        Saves the package to the file system.

        Creates the directory and file if they don't exist already.

        - Parameter: A local, writeable filesystem URL, either to the directory or the package descriptor file.
        - Return: Whether the save was successful.
    */
    public final func save(to url: URL) -> Bool {
        guard (try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)) != nil else {
            return false
        }

        let descriptor = self.serialize()
        guard JSONSerialization.isValidJSONObject(descriptor) else {
            return false
        }

        let saveURL = (url.lastPathComponent != Package.descriptorPathComponent) ? url.appendingPathComponent(Package.descriptorPathComponent) : url

        guard let data = try? JSONSerialization.data(withJSONObject: descriptor, options: .prettyPrinted) else {
            return false
        }

        return FileManager.default.createFile(atPath: saveURL.path, contents: data)
    }

    // MARK: - Serializable

    func serialize() -> [String: Any] {
        var descriptor = self.additionalProperties

        if self.resources.count > 0 {
            descriptor[Key.resources.rawValue] = self.resources.map { $0.serialize() }
        }
        if self.licenses.count > 0 {
            descriptor[Key.licenses.rawValue] = self.licenses.map { $0.serialize() }
        }
        descriptor[Key.profile.rawValue] = self.profile
        descriptor[Key.name.rawValue] = self.name
        descriptor[Key.identifier.rawValue] = self.identifier
        descriptor[Key.title.rawValue] = self.title
        descriptor[Key.description.rawValue] = self.description
        descriptor[Key.homepage.rawValue] = self.homepage?.absoluteString
        descriptor[Key.version.rawValue] = self.version
        if self.sources.count > 0 {
            descriptor[Key.sources.rawValue] = self.sources.map { $0.serialize() }
        }
        if self.contributors.count > 0 {
            descriptor[Key.contributors.rawValue] = self.contributors.map { $0.serialize() }
        }
        if self.keywords.count > 0 {
            descriptor[Key.keywords.rawValue] = self.keywords
        }
        descriptor[Key.image.rawValue] = self.image?.absoluteString

        if #available(iOS 10, macOS 10.12, *) {
            if let date = self.created {
                let dateFormatter = ISO8601DateFormatter()
                descriptor[Key.created.rawValue] = dateFormatter.string(from: date)
            }
        }

        return descriptor
    }

    // MARK: - Verifiable

    /**
        Verifies the state of the entire package.

        - Parameter log: Log for writing encountered issues with the package's state.
        - Returns: Whether any errors were detected.
    */
    @discardableResult
    public func verify(log: inout Log) -> Bool {
        var isValid = true

        if self.resources.count == 0 {
            isValid = false
            log.append(keyPath: [Key.resources.rawValue], level: .error, entry: .missing)
        }

        var resourcesLog = Log(baseKeyPath: [Key.resources.rawValue])
        for resource in self.resources {
            isValid = isValid && resource.verify(log: &resourcesLog)
        }
        log.append(contentsOf: resourcesLog)

        var licensesLog = Log(baseKeyPath: [Key.licenses.rawValue])
        for license in self.licenses {
            isValid = isValid && license.verify(log: &licensesLog)
        }
        log.append(contentsOf: licensesLog)

        var contributorsLog = Log(baseKeyPath: [Key.contributors.rawValue])
        for contributor in self.contributors {
            isValid = isValid && contributor.verify(log: &contributorsLog)
        }
        log.append(contentsOf: contributorsLog)

        var sourcesLog = Log(baseKeyPath: [Key.sources.rawValue])
        for source in self.sources {
            isValid = isValid && source.verify(log: &sourcesLog)
        }
        log.append(contentsOf: sourcesLog)

        if (self.profile ?? "").isEmpty {
            log.append(keyPath: [Key.profile.rawValue], level: .warning, entry: .missing)
        }

        if (self.name ?? "").isEmpty {
            log.append(keyPath: [Key.name.rawValue], level: .warning, entry: .missing)
        }

        if (self.identifier ?? "").isEmpty {
            log.append(keyPath: [Key.identifier.rawValue], level: .warning, entry: .missing)
        }

        return (log.pruning(by: .error).count == 0) && isValid
    }

}
