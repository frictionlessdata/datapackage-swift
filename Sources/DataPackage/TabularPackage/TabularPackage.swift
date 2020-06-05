import TableSchema

/**
    TabularPackage represents a Tabular Data Package that contains metadata about the contents of the package and its data resources. This specialized package aids in working with data described in a tabular structured format by way of a resource's schema.

    - SeeAlso: [Tabular Data Package](https://specs.frictionlessdata.io/tabular-data-package/)
*/
public class TabularPackage: Package {

    // MARK: - Setup & Teardown

    override public init() {
        super.init()
        self.profile = TabularPackage.profileName
    }

    // MARK: - Profile

    override public class var profileName: String { return "tabular-data-package" }

    required public init?(descriptor: [String: Any], log: inout Log) {
        super.init(descriptor: descriptor, log: &log)

        guard self.profile == TabularPackage.profileName else {
            log.append(keyPath: [Key.profile.rawValue], level: .error, entry: .badInput(self.profile))
            return nil
        }

        var schemaForeignKeys = [(Schema, [[String: Any]])]()

        if let resourceDescriptors = descriptor[Key.resources.rawValue] as? [[String: Any]] {
            let registry = Registry()
            registry.add(profile: TabularResource.self)

            var resourcesLog = Log(baseKeyPath: [Key.resources.rawValue])
            defer {
                log.append(contentsOf: resourcesLog)
            }

            for descriptor in resourceDescriptors {
                // Remove Foreign Keys descriptor to defer for later
                var foreignKeysDescriptors: [[String: Any]]?
                var newDescriptor = descriptor
                if var schemaDescriptor = descriptor[Resource.Key.schema.rawValue] as? [String: Any] {
                    foreignKeysDescriptors = schemaDescriptor[Schema.Key.foreignKeys.rawValue] as? [[String: Any]]
                    schemaDescriptor[Schema.Key.foreignKeys.rawValue] = nil
                    newDescriptor[Resource.Key.schema.rawValue] = schemaDescriptor
                }

                guard let profile = registry.profile(descriptor: newDescriptor, log: &resourcesLog), let resource = profile as? TabularResource else {
                    return nil
                }

                self.resources.append(resource)
                if let schema = resource.schema, let descriptors = foreignKeysDescriptors {
                    schemaForeignKeys.append((schema, descriptors))
                }
            }
        }

        if !self.loadForeignKeys(descriptors: schemaForeignKeys, log: &log) {
            return nil
        }
    }

    // MARK: - Private

    private func loadForeignKeys(descriptors: [(Schema, [[String: Any]])], log: inout Log) -> Bool {
        let resourcesByName = self.resourcesByName

        var baseKeyPath = Array(log.currentKeyPath)
        baseKeyPath.append(contentsOf: [Key.resources.rawValue, Resource.Key.schema.rawValue])
        var schemaLog = Log(baseKeyPath: baseKeyPath)
        defer {
            log.append(contentsOf: schemaLog)
        }

        baseKeyPath = Array(schemaLog.currentKeyPath)
        baseKeyPath.append(Schema.Key.foreignKeys.rawValue)
        var foreignKeysLog = Log(baseKeyPath: baseKeyPath)
        defer {
            log.append(contentsOf: foreignKeysLog)
        }

        // Build foreign key descriptors
        for (schema, foreignKeysDescriptors) in descriptors {
            for foreignKeysDescriptor in foreignKeysDescriptors {
                // Replace fields
                let fieldNames = foreignKeysDescriptor.castArray(String.self, forKey: ForeignKey.Key.fields.rawValue) ?? [String]()
                guard let fields = fieldNames.fields(by: schema.fields, keyPath: [Schema.Key.foreignKeys.rawValue, ForeignKey.Key.fields.rawValue], referencingKeyPath: [Schema.Key.fields.rawValue], log: &schemaLog) else {
                    return false
                }

                // Replace referencing fields
                guard var referenceDescriptor = foreignKeysDescriptor[ForeignKey.Key.reference.rawValue] as? [String: Any] else {
                    return false
                }
                guard let referenceFields = self.loadForeignKeyReferences(descriptor: referenceDescriptor, schema: schema, resources: resourcesByName, log: &schemaLog) else {
                    return false
                }
                referenceDescriptor[ForeignKey.Key.fields.rawValue] = referenceFields

                var newDescriptor = foreignKeysDescriptor
                newDescriptor[ForeignKey.Key.fields.rawValue] = fields
                newDescriptor[ForeignKey.Key.reference.rawValue] = referenceDescriptor

                if let foreignKey = ForeignKey(descriptor: newDescriptor, log: &foreignKeysLog) {
                    schema.foreignKeys.append(foreignKey)
                }
            }
        }

        return true
    }

