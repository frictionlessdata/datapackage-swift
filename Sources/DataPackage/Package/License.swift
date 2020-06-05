import Foundation

public class License: Serializable, Verifiable {

    public enum Key: String {
    case name
    case path
    case title
    }

    // MARK: - Properties

    public var name: String?
    public var path: URL?
    public var title: String?

    // MARK: - Setup & Teardown

    public init?(descriptor: [String: Any], log: inout Log) {
        if let name = descriptor[Key.name.rawValue] as? String {
            self.name = name
        }

        if let path = descriptor[Key.path.rawValue] as? String {
            if let url = URL(string: path) {
                self.path = url
            } else {
                log.append(keyPath: [Key.name.rawValue], level: .warning, entry: .badInput(path))
            }
        }

        if let title = descriptor[Key.title.rawValue] as? String {
            self.title = title
        }
    }

    // MARK: - Serializable

    func serialize() -> [String: Any] {
        var descriptor = [String: Any]()
        descriptor[Key.name.rawValue] = self.name
        descriptor[Key.path.rawValue] = self.path?.absoluteString
        descriptor[Key.title.rawValue] = self.title
        return descriptor
    }

    // MARK: - Verifiable

    @discardableResult
    public func verify(log: inout Log) -> Bool {
        if (self.name ?? "").isEmpty && (self.path == nil) {
            log.append(keyPath: [Key.name.rawValue], level: .error, entry: .missing)
            log.append(keyPath: [Key.path.rawValue], level: .error, entry: .missing)
        }

        return (log.pruning(by: .error).count == 0)
    }

}
