import Foundation

public class Contributor: Serializable, Verifiable {

    public enum Key: String {
    case title
    case path
    case email
    case role
    case organization
    }

    public enum Role: String {
    case author
    case publisher
    case maintainer
    case wrangler
    case contributor
    }

    // MARK: - Properties

    public var title: String
    public var email: String?
    public var path: URL?
    public var role: Role? = .contributor
    public var organization: String?

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

        if let role = descriptor[Key.role.rawValue] as? String {
            if let roleValue = Role(rawValue: role) {
                self.role = roleValue
            } else {
                log.append(keyPath: [Key.role.rawValue], level: .error, entry: .unknownEnumeration(role))
            }
        }

        if let organization = descriptor[Key.organization.rawValue] as? String {
            self.organization = organization
        }
    }

    // MARK: - Serializable

    func serialize() -> [String: Any] {
        var descriptor = [String: Any]()
        descriptor[Key.title.rawValue] = self.title
        descriptor[Key.path.rawValue] = self.path?.absoluteString
        descriptor[Key.email.rawValue] = self.email
        descriptor[Key.role.rawValue] = self.role?.rawValue
        descriptor[Key.organization.rawValue] = self.organization
        return descriptor
    }

    // MARK: - Verifiable

    @discardableResult
    public func verify(log: inout Log) -> Bool {
        return true
    }

}
