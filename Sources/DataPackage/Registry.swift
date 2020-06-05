public class Registry {

    enum Key: String {
    case profile
    }

    var profiles = [String: Profile.Type]()
    static var defaultProfile: String = "default"

    /**
        A registry enables extension of a package or resource by registering available profile names to their corresponding classes for instantiation.

        This is akin to an abstract factory.

        - Parameter default: A default profile for use if one is not included in a descriptor.
    */
    public init(`default`: Profile.Type? = nil) {
        if let profileType = `default` {
            self.profiles[Registry.defaultProfile] = profileType
        }
    }

    /**
        Register a profile.
    */
    public func add(profile: Profile.Type) {
        self.profiles[profile.profileName] = profile
    }

    /**
        Instantiates a profile from a JSON-originating dictionary descriptor.
    */
    public func profile(descriptor: [String: Any], log: inout Log) -> Profile? {
        let rawProfileName = descriptor[Key.profile.rawValue]
        let profileName = (rawProfileName as? String) ?? Registry.defaultProfile

        guard let profileType = self.profiles[profileName] else {
            return nil
        }
        return profileType.init(descriptor: descriptor, log: &log)
    }

}