    private func loadForeignKeyReferences(descriptor referenceDescriptor: [String: Any], schema: Schema, resources: [String: Resource], log: inout Log) -> [Field]? {
        guard let name = referenceDescriptor[ForeignKey.Key.resource.rawValue] as? String else {
            return nil
        }
        var referencingSchema: Schema
        if name == ForeignKey.Reference.selfReferencing {
            referencingSchema = schema
        } else {
            guard let reference = resources[name] else {
                let keyPath = [Schema.Key.foreignKeys.rawValue, ForeignKey.Key.reference.rawValue, ForeignKey.Key.resource.rawValue]
                log.append(keyPath: keyPath, level: .error, entry: .badInput(name))

                return nil
            }

            guard let referencingResource = reference as? TabularResource else {
                let keyPath = [Schema.Key.foreignKeys.rawValue, ForeignKey.Key.reference.rawValue, ForeignKey.Key.resource.rawValue]
                log.append(keyPath: keyPath, level: .error, entry: .badInput(name))

                return nil
            }

            guard let resourceSchema = referencingResource.schema else {
                return [Field]()
            }

            referencingSchema = resourceSchema
        }

        let fieldNames = referenceDescriptor.castArray(String.self, forKey: ForeignKey.Key.fields.rawValue) ?? [String]()

        let keyPath = [Schema.Key.foreignKeys.rawValue, ForeignKey.Key.reference.rawValue, ForeignKey.Key.fields.rawValue]
        let referencingKeyPath = [Schema.Key.fields.rawValue]

        guard let fields = fieldNames.fields(by: referencingSchema.fields, keyPath: keyPath, referencingKeyPath: referencingKeyPath, log: &log) else {
            return nil
        }

        return fields
    }

    // MARK: - Verifiable

    @discardableResult
    override public func verify(log: inout Log) -> Bool {
        var isValid = super.verify(log: &log)

        if self.profile != TabularPackage.profileName {
            isValid = false
            log.append(keyPath: [Key.profile.rawValue], level: .error, entry: .badInput(self.profile))
        }

        for resource in self.resources where resource.profile != TabularResource.profileName {
            isValid = false
            let keyPath = [Key.resources.rawValue, Resource.Key.profile.rawValue]
            log.append(keyPath: keyPath, level: .error, entry: .badInput(resource.profile))
        }

        isValid = isValid && self.verifyForeignKeyReferences(log: &log)

        return (log.pruning(by: .error).count == 0) && isValid
    }

    internal func verifyForeignKeyReferences(log: inout Log) -> Bool {
        var valid = true

        var baseKeyPath = Array(log.currentKeyPath)
        baseKeyPath.append(contentsOf: [Key.resources.rawValue, Resource.Key.schema.rawValue])
        var schemaLog = Log(baseKeyPath: baseKeyPath)

        // Foreign Keys between Resources
        for (_, resource) in resourcesByName {
            guard let tabularResource = resource as? TabularResource else {
                continue
            }

            guard let schema = tabularResource.schema else {
                continue
            }

            for foreignKey in schema.foreignKeys {
                var name = foreignKey.reference.resource
                if name == ForeignKey.Reference.selfReferencing {
                    name = resource.name
                }

                guard let reference = resourcesByName[name] else {
                    let keyPath = [Schema.Key.foreignKeys.rawValue, ForeignKey.Key.reference.rawValue, ForeignKey.Key.resource.rawValue]
                    schemaLog.append(keyPath: keyPath, level: .error, entry: .badInput(name))

                    valid = false
                    continue
                }

                guard let referencingResource = reference as? TabularResource else {
                    let keyPath = [Schema.Key.foreignKeys.rawValue, ForeignKey.Key.reference.rawValue, ForeignKey.Key.resource.rawValue]
                    schemaLog.append(keyPath: keyPath, level: .error, entry: .badInput(name))

                    valid = false
                    continue
                }

                guard let referencingSchema = referencingResource.schema else {
                    continue
                }

                let keyPath = [Schema.Key.fields.rawValue]
                let referencingKeyPath = [Schema.Key.foreignKeys.rawValue, ForeignKey.Key.reference.rawValue, ForeignKey.Key.fields.rawValue]

                let (isValid, _) = referencingSchema.fields.verify(by: foreignKey.reference.fields, keyPath: keyPath, referencingKeyPath: referencingKeyPath, log: &schemaLog)
                valid = valid && isValid
            }
        }
        log.append(contentsOf: schemaLog)

        return valid
    }

}
