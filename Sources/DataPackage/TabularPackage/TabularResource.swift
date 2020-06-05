import TableSchema

/**
    TabularResource represents a Data Resource that contains metadata about a resource. This specialized package aids in working with data described in a tabular structured format by way of its schema.

    - SeeAlso: [Tabular Data Resource](https://specs.frictionlessdata.io/tabular-data-resource/)
*/
public final class TabularResource: Resource {

    // MARK: - Properties

    public var dialect: CSVDialect? = CSVDialect()
    public var schema: Schema?

    public enum AdditionalKey: String, CaseIterable {
    case dialect
    }

    override public var additionalKeys: Set<String> {
        return Set<String>(AdditionalKey.allCases.map { $0.rawValue })
    }

    // MARK: - Setup & Teardown

    override public init(_ name: String) {
        super.init(name)
        self.profile = TabularResource.profileName
    }

    // MARK: - Profile

    override public class var profileName: String { return "tabular-data-resource" }

    required public init?(descriptor: [String: Any], log: inout Log) {
        super.init(descriptor: descriptor, log: &log)

        if self.profile != TabularResource.profileName {
            log.append(keyPath: [Key.profile.rawValue], level: .error, entry: .badInput(self.profile))
            return nil
        }

        var keyPath = Array(log.currentKeyPath)
        keyPath.append(AdditionalKey.dialect.rawValue)
        var dialectLog = Log(baseKeyPath: keyPath)
        if let dialect = descriptor[AdditionalKey.dialect.rawValue] as? [String: Any] {
            self.dialect = CSVDialect(descriptor: dialect, log: &dialectLog)
        }
        log.append(contentsOf: dialectLog)

        keyPath = Array(log.currentKeyPath)
        keyPath.append(Key.schema.rawValue)
        var schemaLog = Log(baseKeyPath: keyPath)
        if let schema = descriptor[Key.schema.rawValue] as? [String: Any] {
            self.schema = Schema(descriptor: schema, log: &schemaLog)
        }
        log.append(contentsOf: schemaLog)
    }

    // MARK: - Serializable

    override func serialize() -> [String: Any] {
        var descriptor = super.serialize()
        descriptor[Key.schema.rawValue] = self.schema?.serialize()
		descriptor[AdditionalKey.dialect.rawValue] = self.dialect?.serialize()
        return descriptor
    }

    // MARK: - Verifiable

    @discardableResult
    override public func verify(log: inout Log) -> Bool {
        var isValid = super.verify(log: &log)

        if self.profile != TabularResource.profileName {
            isValid = false
            log.append(keyPath: [Key.profile.rawValue], level: .error, entry: .badInput(self.profile))
        }

        if let dialect = self.dialect {
            var keyPath = Array(log.currentKeyPath)
            keyPath.append(AdditionalKey.dialect.rawValue)
            var dialectLog = Log(baseKeyPath: keyPath)
            isValid = isValid && dialect.verify(log: &dialectLog)
            log.append(contentsOf: dialectLog)
        }

        if self.schema == nil {
            isValid = false
            log.append(keyPath: [Key.schema.rawValue], level: .error, entry: .missing)
        }

        var keyPath = Array(log.currentKeyPath)
        keyPath.append(Key.schema.rawValue)
        var schemaLog = Log(baseKeyPath: keyPath)
        isValid = isValid && self.schema?.verify(log: &schemaLog) ?? true
        log.append(contentsOf: schemaLog)

        let isExpectedFormat = (self.mediatype?.caseInsensitiveCompare("text/csv") == .orderedSame) || (self.format?.caseInsensitiveCompare("csv") == .orderedSame)
        if self.paths.count > 0 && !isExpectedFormat {
            isValid = false
            log.append(keyPath: [Key.paths.rawValue], level: .error, entry: .conflicting([Key.mediatype.rawValue]))
            log.append(keyPath: [Key.paths.rawValue], level: .error, entry: .conflicting([Key.format.rawValue]))
        }

        let isExpectedType = (self.rawData as? [[Any]] != nil) || (self.rawData as? [String: Any] != nil)
        if self.rawData != nil && !isExpectedType {
            isValid = false
            log.append(keyPath: [Key.data.rawValue], level: .error, entry: .badInput(nil))
        }

        return (log.pruning(by: .error).count == 0) && isValid
    }

}
