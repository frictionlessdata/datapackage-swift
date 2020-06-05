/// A log for reporting issues during model validity and verification checking.
public class Log {

    public enum Level: Int {
    /// Denotes a violation that impacts the meaning or functionality (corresponding to MUST, MUST NOT, REQUIRED, SHALL, or SHALL NOT)
    case error = 0
    /// Denotes a minor issue that may create ambiguity or lead to an issue (corresponding to SHOULD, SHOULD NOT, RECOMMENDED)
    case warning = 1
    }

    public enum Entry {
    /// Found an unexpected value for a key path.
    case badInput(Any?)
    /// Unable to interpret an enumeration value.
    case unknownEnumeration(String)
    /// Expected a key path that is missing.
    case missing
    /// A key path conflicts with another.
    case conflicting([String])
    }

    /// An issue occurring at some key path in the descriptor object hierarchy.
    public struct Item: CustomStringConvertible {

        // Key path leading up to this object.
        public let baseKeyPath: [String]
        // Key of the object, relative to the base key path.
        public let keyPath: [String]
        /// Severity level.
        public let level: Level
        /// Reported issue.
        public let entry: Entry

        public init(baseKeyPath: [String], keyPath: [String], level: Level, entry: Entry) {
            self.baseKeyPath = baseKeyPath
            self.keyPath = keyPath
            self.level = level
            self.entry = entry
        }

        // MARK: - CustomStringConvertible

        public var description: String {
            var source = Array(self.baseKeyPath)
            source.append(contentsOf: self.keyPath)
            let sourcePath = source.joined(separator: ".")

            let message: String
            switch self.entry {
            case .badInput(let value):
                let valueText = (value != nil) ? "'\(value!)'" : ""
                message = "Bad value \(valueText) at '\(sourcePath)'."
            case .unknownEnumeration(let value):
                message = "Unknown enumeration '\(value)' at '\(sourcePath)'."
            case .missing:
                message = "Missing value at '\(sourcePath)'."
            case .conflicting(let conflicting):
                var conflictingKeyPath = Array(self.baseKeyPath)
                conflictingKeyPath.append(contentsOf: conflicting)
                let conflictingPath = conflictingKeyPath.joined(separator: ".")
                message = "Conflict between '\(sourcePath)' and '\(conflictingPath)'."
            }

            return message
        }
    }

    public var items = [Item]()
    /// Base key path for this log. Items are relative to this path
    public var currentKeyPath = [String]()

    public init(baseKeyPath: [String] = [String]()) {
        self.currentKeyPath = baseKeyPath
    }

    /// Convenience for adding an item to the log.
    public func append(keyPath: [String], level: Level, entry: Entry) {
        self.append(Item(baseKeyPath: self.currentKeyPath, keyPath: keyPath, level: level, entry: entry))
    }

    /// Adds an item to the log.
    public func append(_ item: Item) {
        items.append(item)
    }

    /// Add another log's items to the end of this log.
    public func append(contentsOf log: Log) {
        items.append(contentsOf: log.items)
    }

    /**
        Find items that meet or exceed a severity level.

        - Parameter level: Include this severity level and above.
    */
    public func pruning(by level: Level = .error) -> [Item] {
        return self.items.filter { $0.level.rawValue <= level.rawValue }
    }

}
