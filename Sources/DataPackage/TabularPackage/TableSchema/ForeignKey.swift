import TableSchema

extension ForeignKey.Reference {

    public convenience init(_ resource: Resource) {
        self.init(resource: resource.name)
    }

}

extension ForeignKey: Serializable, Verifiable {

    public enum Key: String {
    case fields
    case reference
    case resource
    }

    // MARK: - Setup & Teardown

    public convenience init?(descriptor: [String: Any], log: inout Log) {
        guard let fields = ForeignKey.loadFields(descriptor: descriptor, log: &log) else {
            return nil
        }

        guard let reference = ForeignKey.loadReference(descriptor: descriptor, log: &log) else {
            return nil
        }

        self.init(fields: fields, reference: reference)
    }

    private class func loadFields(descriptor: [String: Any], log: inout Log) -> [Field]? {
        let fields: [Field]

        if let allFields = descriptor.castArray(Field.self, forKey: Key.fields.rawValue) {
            fields = allFields
        } else if let allNames = descriptor.castArray(String.self, forKey: Key.fields.rawValue) {
            log.append(keyPath: [Key.fields.rawValue], level: .warning, entry: .badInput(descriptor[Key.fields.rawValue]))
            fields = allNames.map { Field($0) }
        } else {
            log.append(keyPath: [Key.fields.rawValue], level: .error, entry: .badInput(descriptor[Key.fields.rawValue]))
            return nil
        }

        return fields
    }

    private class func loadReference(descriptor: [String: Any], log: inout Log) -> Reference? {
        guard let referenceDescriptor = descriptor[Key.reference.rawValue] as? [String: Any] else {
            log.append(keyPath: [Key.reference.rawValue], level: .error, entry: .missing)
            return nil
        }

        guard let resource = referenceDescriptor[Key.resource.rawValue] as? String else {
            let keyPath = [Key.reference.rawValue, Key.resource.rawValue]
            log.append(keyPath: keyPath, level: .error, entry: .missing)
            return nil
        }

        let referenceFields: [Field]

        if let allFields = referenceDescriptor.castArray(Field.self, forKey: Key.fields.rawValue) {
            referenceFields = allFields
        } else if let allNames = referenceDescriptor.castArray(String.self, forKey: Key.fields.rawValue) {
            let keyPath = [Key.reference.rawValue, Key.fields.rawValue]
            log.append(keyPath: keyPath, level: .warning, entry: .badInput(referenceDescriptor[Key.fields.rawValue]))
            referenceFields = allNames.map { Field($0) }
        } else {
            let keyPath = [Key.reference.rawValue, Key.fields.rawValue]
            log.append(keyPath: keyPath, level: .error, entry: .badInput(referenceDescriptor[Key.fields.rawValue]))
            return nil
        }

        let reference = Reference(resource: resource)
        reference.fields = referenceFields

        return reference
    }

    // MARK: - Serializable

    func serialize() -> [String: Any] {
        var descriptor = [String: Any]()
        descriptor[Key.fields.rawValue] = self.fields.map { (field) in field.name }

        var reference = [String: Any]()
        reference[Key.fields.rawValue] = self.reference.fields.map { $0.name }
        reference[Key.resource.rawValue] = self.reference.resource
        descriptor[Key.reference.rawValue] = reference

        return descriptor
    }

    // MARK: - Verifiable

    @discardableResult
    public func verify(log: inout Log) -> Bool {
        if self.fields.count == 0 {
            log.append(keyPath: [Key.fields.rawValue], level: .error, entry: .badInput(self.fields))
        }

        if self.fields.count != self.reference.fields.count {
            let keyPath = [Key.reference.rawValue, Key.fields.rawValue]
            log.append(keyPath: keyPath, level: .error, entry: .conflicting([Key.fields.rawValue]))
        }

        return (log.pruning(by: .error).count == 0)
    }

}
