import Foundation

public class Source: Serializable, Verifiable {

    public enum Key: String {
    case title
    case path
    case email
    }

    // MARK: - Properties

    public var title: String
    public var path: URL?
    public var email: String?

    // MARK: - Setup & Teardown

    public init(_ title: String) {
        self.title = title
    }

    convenience public init?(descriptor: [String: Any], log: inout Log) {
        guard let title = descriptor[Key.title.rawValue] as? String else {
            log.append(keyPath: [Key.title.rawValue], level: .error, entry: .missing)
            return nil
        }

        self.init(title)

        if let path = descriptor[Key.path.rawValue] as? String {
            if let url = URL(string: path) {
                self.path = url
            } else {
                log.append(keyPath: [Key.path.rawValue], level: .warning, entry: .badInput(path))
            }
        }

        if let email = descriptor[Key.email.rawValue] as? String {
            self.email = email
        }
    }

    // MARK: - Serializable

    func serialize() -> [String: Any] {
        var descriptor = [String: Any]()
        descriptor[Key.title.rawValue] = self.title
        descriptor[Key.path.rawValue] = self.path?.absoluteString
        descriptor[Key.email.rawValue] = self.email
        return descriptor
    }

    // MARK: - Verifiable

    @discardableResult
    public func verify(log: inout Log) -> Bool {
        return true
    }

}
