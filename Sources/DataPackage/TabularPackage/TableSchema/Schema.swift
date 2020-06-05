import TableSchema

extension Schema: Serializable, Verifiable {

    public enum Key: String {
    case fields
    case missingValues
    case primaryKeys = "primaryKey"
    case foreignKeys
    }

    // MARK: - Setup & Teardown

    public convenience init?(descriptor: [String: Any], log: inout Log) {
        self.init()

        guard self.loadFields(descriptor: descriptor, log: &log) else {
            return nil
        }

        if let missingValues = descriptor[Key.missingValues.rawValue] as? [String] {
            self.missingValues = missingValues
        }

        guard self.loadPrimaryKeys(descriptor: descriptor, log: &log) else {
            return nil
        }

        guard self.loadForeignKeys(descriptor: descriptor, log: &log) else {
            return nil
        }
    }

    private func loadFields(descriptor: [String: Any], log: inout Log) -> Bool {
        if let fieldDescriptors = descriptor[Key.fields.rawValue] as? [[String: Any]] {
            var baseKeyPath = log.currentKeyPath
            baseKeyPath.append(Key.fields.rawValue)
            var fieldsLog = Log(baseKeyPath: baseKeyPath)
            defer {
                log.append(contentsOf: fieldsLog)
            }

            for fieldDescriptor in fieldDescriptors {
                guard let field = Field(descriptor: fieldDescriptor, log: &fieldsLog) else {
                    return false
                }

                self.fields.append(field)
            }
        }

        return true
    }

    private func loadPrimaryKeys(descriptor: [String: Any], log: inout Log) -> Bool {
        guard let primaryKeyNames = descriptor.castArray(String.self, forKey: Key.primaryKeys.rawValue) else {
            return true
        }

        guard let primaryKeys = primaryKeyNames.fields(by: self.fields, keyPath: [Key.primaryKeys.rawValue], referencingKeyPath: [Key.fields.rawValue], log: &log) else {
            return false
        }
        self.primaryKeys = primaryKeys

        return true
    }

    private func loadForeignKeys(descriptor: [String: Any], log: inout Log) -> Bool {
        guard let foreignKeysDescriptors = descriptor[Key.foreignKeys.rawValue] as? [[String: Any]] else {
            return true
        }

        var baseKeyPath = log.currentKeyPath
        baseKeyPath.append(Key.foreignKeys.rawValue)
        var foreignKeysLog = Log(baseKeyPath: baseKeyPath)
        defer {
            log.append(contentsOf: foreignKeysLog)
        }

        for foreignKeysDescriptor in foreignKeysDescriptors {
            let fieldNames = foreignKeysDescriptor.castArray(String.self, forKey: ForeignKey.Key.fields.rawValue) ?? [String]()

            guard let fields = fieldNames.fields(by: self.fields, keyPath: [Key.foreignKeys.rawValue, ForeignKey.Key.fields.rawValue], referencingKeyPath: [Key.fields.rawValue], log: &log) else {
                return false
            }

            var newDescriptor = foreignKeysDescriptor
            newDescriptor[ForeignKey.Key.fields.rawValue] = fields

            if let foreignKey = ForeignKey(descriptor: newDescriptor, log: &foreignKeysLog) {
                self.foreignKeys.append(foreignKey)
            }
        }

        return true
    }

    // MARK: - Serializable

    func serialize() -> [String: Any] {
        var descriptor = [String: Any]()

        if self.fields.count > 0 {
            descriptor[Key.fields.rawValue] = self.fields.map { $0.serialize() }
        }
        if self.missingValues.count > 0 {
            descriptor[Key.missingValues.rawValue] = self.missingValues
        }
        if self.primaryKeys.count > 0 {
            descriptor[Key.primaryKeys.rawValue] = self.primaryKeys.map { $0.name }
        }
        if self.foreignKeys.count > 0 {
            descriptor[Key.foreignKeys.rawValue] = self.foreignKeys.map { $0.serialize() }
        }

        return descriptor
    }

    // MARK: - Verifiable

    @discardableResult
    public func verify(log: inout Log) -> Bool {
        var isValid = true

        let (validFields, _) = self.verifyFields(log: &log)
        isValid = isValid && validFields

        let (validPrimaryKeys, _) = self.verifyPrimaryKeys(log: &log)
        isValid = isValid && validPrimaryKeys

        let (validForeignKeys, _) = self.verifyForeignKeys(log: &log)
        isValid = isValid && validForeignKeys

        return (log.pruning(by: .error).count == 0) && isValid
    }

    internal func verifyFields(log: inout Log) -> (valid: Bool, unique: Bool) {
        var isValid = true
        var isUnique = true

        var baseKeyPath = Array(log.currentKeyPath)
        baseKeyPath.append(Key.fields.rawValue)
        var fieldsLog = Log(baseKeyPath: baseKeyPath)
        var uniqueFields = Set<Field>()

        for field in self.fields {
            isValid = isValid && field.verify(log: &fieldsLog)

            let (inserted, _) = uniqueFields.insert(field)
            if !inserted {
                isUnique = false
                log.append(keyPath: [Key.fields.rawValue], level: .warning, entry: .conflicting([Key.fields.rawValue]))
            }
        }
        log.append(contentsOf: fieldsLog)

        return (isValid, isUnique)
    }

    internal func verifyPrimaryKeys(log: inout Log) -> (valid: Bool, unique: Bool) {
        return self.fields.verify(by: self.primaryKeys, keyPath: [Key.fields.rawValue], referencingKeyPath: [Key.primaryKeys.rawValue], log: &log)
    }

    internal func verifyForeignKeys(log: inout Log) -> (valid: Bool, unique: Bool) {
        var isValid = true
        var isUnique = true

        var baseKeyPath = Array(log.currentKeyPath)
        baseKeyPath.append(Key.foreignKeys.rawValue)
        var foreignKeyLog = Log(baseKeyPath: baseKeyPath)
        let fieldsKeyPath = [Key.foreignKeys.rawValue, ForeignKey.Key.fields.rawValue]

        for foreignKey in self.foreignKeys {
            isValid = isValid && foreignKey.verify(log: &foreignKeyLog)

            let (valid, unique) = self.fields.verify(by: foreignKey.fields, keyPath: [Key.fields.rawValue], referencingKeyPath: fieldsKeyPath, log: &log)
            isValid = isValid && valid
            isUnique = isUnique && unique
        }
        log.append(contentsOf: foreignKeyLog)

        return (isValid, isUnique)
    }

}
