/**
    Describes the dialect of a CSV-formatted resource.

    Defaults are assumed for any missing properties.

    - SeeAlso: [CSV Dialect](https://specs.frictionlessdata.io/csv-dialect/)
*/
public class CSVDialect: Serializable, Verifiable {

    public enum Key: String {
    case delimiter
    case lineTerminator
    case quoteCharacter = "quoteChar"
    case doubleQuote
    case escapeCharacter = "escapeChar"
    case nullSequence
    case skipInitialSpace
    case header
    case caseSensitiveHeader
    case commentCharacter = "commentChar"
    case csvddfVersion
    }

    public var delimiter: String = ","
    public var lineTerminator: String = "\r\n"
    public var quoteCharacter: String? = "\""
    public var doubleQuote: Bool = true
    public var escapeCharacter: String?
    public var nullSequence: String?
    public var skipInitialSpace: Bool = true
    public var header: Bool = true
    public var caseSensitiveHeader: Bool = false
    public var commentCharacter: String?
    public var csvddfVersion: String = "1.2"

    // MARK: - Setup & Teardown

    public init() {}

    public init(descriptor: [String: Any], log: inout Log) {
        if let delimiter = descriptor[Key.delimiter.rawValue] as? String {
            self.delimiter = delimiter
        }

        if let lineTerminator = descriptor[Key.lineTerminator.rawValue] as? String {
            self.lineTerminator = lineTerminator
        }

        if let quoteCharacter = descriptor[Key.quoteCharacter.rawValue] as? String {
            self.quoteCharacter = quoteCharacter
        }

        if let doubleQuote = descriptor[Key.doubleQuote.rawValue] as? Bool {
            self.doubleQuote = doubleQuote
        }

        if let escapeCharacter = descriptor[Key.escapeCharacter.rawValue] as? String {
            self.escapeCharacter = escapeCharacter
        }

        if let nullSequence = descriptor[Key.nullSequence.rawValue] as? String {
            self.nullSequence = nullSequence
        }

        if let skipInitialSpace = descriptor[Key.skipInitialSpace.rawValue] as? Bool {
            self.skipInitialSpace = skipInitialSpace
        }

        if let header = descriptor[Key.header.rawValue] as? Bool {
            self.header = header
        }

        if let caseSensitiveHeader = descriptor[Key.caseSensitiveHeader.rawValue] as? Bool {
            self.caseSensitiveHeader = caseSensitiveHeader
        }

        if let commentCharacter = descriptor[Key.commentCharacter.rawValue] as? String {
            self.commentCharacter = commentCharacter
        }

        if let csvddfVersion = descriptor[Key.csvddfVersion.rawValue] as? String {
            self.csvddfVersion = csvddfVersion
        }
    }

    // MARK: - Serializable

    func serialize() -> [String: Any] {
        var descriptor = [String: Any]()
        descriptor[Key.delimiter.rawValue] = self.delimiter
        descriptor[Key.lineTerminator.rawValue] = self.lineTerminator
        descriptor[Key.quoteCharacter.rawValue] = self.quoteCharacter
        descriptor[Key.doubleQuote.rawValue] = self.doubleQuote
        descriptor[Key.escapeCharacter.rawValue] = self.escapeCharacter
        descriptor[Key.nullSequence.rawValue] = self.nullSequence
        descriptor[Key.skipInitialSpace.rawValue] = self.skipInitialSpace
        descriptor[Key.header.rawValue] = self.header
        descriptor[Key.caseSensitiveHeader.rawValue] = self.caseSensitiveHeader
        descriptor[Key.commentCharacter.rawValue] = self.commentCharacter
        descriptor[Key.csvddfVersion.rawValue] = self.csvddfVersion
        return descriptor
    }

    // MARK: - Verifiable

    @discardableResult
    public func verify(log: inout Log) -> Bool {
        var isValid = true
        if !(self.lineTerminator == "\r\n" || self.lineTerminator == "\n") {
            isValid = false
            log.append(keyPath: [Key.lineTerminator.rawValue], level: .error, entry: .badInput(self.lineTerminator))
        }
        if !(self.quoteCharacter?.isEmpty ?? true), !(self.escapeCharacter?.isEmpty ?? true) {
            isValid = false
            log.append(keyPath: [Key.quoteCharacter.rawValue], level: .error, entry: .conflicting([Key.escapeCharacter.rawValue]))
        }
        self.verifyNonEmptyValues(log: &log)
        return isValid
    }

    internal func verifyNonEmptyValues(log: inout Log) {
        if self.delimiter.isEmpty {
            log.append(keyPath: [Key.lineTerminator.rawValue], level: .warning, entry: .badInput(self.delimiter))
        }
        if self.lineTerminator.isEmpty {
            log.append(keyPath: [Key.lineTerminator.rawValue], level: .warning, entry: .badInput(self.lineTerminator))
        }
        if self.quoteCharacter?.isEmpty ?? false {
            log.append(keyPath: [Key.quoteCharacter.rawValue], level: .warning, entry: .badInput(self.quoteCharacter))
        }
        if self.escapeCharacter?.isEmpty ?? false {
            log.append(keyPath: [Key.escapeCharacter.rawValue], level: .warning, entry: .badInput(self.escapeCharacter))
        }
        if self.nullSequence?.isEmpty ?? false {
            log.append(keyPath: [Key.nullSequence.rawValue], level: .warning, entry: .badInput(self.nullSequence))
        }
        if self.commentCharacter?.isEmpty ?? false {
            log.append(keyPath: [Key.commentCharacter.rawValue], level: .warning, entry: .badInput(self.commentCharacter))
        }
    }

}
