import Foundation

/**
    Resource represents a Data Resource that contains metadata about a resource and potentially includes embedded data.

    - SeeAlso: [Data Resource](https://specs.frictionlessdata.io/data-resource/)
*/
public class Resource: Profile, Serializable, Verifiable {

    public enum Key: String, CaseIterable {
    case name
    case profile
    case title
    case description
    case format
    case mediatype
    case encoding
    case bytes
    case hash
    case sources
    case licenses
    case paths = "path"
    case data
    case schema
    }

    // MARK: - Properties

    public var name: String
    public var profile: String? = Registry.defaultProfile
    public var title: String?
    public var description: String?
    public var format: String?
    public var mediatype: String?
    public var encoding: String? = "UTF-8"
    public var bytes: UInt?
    public var hash: String?
    public var sources: [Source] = [Source]()
    public var licenses: [License] = [License]()
    public var paths: [URL] = [URL]()

    /// Raw data that requires interpretation
    public var rawData: Any?

    /// Raw schema that requires interpretation
    public var rawSchema: Any?

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

    public init(_ name: String) {
        self.name = name
    }

    // MARK: - Profile

    required public init?(descriptor: [String: Any], log: inout Log) {
        guard let name = descriptor[Key.name.rawValue] as? String else {
            log.append(keyPath: [Key.name.rawValue], level: .error, entry: .missing)
            return nil
        }
        self.name = name

        if let profile = descriptor[Key.profile.rawValue] as? String {
            self.profile = profile
        } else {
            log.append(keyPath: [Key.profile.rawValue], level: .warning, entry: .missing)
        }

        if let title = descriptor[Key.title.rawValue] as? String {
            self.title = title
        }

        if let description = descriptor[Key.description.rawValue] as? String {
            self.description = description
        }

        if let format = descriptor[Key.format.rawValue] as? String {
            self.format = format
        }

        if let mediatype = descriptor[Key.mediatype.rawValue] as? String {
            self.mediatype = mediatype
        }

        if let encoding = descriptor[Key.encoding.rawValue] as? String {
            self.encoding = encoding
        }

        if let bytes = descriptor[Key.bytes.rawValue] as? UInt {
            self.bytes = bytes
        }

        if let hash = descriptor[Key.hash.rawValue] as? String {
            self.hash = hash
        }

        if let sourceDescriptors = descriptor[Key.sources.rawValue] as? [[String: Any]] {
            var baseKeyPath = Array(log.currentKeyPath)
            baseKeyPath.append(Key.sources.rawValue)
            var sourceLog = Log(baseKeyPath: baseKeyPath)
            for descriptor in sourceDescriptors {
                if let source = Source(descriptor: descriptor, log: &sourceLog) {
                    self.sources.append(source)
                }
            }
            log.append(contentsOf: sourceLog)
        }

        if let licenseDescriptors = descriptor[Key.licenses.rawValue] as? [[String: Any]] {
            var baseKeyPath = Array(log.currentKeyPath)
            baseKeyPath.append(Key.licenses.rawValue)
            var licenseLog = Log(baseKeyPath: baseKeyPath)
            for descriptor in licenseDescriptors {
                if let license = License(descriptor: descriptor, log: &licenseLog) {
                    self.licenses.append(license)
                }
            }
            log.append(contentsOf: licenseLog)
        }

        if let paths = descriptor.castArray(String.self, forKey: Key.paths.rawValue) {
            for path in paths {
                if let url = URL(string: path) {
                    self.paths.append(url)
                } else {
                    log.append(keyPath: [Key.paths.rawValue], level: .warning, entry: .badInput(path))
                }
            }
        }

        self.rawData = descriptor[Key.data.rawValue]
        self.rawSchema = descriptor[Key.schema.rawValue]

        var omitProperties = Set<String>(Key.allCases.map { $0.rawValue })
        omitProperties.formUnion(additionalKeys)
        self.additionalProperties = descriptor.filter { !omitProperties.contains($0.key) }
    }

    public class var profileName: String { return "data-resource" }

    // MARK: - Serializable

    func serialize() -> [String: Any] {
        var descriptor = self.additionalProperties

        descriptor[Key.name.rawValue] = self.name
        descriptor[Key.profile.rawValue] = self.profile
        descriptor[Key.title.rawValue] = self.title
        descriptor[Key.description.rawValue] = self.description
        descriptor[Key.format.rawValue] = self.format
        descriptor[Key.mediatype.rawValue] = self.mediatype
        descriptor[Key.encoding.rawValue] = self.encoding
        descriptor[Key.bytes.rawValue] = self.bytes
        descriptor[Key.hash.rawValue] = self.hash
        if self.sources.count > 0 {
            descriptor[Key.sources.rawValue] = self.sources.map { $0.serialize() }
        }
        if self.licenses.count > 0 {
            descriptor[Key.licenses.rawValue] = self.licenses.map { $0.serialize() }
        }
        if self.paths.count > 0 {
            descriptor[Key.paths.rawValue] = self.paths.map { $0.absoluteString }
        }
        descriptor[Key.data.rawValue] = self.rawData
        descriptor[Key.schema.rawValue] = self.rawSchema

        return descriptor
    }

    // MARK: - Verifiable

    /**
        Verifies the state of the entire resource.

        - Parameter log: Log for writing encountered issues with the package's state.
        - Returns: Whether any errors were detected.
    */
    @discardableResult
    public func verify(log: inout Log) -> Bool {
        var isValid = true

        let missingBoth = (self.paths.count == 0) && (self.rawData == nil)
        let missingNone = (self.paths.count > 0) && (self.rawData != nil)
        if missingBoth || missingNone {
            isValid = false
            if missingBoth {
                log.append(keyPath: [Key.paths.rawValue], level: .error, entry: .missing)
                log.append(keyPath: [Key.data.rawValue], level: .error, entry: .missing)
            }
            log.append(keyPath: [Key.paths.rawValue], level: .error, entry: .conflicting([Key.data.rawValue]))
        }

        if (self.profile ?? "").isEmpty {
            log.append(keyPath: [Key.profile.rawValue], level: .warning, entry: .missing)
        }

        var baseKeyPath = log.currentKeyPath
        baseKeyPath.append(Key.sources.rawValue)
        var sourcesLog = Log(baseKeyPath: baseKeyPath)
        for source in self.sources {
            isValid = isValid && source.verify(log: &sourcesLog)
        }
        log.append(contentsOf: sourcesLog)

        baseKeyPath = Array(log.currentKeyPath)
        baseKeyPath.append(Key.licenses.rawValue)
        var licensesLog = Log(baseKeyPath: baseKeyPath)
        for license in self.licenses {
            isValid = isValid && license.verify(log: &licensesLog)
        }
        log.append(contentsOf: licensesLog)

        return (log.pruning(by: .error).count == 0) && isValid
    }

}
